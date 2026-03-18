import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_data_app/src/profile_vault/model/profile_vault_model.dart';

abstract class ProfileVaultRepository {
  List<VaultEntry> getAll();
  void add(VaultEntry entry);
  void update(VaultEntry entry);
  void delete(String id);
  Future<void> init();
}

class FirestoreProfileVaultRepository implements ProfileVaultRepository {
  final String uid;
  final FirebaseFirestore _firestore;
  List<VaultEntry> _entries = [];

  FirestoreProfileVaultRepository({
    required this.uid,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('users').doc(uid).collection('vault_entries');

  @override
  Future<void> init() async {
    final snapshot = await _collection.get();
    _entries = snapshot.docs
        .map((doc) => VaultEntry.fromJson(doc.data()))
        .toList();
  }

  @override
  List<VaultEntry> getAll() => List.unmodifiable(_entries);

  @override
  void add(VaultEntry entry) {
    _entries.add(entry);
    _collection.doc(entry.id).set(entry.toJson());
  }

  @override
  void update(VaultEntry entry) {
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
