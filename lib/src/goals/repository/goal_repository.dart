import 'package:my_data_app/src/core/sync/single_collection_repository.dart';
import 'package:my_data_app/src/core/sync/sync_node.dart';
import 'package:my_data_app/src/goals/model/goal_model.dart';

abstract class GoalRepository implements SyncNode {
  List<Goal> getAll();
  void add(Goal goal);
  void update(Goal goal);
  void delete(String id);
}

class FirestoreGoalRepository extends SingleCollectionRepository<Goal>
    implements GoalRepository {
  FirestoreGoalRepository({required super.uid, super.firestore})
    : super(
        collectionName: 'goals',
        fromDoc: (json, _) => Goal.fromJson(json),
        toJson: (g) => g.toJson(),
        idOf: (g) => g.id,
      );

  @override
  void add(Goal goal) => store.save(goal);

  @override
  void update(Goal goal) => store.save(goal);

  @override
  void delete(String id) => store.remove(id);
}
