import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_data_app/src/goals/model/goal_model.dart';

abstract class GoalRepository {
  List<Goal> getAll();
  void add(Goal goal);
  void update(Goal goal);
  void delete(String id);
  Future<void> init();
}

class FirestoreGoalRepository implements GoalRepository {
  final String uid;
  final FirebaseFirestore _firestore;
  List<Goal> _goals = [];

  FirestoreGoalRepository({
    required this.uid,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('users').doc(uid).collection('goals');

  @override
  Future<void> init() async {
    final snapshot = await _collection.get();
    _goals = snapshot.docs.map((doc) => Goal.fromJson(doc.data())).toList();
  }

  @override
  List<Goal> getAll() => List.unmodifiable(_goals);

  @override
  void add(Goal goal) {
    _goals.add(goal);
    _collection.doc(goal.id).set(goal.toJson());
  }

  @override
  void update(Goal goal) {
    final index = _goals.indexWhere((g) => g.id == goal.id);
    if (index != -1) {
      _goals[index] = goal;
      _collection.doc(goal.id).set(goal.toJson());
    }
  }

  @override
  void delete(String id) {
    _goals.removeWhere((g) => g.id == id);
    _collection.doc(id).delete();
  }
}
