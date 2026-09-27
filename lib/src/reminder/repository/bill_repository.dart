import 'package:my_data_app/src/core/sync/single_collection_repository.dart';
import 'package:my_data_app/src/core/sync/sync_node.dart';
import 'package:my_data_app/src/reminder/model/bill_model.dart';

abstract class BillRepository implements SyncNode {
  List<Bill> getAll();
  void add(Bill bill);
  void update(Bill bill);
  void delete(String billId);
}

class FirestoreBillRepository extends SingleCollectionRepository<Bill>
    implements BillRepository {
  FirestoreBillRepository({required super.uid, super.firestore})
    : super(
        collectionName: 'bills',
        fromDoc: (json, _) => Bill.fromJson(json),
        toJson: (b) => b.toJson(),
        idOf: (b) => b.id,
      );

  @override
  void add(Bill bill) => store.save(bill);

  @override
  void update(Bill bill) => store.save(bill);

  @override
  void delete(String billId) => store.remove(billId);
}
