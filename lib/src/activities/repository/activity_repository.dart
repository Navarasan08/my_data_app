import 'package:my_data_app/src/activities/model/activity_model.dart';
import 'package:my_data_app/src/core/sync/single_collection_repository.dart';
import 'package:my_data_app/src/core/sync/sync_node.dart';

abstract class ActivityRepository implements SyncNode {
  List<ActivityRecord> getAll();
  void add(ActivityRecord r);
  void update(ActivityRecord r);
  void delete(String id);
}

class FirestoreActivityRepository
    extends SingleCollectionRepository<ActivityRecord>
    implements ActivityRepository {
  FirestoreActivityRepository({required super.uid, super.firestore})
    : super(
        collectionName: 'activities',
        fromDoc: (json, _) => ActivityRecord.fromJson(json),
        toJson: (r) => r.toJson(),
        idOf: (r) => r.id,
      );

  @override
  void add(ActivityRecord r) => store.save(r);

  @override
  void update(ActivityRecord r) => store.save(r);

  @override
  void delete(String id) => store.remove(id);
}
