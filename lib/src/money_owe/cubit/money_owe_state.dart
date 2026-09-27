import 'package:my_data_app/src/core/sync/sync_snapshot.dart';
import 'package:my_data_app/src/money_owe/model/money_owe_model.dart';

class MoneyOweState {
  final List<DebtEntry> entries;

  /// Where [entries] came from: `loading` before the first snapshot, `cached`
  /// until the server confirms, `live` after.
  final SyncStatus syncStatus;

  const MoneyOweState({
    required this.entries,
    this.syncStatus = SyncStatus.loading,
  });

  bool get isLive => syncStatus.isLive;

  MoneyOweState copyWith({List<DebtEntry>? entries, SyncStatus? syncStatus}) =>
      MoneyOweState(
        entries: entries ?? this.entries,
        syncStatus: syncStatus ?? this.syncStatus,
      );
}
