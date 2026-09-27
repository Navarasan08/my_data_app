import 'package:my_data_app/src/chits/model/chit_model.dart';
import 'package:my_data_app/src/core/sync/sync_snapshot.dart';

class ChitState {
  final List<ChitFund> chitFunds;

  /// Where [chitFunds] came from: `loading` before the first snapshot,
  /// `cached` until the server confirms, `live` after.
  final SyncStatus syncStatus;

  const ChitState({
    required this.chitFunds,
    this.syncStatus = SyncStatus.loading,
  });

  bool get isLive => syncStatus.isLive;

  ChitState copyWith({List<ChitFund>? chitFunds, SyncStatus? syncStatus}) {
    return ChitState(
      chitFunds: chitFunds ?? this.chitFunds,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
