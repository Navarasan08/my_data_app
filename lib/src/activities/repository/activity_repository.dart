import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_data_app/src/activities/model/activity_model.dart';
import 'package:my_data_app/src/core/firestore_read.dart';

abstract class ActivityRepository {
  List<ActivityRecord> getAll();
  void add(ActivityRecord r);
  void update(ActivityRecord r);
  void delete(String id);
  Future<void> init();
}

class FirestoreActivityRepository implements ActivityRepository {
  final String uid;
  final FirebaseFirestore _firestore;
  List<ActivityRecord> _items = [];

  FirestoreActivityRepository({
    required this.uid,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('users').doc(uid).collection('activities');

  @override
  Future<void> init() async {
    _load(await readQueryCacheFirst(_collection));
  }

  /// Re-reads from the server, replacing the cache-first data from [init].
  Future<void> refresh() async {
    _load(await _collection.get());
  }

  void _load(QuerySnapshot<Map<String, dynamic>> snap) {
    _items =
        snap.docs.map((d) => ActivityRecord.fromJson(d.data())).toList();
  }

  @override
  List<ActivityRecord> getAll() => List.unmodifiable(_items);

  @override
  void add(ActivityRecord r) {
    _items.add(r);
    _collection.doc(r.id).set(r.toJson());
  }

  @override
  void update(ActivityRecord r) {
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
