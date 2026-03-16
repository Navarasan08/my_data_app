import 'package:my_data_app/src/schedule/model/schedule_model.dart';

class ScheduleState {
  final List<ScheduleEntry> entries;
  final DateTime selectedDate;

  const ScheduleState({
    required this.entries,
    required this.selectedDate,
  });

  ScheduleState copyWith({
    List<ScheduleEntry>? entries,
    DateTime? selectedDate,
  }) {
    return ScheduleState(
      entries: entries ?? this.entries,
      selectedDate: selectedDate ?? this.selectedDate,
    );
  }
}
