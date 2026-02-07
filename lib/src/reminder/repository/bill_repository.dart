import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_data_app/src/reminder/model/bill_model.dart';

abstract class BillRepository {
  List<BillTask> getAll();
  void add(BillTask task);
  void update(BillTask task);
  void delete(String taskId);
  Future<void> init();
}

class InMemoryBillRepository implements BillRepository {
  final List<BillTask> _tasks;

  InMemoryBillRepository()
      : _tasks = [
          BillTask(
            id: '1',
            title: 'Electricity Bill',
            description: 'Monthly electricity payment',
            amount: 120.50,
            recurrence: RecurrenceType.monthly,
            createdDate: DateTime(2024, 1, 5),
          ),
          BillTask(
            id: '2',
            title: 'Gym Membership',
            description: 'Weekly gym payment',
            amount: 25.00,
            recurrence: RecurrenceType.weekly,
            createdDate: DateTime(2024, 1, 1),
          ),
          BillTask(
            id: '3',
            title: 'Take Vitamins',
            description: 'Daily health routine',
            recurrence: RecurrenceType.daily,
            createdDate: DateTime.now(),
          ),
        ];

  @override
  Future<void> init() async {}

  @override
  List<BillTask> getAll() => List.unmodifiable(_tasks);

  @override
  void add(BillTask task) {
    _tasks.add(task);
  }

  @override
  void update(BillTask task) {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
    }
  }

  @override
  void delete(String taskId) {
    _tasks.removeWhere((t) => t.id == taskId);
  }
}

class LocalStorageBillRepository implements BillRepository {
  static const String _storageKey = 'bills_data';
  final SharedPreferences _prefs;
  List<BillTask> _tasks = [];

  LocalStorageBillRepository(this._prefs);

  @override
  Future<void> init() async {
    await _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    final jsonString = _prefs.getString(_storageKey);
    if (jsonString != null) {
      final List<dynamic> jsonList = json.decode(jsonString);
      _tasks = jsonList
          .map((item) => BillTask.fromJson(item as Map<String, dynamic>))
          .toList();
    } else {
      // Initialize with seed data if empty
      _tasks = [
        BillTask(
          id: '1',
          title: 'Electricity Bill',
          description: 'Monthly electricity payment',
          amount: 120.50,
          recurrence: RecurrenceType.monthly,
          createdDate: DateTime(2024, 1, 5),
        ),
        BillTask(
          id: '2',
          title: 'Gym Membership',
          description: 'Weekly gym payment',
          amount: 25.00,
          recurrence: RecurrenceType.weekly,
          createdDate: DateTime(2024, 1, 1),
        ),
        BillTask(
          id: '3',
          title: 'Take Vitamins',
          description: 'Daily health routine',
          recurrence: RecurrenceType.daily,
          createdDate: DateTime.now(),
        ),
      ];
      await _saveToStorage();
    }
  }

  Future<void> _saveToStorage() async {
    final jsonList = _tasks.map((task) => task.toJson()).toList();
    await _prefs.setString(_storageKey, json.encode(jsonList));
  }

  @override
  List<BillTask> getAll() => List.unmodifiable(_tasks);

  @override
  void add(BillTask task) {
    _tasks.add(task);
    _saveToStorage();
  }

  @override
  void update(BillTask task) {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
      _saveToStorage();
    }
  }

  @override
  void delete(String taskId) {
    _tasks.removeWhere((t) => t.id == taskId);
    _saveToStorage();
  }
}

class FirestoreBillRepository implements BillRepository {
  final String uid;
  final FirebaseFirestore _firestore;
  List<BillTask> _tasks = [];

  FirestoreBillRepository({required this.uid, FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('users').doc(uid).collection('bills');

  @override
  Future<void> init() async {
    final snapshot = await _collection.get();
    _tasks = snapshot.docs
        .map((doc) => BillTask.fromJson(doc.data()))
        .toList();
  }

  @override
  List<BillTask> getAll() => List.unmodifiable(_tasks);

  @override
  void add(BillTask task) {
    _tasks.add(task);
    _collection.doc(task.id).set(task.toJson());
  }

  @override
  void update(BillTask task) {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
      _collection.doc(task.id).set(task.toJson());
    }
  }

  @override
  void delete(String taskId) {
    _tasks.removeWhere((t) => t.id == taskId);
    _collection.doc(taskId).delete();
  }
}
