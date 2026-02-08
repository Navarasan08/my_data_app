import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_data_app/src/checklist/model/checklist_model.dart';

abstract class ChecklistRepository {
  List<ChecklistGroup> getAll();
  void add(ChecklistGroup group);
  void update(ChecklistGroup group);
  void delete(String groupId);
  Future<void> init();
}

class FirestoreChecklistRepository implements ChecklistRepository {
  final String uid;
  final FirebaseFirestore _firestore;
  List<ChecklistGroup> _checklists = [];

  FirestoreChecklistRepository(
      {required this.uid, FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('users').doc(uid).collection('checklists');

  @override
  Future<void> init() async {
    final snapshot = await _collection.get();
    _checklists =
        snapshot.docs.map((doc) => ChecklistGroup.fromJson(doc.data())).toList();
  }

  @override
  List<ChecklistGroup> getAll() => List.unmodifiable(_checklists);

  @override
  void add(ChecklistGroup group) {
    _checklists.add(group);
    _collection.doc(group.id).set(group.toJson());
  }

  @override
  void update(ChecklistGroup group) {
    final index = _checklists.indexWhere((c) => c.id == group.id);
    if (index != -1) {
      _checklists[index] = group;
      _collection.doc(group.id).set(group.toJson());
    }
  }

  @override
  void delete(String groupId) {
    _checklists.removeWhere((c) => c.id == groupId);
    _collection.doc(groupId).delete();
  }
}
