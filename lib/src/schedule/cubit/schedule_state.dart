import 'package:my_data_app/src/core/sync/sync_snapshot.dart';
import 'package:my_data_app/src/schedule/model/schedule_model.dart';

enum ScheduleFilter { all, thisMonth }

class ScheduleState {
  final List<ScheduleEntry> entries;
  final DateTime selectedDate;
  final ScheduleFilter filter;
  final List<ScheduleCategory> customCategories;

  /// Where the lists came from: `loading` before the first snapshot,
  /// `cached` until the server confirms, `live` after.
  final SyncStatus syncStatus;

  const ScheduleState({
    required this.entries,
    required this.selectedDate,
    this.filter = ScheduleFilter.all,
    this.customCategories = const [],
    this.syncStatus = SyncStatus.loading,
  });

  bool get isLive => syncStatus.isLive;

  ScheduleState copyWith({
    List<ScheduleEntry>? entries,
    DateTime? selectedDate,
    ScheduleFilter? filter,
    List<ScheduleCategory>? customCategories,
    SyncStatus? syncStatus,
  }) {
    return ScheduleState(
      entries: entries ?? this.entries,
      selectedDate: selectedDate ?? this.selectedDate,
      filter: filter ?? this.filter,
      customCategories: customCategories ?? this.customCategories,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
