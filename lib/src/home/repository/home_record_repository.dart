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
  List<PaymentType> getPaymentTypes();
  void addPaymentType(PaymentType type);
  void updatePaymentType(PaymentType type);
  void deletePaymentType(String typeId);
  String getCurrencyCode();
  void setCurrencyCode(String code);
  bool getShowMonthlyCalendar();
  void setShowMonthlyCalendar(bool value);
  bool getIsCalendarView();
  void setIsCalendarView(bool value);
  Future<void> init();
}

class FirestoreHomeRecordRepository implements HomeRecordRepository {
  final String uid;
  final FirebaseFirestore _firestore;
  List<HomeRecord> _records = [];
  List<HomeCategory> _customCategories = [];
  List<PaymentType> _paymentTypes = [];
  String _currencyCode = 'INR';
  bool _showMonthlyCalendar = true;
  bool _isCalendarView = false;

  FirestoreHomeRecordRepository({
    required this.uid,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('users').doc(uid).collection('home_records');

  CollectionReference<Map<String, dynamic>> get _categoryCollection =>
      _firestore.collection('users').doc(uid).collection('home_categories');

  CollectionReference<Map<String, dynamic>> get _paymentTypeCollection =>
      _firestore.collection('users').doc(uid).collection('home_payment_types');

  @override
  Future<void> init() async {
    // Load settings
    final settingsSnap = await _settingsDoc.get();
    bool paymentTypesSeeded = false;
    if (settingsSnap.exists) {
      _currencyCode = (settingsSnap.data()?['currencyCode'] as String?) ?? 'INR';
      _showMonthlyCalendar = (settingsSnap.data()?['showMonthlyCalendar'] as bool?) ?? true;
      _isCalendarView =
          (settingsSnap.data()?['isCalendarView'] as bool?) ?? false;
      paymentTypesSeeded =
          (settingsSnap.data()?['paymentTypesSeeded'] as bool?) ?? false;
    }

    // Load custom categories first so records can reference them
    final catSnapshot = await _categoryCollection.get();
    _customCategories = catSnapshot.docs
        .map((doc) => HomeCategory.fromJson(doc.data()))
        .toList();

    // Load payment types. On the very first init for a user, seed the
    // default trio (cash / upi / card). After that, the user is free to add
    // or remove anything — we won't re-seed on subsequent launches even if
    // they delete them all.
    final ptSnapshot = await _paymentTypeCollection.get();
    _paymentTypes = ptSnapshot.docs
        .map((doc) => PaymentType.fromJson(doc.data()))
        .toList();
    if (!paymentTypesSeeded && _paymentTypes.isEmpty) {
      for (final t in PaymentType.seedDefaults) {
        _paymentTypes.add(t);
        _paymentTypeCollection.doc(t.id).set(t.toJson());
      }
      _settingsDoc.set(
        {'paymentTypesSeeded': true},
        SetOptions(merge: true),
      );
    }

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

  @override
  List<PaymentType> getPaymentTypes() => List.unmodifiable(_paymentTypes);

  @override
  void addPaymentType(PaymentType type) {
    _paymentTypes.add(type);
    _paymentTypeCollection.doc(type.id).set(type.toJson());
  }

  @override
  void updatePaymentType(PaymentType type) {
    final i = _paymentTypes.indexWhere((t) => t.id == type.id);
    if (i != -1) {
      _paymentTypes[i] = type;
      _paymentTypeCollection.doc(type.id).set(type.toJson());
    }
  }

  @override
  void deletePaymentType(String typeId) {
    _paymentTypes.removeWhere((t) => t.id == typeId);
    _paymentTypeCollection.doc(typeId).delete();
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

  @override
  bool getShowMonthlyCalendar() => _showMonthlyCalendar;

  @override
  void setShowMonthlyCalendar(bool value) {
    _showMonthlyCalendar = value;
    _settingsDoc.set({'showMonthlyCalendar': value}, SetOptions(merge: true));
  }

  @override
  bool getIsCalendarView() => _isCalendarView;

  @override
  void setIsCalendarView(bool value) {
    _isCalendarView = value;
    _settingsDoc.set({'isCalendarView': value}, SetOptions(merge: true));
  }
}
