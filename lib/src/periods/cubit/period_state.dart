import 'package:my_data_app/src/core/sync/sync_snapshot.dart';
import 'package:my_data_app/src/periods/model/period_model.dart';

class PeriodState {
  final List<PeriodEntry> entries;
  final DateTime selectedMonth;

  /// Where [entries] came from: `loading` before the first snapshot,
  /// `cached` until the server confirms, `live` after.
  final SyncStatus syncStatus;

  const PeriodState({
    required this.entries,
    required this.selectedMonth,
    this.syncStatus = SyncStatus.loading,
  });

  bool get isLive => syncStatus.isLive;

  PeriodState copyWith({
    List<PeriodEntry>? entries,
    DateTime? selectedMonth,
    SyncStatus? syncStatus,
  }) {
    return PeriodState(
      entries: entries ?? this.entries,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
