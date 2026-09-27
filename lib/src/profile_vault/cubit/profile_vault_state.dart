import 'package:my_data_app/src/core/sync/sync_snapshot.dart';
import 'package:my_data_app/src/profile_vault/model/profile_vault_model.dart';

class ProfileVaultState {
  final List<VaultEntry> entries;

  /// Where [entries] came from: `loading` before the first snapshot, `cached`
  /// until the server confirms, `live` after.
  final SyncStatus syncStatus;

  const ProfileVaultState({
    required this.entries,
    this.syncStatus = SyncStatus.loading,
  });

  bool get isLive => syncStatus.isLive;

  ProfileVaultState copyWith({
    List<VaultEntry>? entries,
    SyncStatus? syncStatus,
  }) => ProfileVaultState(
    entries: entries ?? this.entries,
    syncStatus: syncStatus ?? this.syncStatus,
  );
}
