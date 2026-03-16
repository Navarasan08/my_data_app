import 'package:my_data_app/src/food_menu/model/food_menu_model.dart';

class FoodMenuState {
  final List<MealEntry> entries;
  final int selectedWeekday; // 1=Mon .. 7=Sun

  const FoodMenuState({
    required this.entries,
    required this.selectedWeekday,
  });

  FoodMenuState copyWith({
    List<MealEntry>? entries,
    int? selectedWeekday,
  }) {
    return FoodMenuState(
      entries: entries ?? this.entries,
      selectedWeekday: selectedWeekday ?? this.selectedWeekday,
    );
  }
}
