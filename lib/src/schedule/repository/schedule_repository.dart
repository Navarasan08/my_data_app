import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_data_app/src/schedule/model/schedule_model.dart';

abstract class ScheduleRepository {
  List<ScheduleEntry> getAll();
  void add(ScheduleEntry entry);
  void update(ScheduleEntry entry);
  void delete(String id);

  List<ScheduleCategory> getCustomCategories();
  void addCustomCategory(ScheduleCategory category);
  void updateCustomCategory(ScheduleCategory category);
  void deleteCustomCategory(String categoryId);

  Future<void> init();
}

class FirestoreScheduleRepository implements ScheduleRepository {
  final String uid;
  final FirebaseFirestore _firestore;
  List<ScheduleEntry> _entries = [];
  List<ScheduleCategory> _customCategories = [];

  FirestoreScheduleRepository({
    required this.uid,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('users').doc(uid).collection('schedules');

  CollectionReference<Map<String, dynamic>> get _categoryCollection => _firestore
      .collection('users')
      .doc(uid)
      .collection('schedule_categories');

  @override
  Future<void> init() async {
    // Load custom categories first so entries can reference them
    final catSnapshot = await _categoryCollection.get();
    _customCategories = catSnapshot.docs
        .map((doc) => ScheduleCategory.fromJson(doc.data()))
        .toList();

    final snapshot = await _collection.get();
    _entries = snapshot.docs
        .map((doc) => ScheduleEntry.fromJson(doc.data(),
            customCategories: _customCategories))
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

  @override
  List<ScheduleCategory> getCustomCategories() =>
      List.unmodifiable(_customCategories);

  @override
  void addCustomCategory(ScheduleCategory category) {
    _customCategories.add(category);
    _categoryCollection.doc(category.id).set(category.toJson());
  }

  @override
  void updateCustomCategory(ScheduleCategory category) {
    final index = _customCategories.indexWhere((c) => c.id == category.id);
    if (index != -1) {
      _customCategories[index] = category;
      _categoryCollection.doc(category.id).set(category.toJson());
    }
  }

  @override
  void deleteCustomCategory(String categoryId) {
    _customCategories.removeWhere((c) => c.id == categoryId);
    _categoryCollection.doc(categoryId).delete();
  }
}
