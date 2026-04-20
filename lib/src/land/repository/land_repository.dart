import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_data_app/src/land/model/land_model.dart';

abstract class LandRepository {
  List<LandRecord> getAll();
  void add(LandRecord record);
  void update(LandRecord record);
  void delete(String id);
  Future<void> init();
}

class FirestoreLandRepository implements LandRepository {
  final String uid;
  final FirebaseFirestore _firestore;
  List<LandRecord> _records = [];

  FirestoreLandRepository({
    required this.uid,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('users').doc(uid).collection('lands');

  @override
  Future<void> init() async {
    final snapshot = await _collection.get();
    _records = snapshot.docs
        .map((doc) => LandRecord.fromJson(doc.data()))
        .toList();
  }

  @override
  List<LandRecord> getAll() => List.unmodifiable(_records);

  @override
  void add(LandRecord record) {
    _records.add(record);
    _collection.doc(record.id).set(record.toJson());
  }

  @override
  void update(LandRecord record) {
    final index = _records.indexWhere((r) => r.id == record.id);
    if (index != -1) {
      _records[index] = record;
      _collection.doc(record.id).set(record.toJson());
    }
  }

  @override
  void delete(String id) {
    _records.removeWhere((r) => r.id == id);
    _collection.doc(id).delete();
  }
}
