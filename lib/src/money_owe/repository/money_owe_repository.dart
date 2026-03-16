import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_data_app/src/money_owe/model/money_owe_model.dart';

abstract class MoneyOweRepository {
  List<DebtEntry> getAll();
  void add(DebtEntry entry);
  void update(DebtEntry entry);
  void delete(String id);
  Future<void> init();
}

class FirestoreMoneyOweRepository implements MoneyOweRepository {
  final String uid;
  final FirebaseFirestore _firestore;
  List<DebtEntry> _entries = [];

  FirestoreMoneyOweRepository({
    required this.uid,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('users').doc(uid).collection('money_owe');

  @override
  Future<void> init() async {
    final snapshot = await _collection.get();
    _entries =
        snapshot.docs.map((doc) => DebtEntry.fromJson(doc.data())).toList();
  }

  @override
  List<DebtEntry> getAll() => List.unmodifiable(_entries);

  @override
  void add(DebtEntry entry) {
    _entries.add(entry);
    _collection.doc(entry.id).set(entry.toJson());
  }

  @override
  void update(DebtEntry entry) {
    final i = _entries.indexWhere((e) => e.id == entry.id);
    if (i != -1) {
      _entries[i] = entry;
      _collection.doc(entry.id).set(entry.toJson());
    }
  }

  @override
  void delete(String id) {
    _entries.removeWhere((e) => e.id == id);
    _collection.doc(id).delete();
  }
}
