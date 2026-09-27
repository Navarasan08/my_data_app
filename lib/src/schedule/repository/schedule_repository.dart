import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:my_data_app/src/core/sync/firestore_list_store.dart';
import 'package:my_data_app/src/core/sync/sync_node.dart';
import 'package:my_data_app/src/schedule/model/schedule_model.dart';

abstract class ScheduleRepository implements SyncNode {
  List<ScheduleEntry> getAll();
  void add(ScheduleEntry entry);
  void update(ScheduleEntry entry);
  void delete(String id);

  List<ScheduleCategory> getCustomCategories();
  void addCustomCategory(ScheduleCategory category);
  void updateCustomCategory(ScheduleCategory category);
  void deleteCustomCategory(String categoryId);
}

/// Realtime Firestore implementation over two collections.
///
/// Entries are kept as raw docs because parsing them needs the current
/// custom categories; [getAll] parses on demand and memoises the result on
/// the identity of the two underlying lists, so a renamed category shows up
/// on every entry the moment the categories listener fires.
class FirestoreScheduleRepository extends CompositeSyncNode
    implements ScheduleRepository {
  final String uid;
  final FirestoreListStore<Map<String, dynamic>> _entriesRaw;
  final FirestoreListStore<ScheduleCategory> _categories;

  List<Map<String, dynamic>>? _parsedFromRaw;
  List<ScheduleCategory>? _parsedWithCategories;
  List<ScheduleEntry> _parsed = const [];

  factory FirestoreScheduleRepository({
    required String uid,
    FirebaseFirestore? firestore,
  }) {
    final user = (firestore ?? FirebaseFirestore.instance)
        .collection('users')
        .doc(uid);
    return FirestoreScheduleRepository._(
      uid,
      FirestoreListStore<Map<String, dynamic>>(
        collection: user.collection('schedules'),
        fromDoc: (json, _) => json,
        toJson: (m) => m,
        idOf: (m) => m['id'] as String,
        debugLabel: 'schedules',
      ),
      FirestoreListStore<ScheduleCategory>(
        collection: user.collection('schedule_categories'),
        fromDoc: (json, _) => ScheduleCategory.fromJson(json),
        toJson: (c) => c.toJson(),
        idOf: (c) => c.id,
        debugLabel: 'schedule_categories',
      ),
    );
  }

  FirestoreScheduleRepository._(this.uid, this._entriesRaw, this._categories)
    : super([_entriesRaw, _categories]);

  // ── Entries ──────────────────────────────────────────────────────────────

  @override
  List<ScheduleEntry> getAll() {
    final raw = _entriesRaw.items;
    final categories = _categories.items;
    if (identical(raw, _parsedFromRaw) &&
        identical(categories, _parsedWithCategories)) {
      return _parsed;
    }
    final entries = <ScheduleEntry>[];
    for (final json in raw) {
      try {
        entries.add(ScheduleEntry.fromJson(json, customCategories: categories));
      } catch (e) {
        if (kDebugMode) debugPrint('[schedules] skipped entry: $e');
      }
    }
    _parsedFromRaw = raw;
    _parsedWithCategories = categories;
    _parsed = List.unmodifiable(entries);
    return _parsed;
  }

  @override
  void add(ScheduleEntry entry) => _entriesRaw.save(entry.toJson());

  @override
  void update(ScheduleEntry entry) => _entriesRaw.save(entry.toJson());

  @override
  void delete(String id) => _entriesRaw.remove(id);

  // ── Custom categories ────────────────────────────────────────────────────

  @override
  List<ScheduleCategory> getCustomCategories() => _categories.items;

  @override
  void addCustomCategory(ScheduleCategory category) =>
      _categories.save(category);

  @override
  void updateCustomCategory(ScheduleCategory category) =>
      _categories.save(category);

  @override
  void deleteCustomCategory(String categoryId) =>
      _categories.remove(categoryId);
}
