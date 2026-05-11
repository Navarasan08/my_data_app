import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_data_app/src/days_counter/model/days_counter_model.dart';

abstract class DaysCounterRepository {
  List<DaysCounterEvent> getEvents();
  void addEvent(DaysCounterEvent e);
  void updateEvent(DaysCounterEvent e);
  void deleteEvent(String id);

  List<DaysCounterEventType> getEventTypes();
  void addEventType(DaysCounterEventType t);
  void updateEventType(DaysCounterEventType t);
  void deleteEventType(String id);

  Future<void> init();
}

class FirestoreDaysCounterRepository implements DaysCounterRepository {
  final String uid;
  final FirebaseFirestore _firestore;
  List<DaysCounterEvent> _events = [];
  List<DaysCounterEventType> _types = [];

  FirestoreDaysCounterRepository({
    required this.uid,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _eventsCol => _firestore
      .collection('users')
      .doc(uid)
      .collection('days_counter_events');

  CollectionReference<Map<String, dynamic>> get _typesCol => _firestore
      .collection('users')
      .doc(uid)
      .collection('days_counter_event_types');

  DocumentReference<Map<String, dynamic>> get _settingsDoc => _firestore
      .collection('users')
      .doc(uid)
      .collection('days_counter_settings')
      .doc('prefs');

  @override
  Future<void> init() async {
    final settingsSnap = await _settingsDoc.get();
    bool seeded =
        (settingsSnap.data()?['typesSeeded'] as bool?) ?? false;

    // Event types — seed defaults the very first time.
    final typeSnap = await _typesCol.get();
    _types = typeSnap.docs
        .map((d) => DaysCounterEventType.fromJson(d.data()))
        .toList();
    if (!seeded && _types.isEmpty) {
      for (final t in DaysCounterEventType.seedDefaults) {
        _types.add(t);
        _typesCol.doc(t.id).set(t.toJson());
      }
      _settingsDoc.set({'typesSeeded': true}, SetOptions(merge: true));
    }

    final eventSnap = await _eventsCol.get();
    _events = eventSnap.docs
        .map((d) => DaysCounterEvent.fromJson(d.data()))
        .toList();
  }

  @override
  List<DaysCounterEvent> getEvents() => List.unmodifiable(_events);

  @override
  void addEvent(DaysCounterEvent e) {
    _events.add(e);
    _eventsCol.doc(e.id).set(e.toJson());
  }

  @override
  void updateEvent(DaysCounterEvent e) {
    final i = _events.indexWhere((x) => x.id == e.id);
    if (i != -1) {
      _events[i] = e;
      _eventsCol.doc(e.id).set(e.toJson());
    }
  }

  @override
  void deleteEvent(String id) {
    _events.removeWhere((x) => x.id == id);
    _eventsCol.doc(id).delete();
  }

  @override
  List<DaysCounterEventType> getEventTypes() => List.unmodifiable(_types);

  @override
  void addEventType(DaysCounterEventType t) {
    _types.add(t);
    _typesCol.doc(t.id).set(t.toJson());
  }

  @override
  void updateEventType(DaysCounterEventType t) {
    final i = _types.indexWhere((x) => x.id == t.id);
    if (i != -1) {
      _types[i] = t;
      _typesCol.doc(t.id).set(t.toJson());
    }
  }

  @override
  void deleteEventType(String id) {
    _types.removeWhere((x) => x.id == id);
    _typesCol.doc(id).delete();
  }
}
