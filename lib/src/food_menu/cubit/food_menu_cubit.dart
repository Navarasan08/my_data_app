import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_data_app/src/food_menu/model/food_menu_model.dart';
import 'package:my_data_app/src/food_menu/repository/food_menu_repository.dart';
import 'package:my_data_app/src/food_menu/cubit/food_menu_state.dart';

class FoodMenuCubit extends Cubit<FoodMenuState> {
  final FoodMenuRepository _repository;

  FoodMenuCubit(this._repository)
      : super(FoodMenuState(
          entries: _repository.getAll(),
          selectedWeekday: DateTime.now().weekday,
        ));

  void selectWeekday(int weekday) {
    emit(state.copyWith(selectedWeekday: weekday));
  }

  void addEntry(MealEntry entry) {
    _repository.add(entry);
    emit(state.copyWith(entries: _repository.getAll()));
  }

  void updateEntry(MealEntry entry) {
    _repository.update(entry);
    emit(state.copyWith(entries: _repository.getAll()));
  }

  void deleteEntry(String id) {
    _repository.delete(id);
    emit(state.copyWith(entries: _repository.getAll()));
  }

  List<MealEntry> entriesForWeekday(int weekday) {
    return state.entries
        .where((e) => e.weekday == weekday)
        .toList()
      ..sort((a, b) => a.mealType.index.compareTo(b.mealType.index));
  }

  List<MealEntry> get selectedDayEntries =>
      entriesForWeekday(state.selectedWeekday);

  List<MealEntry> getMeals(int weekday, MealType type) {
    return state.entries
        .where((e) => e.weekday == weekday && e.mealType == type)
        .toList();
  }

  List<MealEntry> getCustomEntries(int weekday) {
    return state.entries
        .where((e) => e.weekday == weekday && e.mealType == MealType.custom)
        .toList()
      ..sort((a, b) => (a.timeHour ?? 0).compareTo(b.timeHour ?? 0));
  }

  int mealsCountForDay(int weekday) {
    return state.entries.where((e) => e.weekday == weekday).length;
  }

  int get totalMeals => state.entries.length;
}
