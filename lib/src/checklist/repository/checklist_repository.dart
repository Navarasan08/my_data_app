import 'package:my_data_app/src/checklist/model/checklist_model.dart';
import 'package:my_data_app/src/core/sync/single_collection_repository.dart';
import 'package:my_data_app/src/core/sync/sync_node.dart';

abstract class ChecklistRepository implements SyncNode {
  List<ChecklistGroup> getAll();
  void add(ChecklistGroup group);
  void update(ChecklistGroup group);
  void delete(String groupId);
}

class FirestoreChecklistRepository
    extends SingleCollectionRepository<ChecklistGroup>
    implements ChecklistRepository {
  FirestoreChecklistRepository({required super.uid, super.firestore})
    : super(
        collectionName: 'checklists',
        fromDoc: (json, _) => ChecklistGroup.fromJson(json),
        toJson: (g) => g.toJson(),
        idOf: (g) => g.id,
      );

  @override
  void add(ChecklistGroup group) => store.save(group);

  @override
  void update(ChecklistGroup group) => store.save(group);

  @override
  void delete(String groupId) => store.remove(groupId);
}
