import 'package:my_data_app/src/core/sync/single_collection_repository.dart';
import 'package:my_data_app/src/core/sync/sync_node.dart';
import 'package:my_data_app/src/periods/model/period_model.dart';

abstract class PeriodRepository implements SyncNode {
  List<PeriodEntry> getAll();
  void add(PeriodEntry entry);
  void update(PeriodEntry entry);
  void delete(String entryId);
}

class FirestorePeriodRepository extends SingleCollectionRepository<PeriodEntry>
    implements PeriodRepository {
  FirestorePeriodRepository({required super.uid, super.firestore})
    : super(
        collectionName: 'periods',
        fromDoc: (json, _) => PeriodEntry.fromJson(json),
        toJson: (e) => e.toJson(),
        idOf: (e) => e.id,
      );

  @override
  void add(PeriodEntry entry) => store.save(entry);

  @override
  void update(PeriodEntry entry) => store.save(entry);

  @override
  void delete(String entryId) => store.remove(entryId);
}
