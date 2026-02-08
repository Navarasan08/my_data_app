import 'package:my_data_app/src/periods/model/period_model.dart';

class PeriodState {
  final List<PeriodEntry> entries;
  final DateTime selectedMonth;

  const PeriodState({required this.entries, required this.selectedMonth});

  PeriodState copyWith({List<PeriodEntry>? entries, DateTime? selectedMonth}) {
    return PeriodState(
      entries: entries ?? this.entries,
      selectedMonth: selectedMonth ?? this.selectedMonth,
    );
  }
}
