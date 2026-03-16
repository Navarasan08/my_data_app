import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_data_app/src/schedule/model/schedule_model.dart';

abstract class ScheduleRepository {
  List<ScheduleEntry> getAll();
  void add(ScheduleEntry entry);
  void update(ScheduleEntry entry);
  void delete(String id);
  Future<void> init();
}

class FirestoreScheduleRepository implements ScheduleRepository {
  final String uid;
  final FirebaseFirestore _firestore;
  List<ScheduleEntry> _entries = [];

  FirestoreScheduleRepository({
    required this.uid,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('users').doc(uid).collection('schedules');

  @override
  Future<void> init() async {
    final snapshot = await _collection.get();
    _entries = snapshot.docs
        .map((doc) => ScheduleEntry.fromJson(doc.data()))
        .toList();
  }

  @override
  List<ScheduleEntry> getAll() => List.unmodifiable(_entries);

  @override
  void add(ScheduleEntry entry) {
    _entries.add(entry);
    _collection.doc(entry.id).set(entry.toJson());
  }

  @override
  void update(ScheduleEntry entry) {
    final index = _entries.indexWhere((e) => e.id == entry.id);
    if (index != -1) {
      _entries[index] = entry;
      _collection.doc(entry.id).set(entry.toJson());
    }
  }

  @override
  void delete(String id) {
    _entries.removeWhere((e) => e.id == id);
    _collection.doc(id).delete();
  }
}
