import 'package:my_data_app/src/core/sync/sync_snapshot.dart';
import 'package:my_data_app/src/land/model/land_model.dart';

class LandState {
  final List<LandRecord> records;

  /// Where [records] came from: `loading` before the first snapshot, `cached`
  /// until the server confirms, `live` after.
  final SyncStatus syncStatus;

  const LandState({
    required this.records,
    this.syncStatus = SyncStatus.loading,
  });

  bool get isLive => syncStatus.isLive;

  LandState copyWith({List<LandRecord>? records, SyncStatus? syncStatus}) =>
      LandState(
        records: records ?? this.records,
        syncStatus: syncStatus ?? this.syncStatus,
      );
}
