import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

enum ImportMode { replace, merge, addOnly }

/// A logical group of Firestore collections the user can tick on/off when
/// exporting. Each collection optionally declares the top-level ISO-date field
/// that the date-range filter should compare against (null = no filtering,
/// items always included when the module is selected).
class ExportModule {
  final String id;
  final String label;
  final IconData icon;

  /// Collection name -> date field for filtering (null = no date filter).
  final Map<String, String?> collections;

  /// `'<collection>/<docId>'` singleton setting docs tied to this module.
  /// Settings are never date-filtered.
  final List<String> settingDocs;

  const ExportModule({
    required this.id,
    required this.label,
    required this.icon,
    this.collections = const {},
    this.settingDocs = const [],
  });
}

/// Outcome from a size precheck. The caller decides whether to proceed.
enum ExportSize { ok, warn, block }

class ExportSizeResult {
  final ExportSize verdict;
  final int bytes;
  const ExportSizeResult(this.verdict, this.bytes);
}

class DataIoService {
  final FirebaseFirestore _firestore;

  DataIoService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Size guard: warn above this, block above the upper bound.
  static const int warnBytes = 20 * 1024 * 1024;
  static const int blockBytes = 100 * 1024 * 1024;

  /// Canonical module catalog. Order is the display order in the dialog.
  static const List<ExportModule> modules = [
    ExportModule(
      id: 'bills',
      label: 'Bills & Reminders',
      icon: Icons.receipt_long_outlined,
      collections: {'bills': 'createdDate'},
    ),
    ExportModule(
      id: 'vehicles',
      label: 'Vehicles',
      icon: Icons.directions_car_outlined,
      collections: {'vehicles': null},
    ),
    ExportModule(
      id: 'chits',
      label: 'Chit Funds',
      icon: Icons.account_balance_outlined,
      collections: {'chits': 'startDate'},
    ),
    ExportModule(
      id: 'checklists',
      label: 'Checklists',
      icon: Icons.checklist_outlined,
      collections: {'checklists': 'createdDate'},
    ),
    ExportModule(
      id: 'periods',
      label: 'Periods',
      icon: Icons.water_drop_outlined,
      collections: {'periods': 'startDate'},
    ),
    ExportModule(
      id: 'home',
      label: 'Home Records',
      icon: Icons.home_outlined,
      collections: {
        'home_records': 'date',
        'home_categories': null,
        'home_payment_types': null,
      },
      settingDocs: ['home_settings/prefs'],
    ),
    ExportModule(
      id: 'schedule',
      label: 'Schedule',
      icon: Icons.event_outlined,
      collections: {
        'schedules': 'startDate',
        'schedule_categories': null,
      },
    ),
    ExportModule(
      id: 'food_menu',
      label: 'Food Menu',
      icon: Icons.restaurant_outlined,
      collections: {'food_menu': null},
    ),
    ExportModule(
      id: 'loans',
      label: 'Loans',
      icon: Icons.account_balance_wallet_outlined,
      collections: {'loans': 'startDate'},
    ),
    ExportModule(
      id: 'goals',
      label: 'Goals',
      icon: Icons.flag_outlined,
      collections: {'goals': 'startDate'},
    ),
    ExportModule(
      id: 'money_owe',
      label: 'Money Owed',
      icon: Icons.savings_outlined,
      collections: {'money_owe': 'date'},
    ),
    ExportModule(
      id: 'medical',
      label: 'Medical',
      icon: Icons.medical_services_outlined,
      collections: {
        'family_members': null,
        'medical_records': 'date',
      },
    ),
    ExportModule(
      id: 'vault',
      label: 'Profile Vault',
      icon: Icons.lock_outline_rounded,
      collections: {'vault_entries': null},
    ),
    ExportModule(
      id: 'land',
      label: 'Land',
      icon: Icons.terrain_outlined,
      collections: {'lands': null},
    ),
    ExportModule(
      id: 'events',
      label: 'Events',
      icon: Icons.event_note_outlined,
      // Events have nested `expenses` subcollection — handled automatically.
      collections: {'events': 'eventDate'},
    ),
    ExportModule(
      id: 'interest',
      label: 'Interest',
      icon: Icons.percent_outlined,
      collections: {'interest_records': 'startDate'},
    ),
    ExportModule(
      id: 'activities',
      label: 'Activities',
      icon: Icons.directions_run_outlined,
      collections: {'activities': 'startDate'},
    ),
    ExportModule(
      id: 'diet',
      label: 'Diet',
      icon: Icons.local_dining_outlined,
      collections: {
        'diet_items': null,
        'diet_entries': 'date',
      },
    ),
    ExportModule(
      id: 'days_counter',
      label: 'Days Counter',
      icon: Icons.calendar_month_outlined,
      collections: {
        'days_counter_events': 'date',
        'days_counter_event_types': null,
      },
      settingDocs: ['days_counter_settings/prefs'],
    ),
    ExportModule(
      id: 'notifications',
      label: 'Notifications',
      icon: Icons.notifications_outlined,
      collections: {'notifications': 'createdAt'},
    ),
    ExportModule(
      id: 'app_settings',
      label: 'App Settings',
      icon: Icons.tune_outlined,
      settingDocs: ['settings/dashboard'],
    ),
  ];

  // Import path still needs to know every collection that *could* exist in a
  // payload, regardless of whether the user has that module selected today.
  static final List<String> _allCollections = [
    for (final m in modules) ...m.collections.keys,
  ];

  static const _nestedSubcollections = <String, List<String>>{
    'events': ['expenses'],
  };

  static final List<String> _allSettingDocs = [
    for (final m in modules) ...m.settingDocs,
  ];

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _firestore.collection('users').doc(uid);

  // ── Export ────────────────────────────────────────────────────────────

  /// Reads the user tree from Firestore, optionally restricted to a subset of
  /// modules and a date range. [from] and [to] are inclusive day boundaries —
  /// pass `null` to skip date filtering. A doc whose date field is null/empty
  /// is *included* (no-date items are not silently dropped).
  Future<Map<String, dynamic>> exportAll(
    String uid, {
    Set<String>? moduleIds,
    DateTime? from,
    DateTime? to,
  }) async {
    final userDoc = _userDoc(uid);

    // Normalize range to whole-day boundaries.
    final fromTs = from == null
        ? null
        : DateTime(from.year, from.month, from.day);
    final toTs = to == null
        ? null
        : DateTime(to.year, to.month, to.day, 23, 59, 59, 999);

    final selected =
        moduleIds == null ? modules : modules.where((m) => moduleIds.contains(m.id));

    final collections = <String, List<Map<String, dynamic>>>{};
    final settings = <String, Map<String, dynamic>?>{};

    for (final module in selected) {
      for (final entry in module.collections.entries) {
        final col = entry.key;
        final dateField = entry.value;
        final snap = await userDoc.collection(col).get();
        final docs = <Map<String, dynamic>>[];
        final nested = _nestedSubcollections[col];

        for (final d in snap.docs) {
          final data = d.data();
          if (!_passesDateFilter(data, dateField, fromTs, toTs)) continue;

          final item = <String, dynamic>{
            '__id': d.id,
            'data': data,
          };
          if (nested != null) {
            final subMap = <String, List<Map<String, dynamic>>>{};
            for (final sub in nested) {
              final subSnap = await userDoc
                  .collection(col)
                  .doc(d.id)
                  .collection(sub)
                  .get();
              subMap[sub] = subSnap.docs
                  .map((s) => {'__id': s.id, 'data': s.data()})
                  .toList();
            }
            item['__sub'] = subMap;
          }
          docs.add(item);
        }
        collections[col] = docs;
      }

      for (final ref in module.settingDocs) {
        final parts = ref.split('/');
        if (parts.length != 2) continue;
        final snap = await userDoc.collection(parts[0]).doc(parts[1]).get();
        settings[ref] = snap.data();
      }
    }

    return <String, dynamic>{
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'dateRange': {
        'from': from?.toIso8601String(),
        'to': to?.toIso8601String(),
      },
      'modules': selected.map((m) => m.id).toList(),
      'collections': collections,
      'settings': settings,
    };
  }

  /// Serializes [payload] and runs the size guard. Returns the encoded JSON
  /// and a verdict. Caller decides what to do on `warn`/`block`.
  ExportSizeResult evaluatePayloadSize(String json) {
    final bytes = utf8.encode(json).length;
    if (bytes >= blockBytes) return ExportSizeResult(ExportSize.block, bytes);
    if (bytes >= warnBytes) return ExportSizeResult(ExportSize.warn, bytes);
    return ExportSizeResult(ExportSize.ok, bytes);
  }

  /// Writes [json] to a temp file and opens the system share sheet.
  Future<File> shareJson(String json) async {
    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;
    final file = File('${dir.path}/my_data_app_export_$stamp.json');
    await file.writeAsString(json);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'my_data_app data export',
      ),
    );
    return file;
  }

  String encodePayload(Map<String, dynamic> payload) =>
      const JsonEncoder.withIndent('  ').convert(payload);

  bool _passesDateFilter(
    Map<String, dynamic> data,
    String? dateField,
    DateTime? from,
    DateTime? to,
  ) {
    if (dateField == null) return true;
    if (from == null && to == null) return true;
    final raw = data[dateField];
    if (raw is! String || raw.isEmpty) return true; // no-date items kept
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return true;
    if (from != null && parsed.isBefore(from)) return false;
    if (to != null && parsed.isAfter(to)) return false;
    return true;
  }

  // ── Import ────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> pickAndParseImport() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;

    final fileBytes = result.files.single.bytes;
    final filePath = result.files.single.path;
    final content = fileBytes != null
        ? utf8.decode(fileBytes)
        : await File(filePath!).readAsString();

    final decoded = jsonDecode(content);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Export file root is not a JSON object.');
    }
    if (decoded['collections'] is! Map || decoded['settings'] is! Map) {
      throw const FormatException(
          'Export file is missing "collections" or "settings".');
    }
    return decoded;
  }

  Future<void> importAll(
    String uid,
    Map<String, dynamic> data,
    ImportMode mode,
  ) async {
    final userDoc = _userDoc(uid);

    if (mode == ImportMode.replace) {
      await _wipeAll(userDoc);
    }

    final collections =
        (data['collections'] as Map?)?.cast<String, dynamic>() ?? const {};
    final settings =
        (data['settings'] as Map?)?.cast<String, dynamic>() ?? const {};

    final writer = _BatchedWriter(_firestore);

    for (final col in _allCollections) {
      final items = (collections[col] as List?) ?? const [];

      Set<String>? existingIds;
      if (mode == ImportMode.addOnly) {
        final snap = await userDoc.collection(col).get();
        existingIds = snap.docs.map((d) => d.id).toSet();
      }

      final nested = _nestedSubcollections[col];

      for (final raw in items) {
        if (raw is! Map) continue;
        final id = raw['__id'] as String?;
        final docData = (raw['data'] as Map?)?.cast<String, dynamic>();
        if (id == null || docData == null) continue;
        if (existingIds != null && existingIds.contains(id)) continue;

        final docRef = userDoc.collection(col).doc(id);
        writer.set(docRef, docData);

        if (nested != null) {
          final subRaw = (raw['__sub'] as Map?)?.cast<String, dynamic>();
          if (subRaw != null) {
            for (final sub in nested) {
              final subItems = (subRaw[sub] as List?) ?? const [];
              for (final subRow in subItems) {
                if (subRow is! Map) continue;
                final subId = subRow['__id'] as String?;
                final subData =
                    (subRow['data'] as Map?)?.cast<String, dynamic>();
                if (subId == null || subData == null) continue;
                writer.set(docRef.collection(sub).doc(subId), subData);
              }
            }
          }
        }
        await writer.commitIfFull();
      }
    }

    for (final ref in _allSettingDocs) {
      final parts = ref.split('/');
      if (parts.length != 2) continue;
      final raw = settings[ref];
      if (raw is! Map<String, dynamic>) continue;
      final docRef = userDoc.collection(parts[0]).doc(parts[1]);
      if (mode == ImportMode.addOnly) {
        final existing = await docRef.get();
        if (existing.exists) continue;
      }
      writer.set(docRef, raw, merge: mode == ImportMode.merge);
      await writer.commitIfFull();
    }

    await writer.flush();
  }

  Future<void> _wipeAll(
      DocumentReference<Map<String, dynamic>> userDoc) async {
    final writer = _BatchedWriter(_firestore);

    for (final col in _allCollections) {
      final snap = await userDoc.collection(col).get();
      final nested = _nestedSubcollections[col];
      for (final d in snap.docs) {
        if (nested != null) {
          for (final sub in nested) {
            final subSnap =
                await userDoc.collection(col).doc(d.id).collection(sub).get();
            for (final s in subSnap.docs) {
              writer.delete(s.reference);
              await writer.commitIfFull();
            }
          }
        }
        writer.delete(d.reference);
        await writer.commitIfFull();
      }
    }

    for (final ref in _allSettingDocs) {
      final parts = ref.split('/');
      if (parts.length != 2) continue;
      writer.delete(userDoc.collection(parts[0]).doc(parts[1]));
      await writer.commitIfFull();
    }

    await writer.flush();
  }
}

class _BatchedWriter {
  final FirebaseFirestore _firestore;
  WriteBatch _batch;
  int _count = 0;
  static const _limit = 400;

  _BatchedWriter(this._firestore) : _batch = _firestore.batch();

  void set(
    DocumentReference<Map<String, dynamic>> ref,
    Map<String, dynamic> data, {
    bool merge = false,
  }) {
    if (merge) {
      _batch.set(ref, data, SetOptions(merge: true));
    } else {
      _batch.set(ref, data);
    }
    _count++;
  }

  void delete(DocumentReference<Map<String, dynamic>> ref) {
    _batch.delete(ref);
    _count++;
  }

  Future<void> commitIfFull() async {
    if (_count >= _limit) {
      await _batch.commit();
      _batch = _firestore.batch();
      _count = 0;
    }
  }

  Future<void> flush() async {
    if (_count > 0) {
      await _batch.commit();
      _batch = _firestore.batch();
      _count = 0;
    }
  }
}
