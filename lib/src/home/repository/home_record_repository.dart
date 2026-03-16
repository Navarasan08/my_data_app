import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_data_app/src/home/home_record_model.dart';

abstract class HomeRecordRepository {
  List<HomeRecord> getAll();
  void add(HomeRecord record);
  void update(HomeRecord record);
  void delete(String recordId);
  List<HomeCategory> getCustomCategories();
  void addCustomCategory(HomeCategory category);
  void updateCustomCategory(HomeCategory category);
  void deleteCustomCategory(String categoryId);
  String getCurrencyCode();
  void setCurrencyCode(String code);
  Future<void> init();
}

class FirestoreHomeRecordRepository implements HomeRecordRepository {
  final String uid;
  final FirebaseFirestore _firestore;
  List<HomeRecord> _records = [];
  List<HomeCategory> _customCategories = [];
  String _currencyCode = 'INR';

  FirestoreHomeRecordRepository({
    required this.uid,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('users').doc(uid).collection('home_records');

  CollectionReference<Map<String, dynamic>> get _categoryCollection =>
      _firestore.collection('users').doc(uid).collection('home_categories');

  @override
  Future<void> init() async {
    // Load settings
    final settingsSnap = await _settingsDoc.get();
    if (settingsSnap.exists) {
      _currencyCode = (settingsSnap.data()?['currencyCode'] as String?) ?? 'INR';
    }

    // Load custom categories first so records can reference them
    final catSnapshot = await _categoryCollection.get();
    _customCategories = catSnapshot.docs
        .map((doc) => HomeCategory.fromJson(doc.data()))
        .toList();

    final snapshot = await _collection.get();
    _records = snapshot.docs
        .map((doc) =>
            HomeRecord.fromJson(doc.data(), customCategories: _customCategories))
        .toList();
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

  @override
  List<HomeCategory> getCustomCategories() =>
      List.unmodifiable(_customCategories);

  @override
  void addCustomCategory(HomeCategory category) {
    _customCategories.add(category);
    _categoryCollection.doc(category.id).set(category.toJson());
  }

  @override
  void updateCustomCategory(HomeCategory category) {
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

  DocumentReference<Map<String, dynamic>> get _settingsDoc =>
      _firestore.collection('users').doc(uid).collection('home_settings').doc('prefs');

  @override
  String getCurrencyCode() => _currencyCode;

  @override
  void setCurrencyCode(String code) {
    _currencyCode = code;
    _settingsDoc.set({'currencyCode': code}, SetOptions(merge: true));
  }
}
