import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_data_app/src/interest/model/interest_model.dart';

abstract class InterestRepository {
  List<InterestRecord> getAll();
  void add(InterestRecord r);
  void update(InterestRecord r);
  void delete(String id);
  Future<void> init();
}

class FirestoreInterestRepository implements InterestRepository {
  final String uid;
  final FirebaseFirestore _firestore;
  List<InterestRecord> _items = [];

  FirestoreInterestRepository({
    required this.uid,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('users').doc(uid).collection('interest_records');

  @override
  Future<void> init() async {
    final snap = await _collection.get();
    _items =
        snap.docs.map((d) => InterestRecord.fromJson(d.data())).toList();
  }

  @override
  List<InterestRecord> getAll() => List.unmodifiable(_items);

  @override
  void add(InterestRecord r) {
    _items.add(r);
    _collection.doc(r.id).set(r.toJson());
  }

  @override
  void update(InterestRecord r) {
    final i = _items.indexWhere((x) => x.id == r.id);
    if (i != -1) {
      _items[i] = r;
      _collection.doc(r.id).set(r.toJson());
    }
  }

  @override
  void delete(String id) {
    _items.removeWhere((x) => x.id == id);
    _collection.doc(id).delete();
  }
}
