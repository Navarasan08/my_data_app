import 'package:my_data_app/src/core/sync/sync_snapshot.dart';
import 'package:my_data_app/src/interest/model/interest_model.dart';

class InterestState {
  final List<InterestRecord> records;

  /// Where [records] came from: `loading` before the first snapshot, `cached`
  /// until the server confirms, `live` after.
  final SyncStatus syncStatus;

  const InterestState({
    required this.records,
    this.syncStatus = SyncStatus.loading,
  });

  bool get isLive => syncStatus.isLive;

  InterestState copyWith({
    List<InterestRecord>? records,
    SyncStatus? syncStatus,
  }) => InterestState(
    records: records ?? this.records,
    syncStatus: syncStatus ?? this.syncStatus,
  );
}
