import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:my_data_app/src/core/sync/firestore_collection_source.dart';
import 'package:my_data_app/src/core/sync/firestore_document_source.dart';
import 'package:my_data_app/src/core/sync/sync_node.dart';
import 'package:my_data_app/src/core/sync/sync_snapshot.dart';
import 'package:my_data_app/src/home/home_record_model.dart';

/// User preferences for the expense tracker, stored in one settings doc.
class HomeSettings {
  final String currencyCode;
  final bool showMonthlyCalendar;
  final int monthlyStartDay;
  final String weekendAdjustment;
  final bool isCalendarView;
  final bool paymentTypesSeeded;

  const HomeSettings({
    this.currencyCode = 'INR',
    this.showMonthlyCalendar = true,
    this.monthlyStartDay = 1,
    this.weekendAdjustment = 'exact',
    this.isCalendarView = false,
    this.paymentTypesSeeded = false,
  });

  static const defaults = HomeSettings();

  factory HomeSettings.fromJson(Map<String, dynamic>? json) {
    if (json == null) return defaults;
    return HomeSettings(
      currencyCode: (json['currencyCode'] as String?) ?? 'INR',
      showMonthlyCalendar: (json['showMonthlyCalendar'] as bool?) ?? true,
      monthlyStartDay: (json['monthlyStartDay'] as int?) ?? 1,
      weekendAdjustment: (json['weekendAdjustment'] as String?) ?? 'exact',
      isCalendarView: (json['isCalendarView'] as bool?) ?? false,
      paymentTypesSeeded: (json['paymentTypesSeeded'] as bool?) ?? false,
    );
  }
}

/// Everything the expense tracker needs, delivered as one consistent unit
/// with the sync status of the slowest underlying source.
class HomeRecordData {
  final List<HomeRecord> records;
  final List<HomeCategory> customCategories;
  final List<PaymentType> paymentTypes;
  final HomeSettings settings;
  final SyncStatus status;
  final bool hasPendingWrites;

  const HomeRecordData({
    this.records = const [],
    this.customCategories = const [],
    this.paymentTypes = const [],
    this.settings = HomeSettings.defaults,
    this.status = SyncStatus.loading,
    this.hasPendingWrites = false,
  });

  static const empty = HomeRecordData();
}

abstract class HomeRecordRepository implements SyncNode {
  /// Latest combined data. `loading` until every source has reported once.
  HomeRecordData get current;

  /// Emits whenever any underlying source changes. Does not replay
  /// [current] on subscription.
  Stream<HomeRecordData> get stream;

  void add(HomeRecord record);
  void update(HomeRecord record);
  void delete(String recordId);

  void addCustomCategory(HomeCategory category);
  void updateCustomCategory(HomeCategory category);
  void deleteCustomCategory(String categoryId);

  void addPaymentType(PaymentType type);
  void updatePaymentType(PaymentType type);
  void deletePaymentType(String typeId);

  void setCurrencyCode(String code);
  void setShowMonthlyCalendar(bool value);
  void setMonthlyStartDay(int day);
  void setWeekendAdjustment(String value);
  void setIsCalendarView(bool value);
}

/// Listener-based Firestore implementation.
///
/// Four realtime sources (settings doc, categories, payment types, records)
/// are combined into a single [HomeRecordData]. Records are re-parsed
/// whenever categories change, so a renamed category shows up on every
/// record without any extra bookkeeping. Writes go straight to Firestore and
/// come back through the listener via latency compensation, so there is a
/// single source of truth and no in-memory list to keep in step.
class FirestoreHomeRecordRepository implements HomeRecordRepository {
  final String uid;
  final FirebaseFirestore _firestore;

  late final FirestoreDocumentSource<HomeSettings> _settings;
  late final FirestoreCollectionSource<HomeCategory> _categories;
  late final FirestoreCollectionSource<PaymentType> _paymentTypes;

  /// Raw record docs; parsed in [_recompute] because parsing needs the
  /// current custom categories.
  late final FirestoreCollectionSource<Map<String, dynamic>> _recordDocs;

  final _controller = StreamController<HomeRecordData>.broadcast();
  final _subs = <StreamSubscription<dynamic>>[];
  HomeRecordData _current = HomeRecordData.empty;
  bool _started = false;
  bool _seedAttempted = false;

  FirestoreHomeRecordRepository({
    required this.uid,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance {
    _settings = FirestoreDocumentSource<HomeSettings>(
      ref: _settingsDoc,
      fromDoc: HomeSettings.fromJson,
      initial: HomeSettings.defaults,
      debugLabel: 'home_settings',
    );
    _categories = FirestoreCollectionSource<HomeCategory>(
      query: _categoryCollection,
      fromDoc: (json, _) => HomeCategory.fromJson(json),
      debugLabel: 'home_categories',
    );
    _paymentTypes = FirestoreCollectionSource<PaymentType>(
      query: _paymentTypeCollection,
      fromDoc: (json, _) => PaymentType.fromJson(json),
      debugLabel: 'home_payment_types',
    );
    _recordDocs = FirestoreCollectionSource<Map<String, dynamic>>(
      query: _collection,
      fromDoc: (json, _) => json,
      debugLabel: 'home_records',
    );
  }

  DocumentReference<Map<String, dynamic>> get _userDoc =>
      _firestore.collection('users').doc(uid);

  CollectionReference<Map<String, dynamic>> get _collection =>
      _userDoc.collection('home_records');

  CollectionReference<Map<String, dynamic>> get _categoryCollection =>
      _userDoc.collection('home_categories');

  CollectionReference<Map<String, dynamic>> get _paymentTypeCollection =>
      _userDoc.collection('home_payment_types');

  DocumentReference<Map<String, dynamic>> get _settingsDoc =>
      _userDoc.collection('home_settings').doc('prefs');

  @override
  HomeRecordData get current => _current;

  @override
  Stream<HomeRecordData> get stream => _controller.stream;

  @override
  SyncStatus get syncStatus => _current.status;

  @override
  bool get hasPendingWrites => _current.hasPendingWrites;

  @override
  Stream<void> get changes => _controller.stream;

  @override
  void start() {
    if (_started) return;
    _started = true;
    _subs.addAll([
      _settings.stream.listen((_) => _recompute()),
      _categories.stream.listen((_) => _recompute()),
      _paymentTypes.stream.listen((_) => _recompute()),
      _recordDocs.stream.listen((_) => _recompute()),
    ]);
    _settings.start();
    _categories.start();
    _paymentTypes.start();
    _recordDocs.start();
  }

  void _recompute() {
    final settings = _settings.current;
    final categories = _categories.current;
    final paymentTypes = _paymentTypes.current;
    final recordDocs = _recordDocs.current;

    final status = combineSyncStatus([
      settings.status,
      categories.status,
      paymentTypes.status,
      recordDocs.status,
    ]);

    // Hold everything back until all four sources have reported once, so a
    // record never renders with a fallback category because its custom
    // category simply hasn't arrived yet.
    if (status.isLoading) {
      _emit(HomeRecordData.empty);
      return;
    }

    final records = <HomeRecord>[];
    for (final json in recordDocs.data) {
      try {
        records.add(
          HomeRecord.fromJson(json, customCategories: categories.data),
        );
      } catch (e) {
        if (kDebugMode) debugPrint('[home_records] skipped record: $e');
      }
    }

    _maybeSeedPaymentTypes(settings, paymentTypes);

    if (!kReleaseMode && status != _current.status) {
      debugPrint('[sync] home: $status with ${records.length} records');
    }
    _emit(
      HomeRecordData(
        records: List.unmodifiable(records),
        customCategories: categories.data,
        paymentTypes: paymentTypes.data,
        settings: settings.data,
        status: status,
        hasPendingWrites:
            settings.hasPendingWrites ||
            categories.hasPendingWrites ||
            paymentTypes.hasPendingWrites ||
            recordDocs.hasPendingWrites,
      ),
    );
  }

  /// On a user's very first launch, seed the default payment types
  /// (cash / upi / card) once. Only acts on server-confirmed data: an empty
  /// *cached* list just means the device hasn't synced yet, and re-seeding
  /// would resurrect types the user deleted elsewhere.
  void _maybeSeedPaymentTypes(
    SyncSnapshot<HomeSettings> settings,
    SyncSnapshot<List<PaymentType>> paymentTypes,
  ) {
    if (_seedAttempted) return;
    if (!settings.isLive || !paymentTypes.isLive) return;
    if (settings.data.paymentTypesSeeded || paymentTypes.data.isNotEmpty) {
      _seedAttempted = true;
      return;
    }
    _seedAttempted = true;
    for (final t in PaymentType.seedDefaults) {
      _write(_paymentTypeCollection.doc(t.id).set(t.toJson()));
    }
    _write(
      _settingsDoc.set({'paymentTypesSeeded': true}, SetOptions(merge: true)),
    );
  }

  void _emit(HomeRecordData next) {
    _current = next;
    if (!_controller.isClosed) _controller.add(next);
  }

  /// Writes are intentionally not awaited: Firestore applies them locally at
  /// once (and the listener reflects that immediately), then syncs when it
  /// can. Failures are logged rather than surfacing as unhandled errors.
  void _write(Future<void> future) {
    unawaited(
      future.catchError((Object e) {
        if (kDebugMode) debugPrint('[home] write failed: $e');
      }),
    );
  }

  @override
  Future<void> dispose() async {
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
    await Future.wait([
      _settings.dispose(),
      _categories.dispose(),
      _paymentTypes.dispose(),
      _recordDocs.dispose(),
    ]);
    await _controller.close();
  }

  // ── Records ──────────────────────────────────────────────────────────────

  @override
  void add(HomeRecord record) =>
      _write(_collection.doc(record.id).set(record.toJson()));

  @override
  void update(HomeRecord record) =>
      _write(_collection.doc(record.id).set(record.toJson()));

  @override
  void delete(String recordId) => _write(_collection.doc(recordId).delete());

  // ── Custom categories ────────────────────────────────────────────────────

  @override
  void addCustomCategory(HomeCategory category) =>
      _write(_categoryCollection.doc(category.id).set(category.toJson()));

  @override
  void updateCustomCategory(HomeCategory category) =>
      _write(_categoryCollection.doc(category.id).set(category.toJson()));

  @override
  void deleteCustomCategory(String categoryId) =>
      _write(_categoryCollection.doc(categoryId).delete());

  // ── Payment types ────────────────────────────────────────────────────────

  @override
  void addPaymentType(PaymentType type) =>
      _write(_paymentTypeCollection.doc(type.id).set(type.toJson()));

  @override
  void updatePaymentType(PaymentType type) =>
      _write(_paymentTypeCollection.doc(type.id).set(type.toJson()));

  @override
  void deletePaymentType(String typeId) =>
      _write(_paymentTypeCollection.doc(typeId).delete());

  // ── Settings ─────────────────────────────────────────────────────────────

  void _setSetting(String key, Object value) =>
      _write(_settingsDoc.set({key: value}, SetOptions(merge: true)));

  @override
  void setCurrencyCode(String code) => _setSetting('currencyCode', code);

  @override
  void setShowMonthlyCalendar(bool value) =>
      _setSetting('showMonthlyCalendar', value);

  @override
  void setMonthlyStartDay(int day) => _setSetting('monthlyStartDay', day);

  @override
  void setWeekendAdjustment(String value) =>
      _setSetting('weekendAdjustment', value);

  @override
  void setIsCalendarView(bool value) => _setSetting('isCalendarView', value);
}
