import 'package:my_data_app/src/core/sync/sync_snapshot.dart';
import 'package:my_data_app/src/goals/model/goal_model.dart';

class GoalState {
  final List<Goal> goals;

  /// Where [goals] came from: `loading` before the first snapshot, `cached`
  /// until the server confirms, `live` after.
  final SyncStatus syncStatus;

  const GoalState({required this.goals, this.syncStatus = SyncStatus.loading});

  bool get isLive => syncStatus.isLive;

  GoalState copyWith({List<Goal>? goals, SyncStatus? syncStatus}) => GoalState(
    goals: goals ?? this.goals,
    syncStatus: syncStatus ?? this.syncStatus,
  );
}
