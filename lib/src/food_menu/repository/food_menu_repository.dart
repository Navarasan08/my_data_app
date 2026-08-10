import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_data_app/src/core/firestore_read.dart';
import 'package:my_data_app/src/food_menu/model/food_menu_model.dart';

abstract class FoodMenuRepository {
  List<MealEntry> getAll();
  void add(MealEntry entry);
  void update(MealEntry entry);
  void delete(String id);
  Future<void> init();
}

class FirestoreFoodMenuRepository implements FoodMenuRepository {
  final String uid;
  final FirebaseFirestore _firestore;
  List<MealEntry> _entries = [];

  FirestoreFoodMenuRepository({
    required this.uid,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('users').doc(uid).collection('food_menu');

  @override
  Future<void> init() async {
    _load(await readQueryCacheFirst(_collection));
  }

  /// Re-reads from the server, replacing the cache-first data from [init].
  Future<void> refresh() async {
    _load(await _collection.get());
  }

  void _load(QuerySnapshot<Map<String, dynamic>> snapshot) {
    _entries = snapshot.docs
        .map((doc) => MealEntry.fromJson(doc.data()))
        .toList();
  }

  @override
  List<MealEntry> getAll() => List.unmodifiable(_entries);

  @override
  void add(MealEntry entry) {
    _entries.add(entry);
    _collection.doc(entry.id).set(entry.toJson());
  }

  @override
  void update(MealEntry entry) {
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
