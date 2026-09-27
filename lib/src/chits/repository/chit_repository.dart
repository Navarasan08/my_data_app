import 'package:my_data_app/src/chits/model/chit_model.dart';
import 'package:my_data_app/src/core/sync/single_collection_repository.dart';
import 'package:my_data_app/src/core/sync/sync_node.dart';

abstract class ChitRepository implements SyncNode {
  List<ChitFund> getAll();
  void add(ChitFund chitFund);
  void update(ChitFund chitFund);
  void delete(String chitFundId);
}

class FirestoreChitRepository extends SingleCollectionRepository<ChitFund>
    implements ChitRepository {
  FirestoreChitRepository({required super.uid, super.firestore})
    : super(
        collectionName: 'chits',
        fromDoc: (json, _) => ChitFund.fromJson(json),
        toJson: (c) => c.toJson(),
        idOf: (c) => c.id,
      );

  @override
  void add(ChitFund chitFund) => store.save(chitFund);

  @override
  void update(ChitFund chitFund) => store.save(chitFund);

  @override
  void delete(String chitFundId) => store.remove(chitFundId);
}
