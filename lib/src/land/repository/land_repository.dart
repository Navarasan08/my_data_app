import 'package:my_data_app/src/core/sync/single_collection_repository.dart';
import 'package:my_data_app/src/core/sync/sync_node.dart';
import 'package:my_data_app/src/land/model/land_model.dart';

abstract class LandRepository implements SyncNode {
  List<LandRecord> getAll();
  void add(LandRecord record);
  void update(LandRecord record);
  void delete(String id);
}

class FirestoreLandRepository extends SingleCollectionRepository<LandRecord>
    implements LandRepository {
  FirestoreLandRepository({required super.uid, super.firestore})
    : super(
        collectionName: 'lands',
        fromDoc: (json, _) => LandRecord.fromJson(json),
        toJson: (r) => r.toJson(),
        idOf: (r) => r.id,
      );

  @override
  void add(LandRecord record) => store.save(record);

  @override
  void update(LandRecord record) => store.save(record);

  @override
  void delete(String id) => store.remove(id);
}
