import 'package:my_data_app/src/activities/model/activity_model.dart';
import 'package:my_data_app/src/core/sync/sync_snapshot.dart';

class ActivityState {
  final List<ActivityRecord> records;
  final Set<ActivityCategory> selectedCategories;

  /// Where [records] came from: `loading` before the first snapshot, `cached`
  /// until the server confirms, `live` after.
  final SyncStatus syncStatus;

  const ActivityState({
    required this.records,
    this.selectedCategories = const {},
    this.syncStatus = SyncStatus.loading,
  });

  bool get isLive => syncStatus.isLive;

  ActivityState copyWith({
    List<ActivityRecord>? records,
    Set<ActivityCategory>? selectedCategories,
    SyncStatus? syncStatus,
  }) => ActivityState(
    records: records ?? this.records,
    selectedCategories: selectedCategories ?? this.selectedCategories,
    syncStatus: syncStatus ?? this.syncStatus,
  );
}
