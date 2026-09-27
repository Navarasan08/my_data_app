import 'package:my_data_app/src/core/sync/sync_snapshot.dart';
import 'package:my_data_app/src/food_menu/model/food_menu_model.dart';

class FoodMenuState {
  final List<MealEntry> entries;
  final int selectedWeekday; // 1=Mon .. 7=Sun

  /// Where [entries] came from: `loading` before the first snapshot,
  /// `cached` until the server confirms, `live` after.
  final SyncStatus syncStatus;

  const FoodMenuState({
    required this.entries,
    required this.selectedWeekday,
    this.syncStatus = SyncStatus.loading,
  });

  bool get isLive => syncStatus.isLive;

  FoodMenuState copyWith({
    List<MealEntry>? entries,
    int? selectedWeekday,
    SyncStatus? syncStatus,
  }) {
    return FoodMenuState(
      entries: entries ?? this.entries,
      selectedWeekday: selectedWeekday ?? this.selectedWeekday,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
