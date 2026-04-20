import 'package:my_data_app/src/schedule/model/schedule_model.dart';

enum ScheduleFilter { all, thisMonth }

class ScheduleState {
  final List<ScheduleEntry> entries;
  final DateTime selectedDate;
  final ScheduleFilter filter;
  final List<ScheduleCategory> customCategories;

  const ScheduleState({
    required this.entries,
    required this.selectedDate,
    this.filter = ScheduleFilter.all,
    this.customCategories = const [],
  });

  ScheduleState copyWith({
    List<ScheduleEntry>? entries,
    DateTime? selectedDate,
    ScheduleFilter? filter,
    List<ScheduleCategory>? customCategories,
  }) {
    return ScheduleState(
      entries: entries ?? this.entries,
      selectedDate: selectedDate ?? this.selectedDate,
      filter: filter ?? this.filter,
      customCategories: customCategories ?? this.customCategories,
    );
  }
}
