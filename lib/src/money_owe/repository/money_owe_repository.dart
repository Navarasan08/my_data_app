import 'package:my_data_app/src/core/sync/single_collection_repository.dart';
import 'package:my_data_app/src/core/sync/sync_node.dart';
import 'package:my_data_app/src/money_owe/model/money_owe_model.dart';

abstract class MoneyOweRepository implements SyncNode {
  List<DebtEntry> getAll();
  void add(DebtEntry entry);
  void update(DebtEntry entry);
  void delete(String id);
}

class FirestoreMoneyOweRepository extends SingleCollectionRepository<DebtEntry>
    implements MoneyOweRepository {
  FirestoreMoneyOweRepository({required super.uid, super.firestore})
    : super(
        collectionName: 'money_owe',
        fromDoc: (json, _) => DebtEntry.fromJson(json),
        toJson: (e) => e.toJson(),
        idOf: (e) => e.id,
      );

  @override
  void add(DebtEntry entry) => store.save(entry);

  @override
  void update(DebtEntry entry) => store.save(entry);

  @override
  void delete(String id) => store.remove(id);
}
