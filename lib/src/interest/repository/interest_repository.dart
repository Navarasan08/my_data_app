import 'package:my_data_app/src/core/sync/single_collection_repository.dart';
import 'package:my_data_app/src/core/sync/sync_node.dart';
import 'package:my_data_app/src/interest/model/interest_model.dart';

abstract class InterestRepository implements SyncNode {
  List<InterestRecord> getAll();
  void add(InterestRecord r);
  void update(InterestRecord r);
  void delete(String id);
}

class FirestoreInterestRepository
    extends SingleCollectionRepository<InterestRecord>
    implements InterestRepository {
  FirestoreInterestRepository({required super.uid, super.firestore})
    : super(
        collectionName: 'interest_records',
        fromDoc: (json, _) => InterestRecord.fromJson(json),
        toJson: (r) => r.toJson(),
        idOf: (r) => r.id,
      );

  @override
  void add(InterestRecord r) => store.save(r);

  @override
  void update(InterestRecord r) => store.save(r);

  @override
  void delete(String id) => store.remove(id);
}
