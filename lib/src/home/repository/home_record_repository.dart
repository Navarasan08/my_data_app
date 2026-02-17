import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_data_app/src/home/home_record_model.dart';

abstract class HomeRecordRepository {
  List<HomeRecord> getAll();
  void add(HomeRecord record);
  void update(HomeRecord record);
  void delete(String recordId);
  Future<void> init();
}

class FirestoreHomeRecordRepository implements HomeRecordRepository {
  final String uid;
  final FirebaseFirestore _firestore;
  List<HomeRecord> _records = [];

  FirestoreHomeRecordRepository({
    required this.uid,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('users').doc(uid).collection('home_records');

  @override
  Future<void> init() async {
    final snapshot = await _collection.get();
    _records =
        snapshot.docs.map((doc) => HomeRecord.fromJson(doc.data())).toList();
  }

  @override
  List<HomeRecord> getAll() => List.unmodifiable(_records);

  @override
  void add(HomeRecord record) {
    _records.add(record);
    _collection.doc(record.id).set(record.toJson());
  }

  @override
  void update(HomeRecord record) {
    final index = _records.indexWhere((r) => r.id == record.id);
    if (index != -1) {
      _records[index] = record;
      _collection.doc(record.id).set(record.toJson());
    }
  }

  @override
  void delete(String recordId) {
    _records.removeWhere((r) => r.id == recordId);
    _collection.doc(recordId).delete();
  }
}
