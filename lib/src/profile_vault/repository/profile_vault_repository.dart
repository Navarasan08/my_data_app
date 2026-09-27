import 'package:my_data_app/src/core/sync/single_collection_repository.dart';
import 'package:my_data_app/src/core/sync/sync_node.dart';
import 'package:my_data_app/src/profile_vault/model/profile_vault_model.dart';

abstract class ProfileVaultRepository implements SyncNode {
  List<VaultEntry> getAll();
  void add(VaultEntry entry);
  void update(VaultEntry entry);
  void delete(String id);
}

class FirestoreProfileVaultRepository
    extends SingleCollectionRepository<VaultEntry>
    implements ProfileVaultRepository {
  FirestoreProfileVaultRepository({required super.uid, super.firestore})
    : super(
        collectionName: 'vault_entries',
        fromDoc: (json, _) => VaultEntry.fromJson(json),
        toJson: (e) => e.toJson(),
        idOf: (e) => e.id,
      );

  @override
  void add(VaultEntry entry) => store.save(entry);

  @override
  void update(VaultEntry entry) => store.save(entry);

  @override
  void delete(String id) => store.remove(id);
}
