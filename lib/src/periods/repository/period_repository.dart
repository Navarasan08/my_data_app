import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_data_app/src/periods/model/period_model.dart';

abstract class PeriodRepository {
  List<PeriodEntry> getAll();
  void add(PeriodEntry entry);
  void update(PeriodEntry entry);
  void delete(String entryId);
  Future<void> init();
}

class FirestorePeriodRepository implements PeriodRepository {
  final String uid;
  final FirebaseFirestore _firestore;
  List<PeriodEntry> _entries = [];

  FirestorePeriodRepository({required this.uid, FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('users').doc(uid).collection('periods');

  @override
  Future<void> init() async {
    final snapshot = await _collection.get();
    _entries =
        snapshot.docs.map((doc) => PeriodEntry.fromJson(doc.data())).toList();
  }

  @override
  List<PeriodEntry> getAll() => List.unmodifiable(_entries);

  @override
  void add(PeriodEntry entry) {
    _entries.add(entry);
    _collection.doc(entry.id).set(entry.toJson());
  }

  @override
  void update(PeriodEntry entry) {
    final index = _entries.indexWhere((e) => e.id == entry.id);
    if (index != -1) {
      _entries[index] = entry;
      _collection.doc(entry.id).set(entry.toJson());
    }
  }

  @override
  void delete(String entryId) {
    _entries.removeWhere((e) => e.id == entryId);
    _collection.doc(entryId).delete();
  }
}
