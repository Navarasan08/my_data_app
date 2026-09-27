import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_data_app/src/core/sync/firestore_document_source.dart';
import 'package:my_data_app/src/core/sync/firestore_list_store.dart';
import 'package:my_data_app/src/core/sync/sync_node.dart';
import 'package:my_data_app/src/core/sync/sync_snapshot.dart';
import 'package:my_data_app/src/days_counter/model/days_counter_model.dart';

abstract class DaysCounterRepository implements SyncNode {
  List<DaysCounterEvent> getEvents();
  void addEvent(DaysCounterEvent e);
  void updateEvent(DaysCounterEvent e);
  void deleteEvent(String id);

  List<DaysCounterEventType> getEventTypes();
  void addEventType(DaysCounterEventType t);
  void updateEventType(DaysCounterEventType t);
  void deleteEventType(String id);
}

/// Per-user preferences for the days counter, stored in one settings doc.
class DaysCounterSettings {
  final bool typesSeeded;

  const DaysCounterSettings({this.typesSeeded = false});

  static const defaults = DaysCounterSettings();

  factory DaysCounterSettings.fromJson(Map<String, dynamic>? json) {
    if (json == null) return defaults;
    return DaysCounterSettings(
      typesSeeded: (json['typesSeeded'] as bool?) ?? false,
    );
  }
}

/// Listener-based Firestore implementation: two realtime collections plus
/// the settings doc, folded into one sync node. The default event types are
/// seeded once per account, and only from server-confirmed data so an empty
/// *cached* list (device not yet synced) never triggers a re-seed.
class FirestoreDaysCounterRepository extends CompositeSyncNode
    implements DaysCounterRepository {
  final String uid;
  final FirestoreListStore<DaysCounterEvent> _events;
  final FirestoreListStore<DaysCounterEventType> _types;
  final FirestoreDocumentSource<DaysCounterSettings> _settings;
  bool _seedAttempted = false;

  factory FirestoreDaysCounterRepository({
    required String uid,
    FirebaseFirestore? firestore,
  }) {
    final user = (firestore ?? FirebaseFirestore.instance)
        .collection('users')
        .doc(uid);
    final events = FirestoreListStore<DaysCounterEvent>(
      collection: user.collection('days_counter_events'),
      fromDoc: (json, _) => DaysCounterEvent.fromJson(json),
      toJson: (e) => e.toJson(),
      idOf: (e) => e.id,
      debugLabel: 'days_counter_events',
    );
    final types = FirestoreListStore<DaysCounterEventType>(
      collection: user.collection('days_counter_event_types'),
      fromDoc: (json, _) => DaysCounterEventType.fromJson(json),
      toJson: (t) => t.toJson(),
      idOf: (t) => t.id,
      debugLabel: 'days_counter_event_types',
    );
    final settings = FirestoreDocumentSource<DaysCounterSettings>(
      ref: user.collection('days_counter_settings').doc('prefs'),
      fromDoc: DaysCounterSettings.fromJson,
      initial: DaysCounterSettings.defaults,
      debugLabel: 'days_counter_settings',
    );
    return FirestoreDaysCounterRepository._(uid, events, types, settings);
  }

  FirestoreDaysCounterRepository._(
    this.uid,
    this._events,
    this._types,
    this._settings,
  ) : super([_events, _types, _settings]);

  @override
  void onNodeChanged() => _maybeSeedEventTypes();

  /// On a user's very first launch, seed the default event types once.
  /// Only acts on server-confirmed data: an empty *cached* list just means
  /// the device hasn't synced yet, and re-seeding would resurrect types the
  /// user deleted elsewhere.
  void _maybeSeedEventTypes() {
    if (_seedAttempted) return;
    final settings = _settings.current;
    if (!settings.isLive || !_types.syncStatus.isLive) return;
    if (settings.data.typesSeeded || _types.items.isNotEmpty) {
      _seedAttempted = true;
      return;
    }
    _seedAttempted = true;
    for (final t in DaysCounterEventType.seedDefaults) {
      _types.save(t);
    }
    fireAndForget(
      _settings.ref.set({'typesSeeded': true}, SetOptions(merge: true)),
      label: 'days_counter_settings',
    );
  }

  // ── Events ───────────────────────────────────────────────────────────────

  @override
  List<DaysCounterEvent> getEvents() => _events.items;

  @override
  void addEvent(DaysCounterEvent e) => _events.save(e);

  @override
  void updateEvent(DaysCounterEvent e) => _events.save(e);

  @override
  void deleteEvent(String id) => _events.remove(id);

  // ── Event types ──────────────────────────────────────────────────────────

  @override
  List<DaysCounterEventType> getEventTypes() => _types.items;

  @override
  void addEventType(DaysCounterEventType t) => _types.save(t);

  @override
  void updateEventType(DaysCounterEventType t) => _types.save(t);

  @override
  void deleteEventType(String id) => _types.remove(id);
}
