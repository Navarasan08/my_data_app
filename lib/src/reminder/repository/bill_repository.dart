import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_data_app/src/reminder/model/bill_model.dart';

abstract class BillRepository {
  List<Bill> getAll();
  void add(Bill bill);
  void update(Bill bill);
  void delete(String billId);
  Future<void> init();
}

/// Seed bills with due dates in the current month, so a fresh install shows
/// meaningful "days left" values.
List<Bill> _seedBills() {
  final now = DateTime.now();
  DateTime due(int day) => DateTime(now.year, now.month, day);
  return [
    Bill(
      id: '1',
      name: 'Electricity Bill',
      description: 'Monthly electricity payment',
      amount: 120.50,
      dueDate: due(5),
      createdDate: now,
    ),
    Bill(
      id: '2',
      name: 'House Rent',
      description: 'Monthly rent',
      amount: 8000,
      dueDate: due(1),
      createdDate: now,
    ),
    Bill(
      id: '3',
      name: 'Internet',
      description: 'Broadband subscription',
      amount: 799,
      dueDate: due(10),
      createdDate: now,
    ),
  ];
}

class InMemoryBillRepository implements BillRepository {
  final List<Bill> _bills;

  InMemoryBillRepository() : _bills = _seedBills();

  @override
  Future<void> init() async {}

  @override
  List<Bill> getAll() => List.unmodifiable(_bills);

  @override
  void add(Bill bill) {
    _bills.add(bill);
  }

  @override
  void update(Bill bill) {
    final index = _bills.indexWhere((b) => b.id == bill.id);
    if (index != -1) {
      _bills[index] = bill;
    }
  }

  @override
  void delete(String billId) {
    _bills.removeWhere((b) => b.id == billId);
  }
}

class LocalStorageBillRepository implements BillRepository {
  static const String _storageKey = 'bills_data';
  final SharedPreferences _prefs;
  List<Bill> _bills = [];

  LocalStorageBillRepository(this._prefs);

  @override
  Future<void> init() async {
    await _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    final jsonString = _prefs.getString(_storageKey);
    if (jsonString != null) {
      final List<dynamic> jsonList = json.decode(jsonString);
      _bills = jsonList
          .map((item) => Bill.fromJson(item as Map<String, dynamic>))
          .toList();
    } else {
      _bills = _seedBills();
      await _saveToStorage();
    }
  }

  Future<void> _saveToStorage() async {
    final jsonList = _bills.map((bill) => bill.toJson()).toList();
    await _prefs.setString(_storageKey, json.encode(jsonList));
  }

  @override
  List<Bill> getAll() => List.unmodifiable(_bills);

  @override
  void add(Bill bill) {
    _bills.add(bill);
    _saveToStorage();
  }

  @override
  void update(Bill bill) {
    final index = _bills.indexWhere((b) => b.id == bill.id);
    if (index != -1) {
      _bills[index] = bill;
      _saveToStorage();
    }
  }

  @override
  void delete(String billId) {
    _bills.removeWhere((b) => b.id == billId);
    _saveToStorage();
  }
}

class FirestoreBillRepository implements BillRepository {
  final String uid;
  final FirebaseFirestore _firestore;
  List<Bill> _bills = [];

  FirestoreBillRepository({required this.uid, FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('users').doc(uid).collection('bills');

  @override
  Future<void> init() async {
    final snapshot = await _collection.get();
    _bills = snapshot.docs.map((doc) => Bill.fromJson(doc.data())).toList();
  }

  @override
  List<Bill> getAll() => List.unmodifiable(_bills);

  @override
  void add(Bill bill) {
    _bills.add(bill);
    _collection.doc(bill.id).set(bill.toJson());
  }

  @override
  void update(Bill bill) {
    final index = _bills.indexWhere((b) => b.id == bill.id);
    if (index != -1) {
      _bills[index] = bill;
      _collection.doc(bill.id).set(bill.toJson());
    }
  }

  @override
  void delete(String billId) {
    _bills.removeWhere((b) => b.id == billId);
    _collection.doc(billId).delete();
  }
}
