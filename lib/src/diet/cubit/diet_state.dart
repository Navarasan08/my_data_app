import 'package:my_data_app/src/diet/model/diet_model.dart';

class DietState {
  final List<FoodItem> items;
  final List<FoodEntry> entries;

  /// First-of-month anchor for the month currently being viewed on the
  /// diet page. Drives all "this month" aggregates.
  final DateTime selectedMonth;

  const DietState({
    required this.items,
    required this.entries,
    required this.selectedMonth,
  });

  DietState copyWith({
    List<FoodItem>? items,
    List<FoodEntry>? entries,
    DateTime? selectedMonth,
  }) =>
      DietState(
        items: items ?? this.items,
        entries: entries ?? this.entries,
        selectedMonth: selectedMonth ?? this.selectedMonth,
      );
}
