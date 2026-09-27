import 'package:my_data_app/src/checklist/model/checklist_model.dart';
import 'package:my_data_app/src/core/sync/sync_snapshot.dart';

class ChecklistState {
  final List<ChecklistGroup> checklists;

  /// Where [checklists] came from: `loading` before the first snapshot,
  /// `cached` until the server confirms, `live` after.
  final SyncStatus syncStatus;

  const ChecklistState({
    required this.checklists,
    this.syncStatus = SyncStatus.loading,
  });

  bool get isLive => syncStatus.isLive;

  ChecklistState copyWith({
    List<ChecklistGroup>? checklists,
    SyncStatus? syncStatus,
  }) {
    return ChecklistState(
      checklists: checklists ?? this.checklists,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
