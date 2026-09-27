import 'package:my_data_app/src/core/sync/sync_snapshot.dart';
import 'package:my_data_app/src/pregnancy/model/pregnancy_model.dart';

class PregnancyState {
  final PregnancyProfile profile;
  final List<PregnancyCheckItem> checks;
  final List<PregnancyLog> logs;

  /// Where the data came from: `loading` before the first snapshot,
  /// `cached` until the server confirms, `live` after.
  final SyncStatus syncStatus;

  const PregnancyState({
    this.profile = PregnancyProfile.defaults,
    this.checks = const [],
    this.logs = const [],
    this.syncStatus = SyncStatus.loading,
  });

  bool get isLive => syncStatus.isLive;
  bool get isLoading => syncStatus.isLoading;

  PregnancyState copyWith({
    PregnancyProfile? profile,
    List<PregnancyCheckItem>? checks,
    List<PregnancyLog>? logs,
    SyncStatus? syncStatus,
  }) => PregnancyState(
    profile: profile ?? this.profile,
    checks: checks ?? this.checks,
    logs: logs ?? this.logs,
    syncStatus: syncStatus ?? this.syncStatus,
  );
}
