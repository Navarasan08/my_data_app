import 'package:my_data_app/src/core/sync/sync_snapshot.dart';
import 'package:my_data_app/src/diet/model/diet_model.dart';

class DietState {
  final List<FoodItem> items;
  final List<FoodEntry> entries;

  /// First-of-month anchor for the month currently being viewed on the
  /// diet page. Drives all "this month" aggregates.
  final DateTime selectedMonth;

  /// Where the lists came from: `loading` before the first snapshot,
  /// `cached` until the server confirms, `live` after.
  final SyncStatus syncStatus;

  const DietState({
    required this.items,
    required this.entries,
    required this.selectedMonth,
    this.syncStatus = SyncStatus.loading,
  });

  bool get isLive => syncStatus.isLive;

  DietState copyWith({
    List<FoodItem>? items,
    List<FoodEntry>? entries,
    DateTime? selectedMonth,
    SyncStatus? syncStatus,
  }) => DietState(
    items: items ?? this.items,
    entries: entries ?? this.entries,
    selectedMonth: selectedMonth ?? this.selectedMonth,
    syncStatus: syncStatus ?? this.syncStatus,
  );
}
