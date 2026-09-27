import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_data_app/src/food_menu/model/food_menu_model.dart';
import 'package:my_data_app/src/food_menu/repository/food_menu_repository.dart';
import 'package:my_data_app/src/food_menu/cubit/food_menu_state.dart';

class FoodMenuCubit extends Cubit<FoodMenuState> {
  final FoodMenuRepository _repository;
  StreamSubscription<void>? _sub;

  FoodMenuCubit(this._repository)
    : super(
        FoodMenuState(
          entries: _repository.getAll(),
          selectedWeekday: DateTime.now().weekday,
          syncStatus: _repository.syncStatus,
        ),
      ) {
    _sub = _repository.changes.listen((_) => _sync());
  }

  /// Pulls the repository's current list and sync status into state. Runs
  /// on every realtime change and after each local write.
  void _sync() {
    emit(
      state.copyWith(
        entries: _repository.getAll(),
        syncStatus: _repository.syncStatus,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }

  void selectWeekday(int weekday) {
    emit(state.copyWith(selectedWeekday: weekday));
  }

  void addEntry(MealEntry entry) {
    _repository.add(entry);
    _sync();
  }

  void updateEntry(MealEntry entry) {
    _repository.update(entry);
    _sync();
  }

  void deleteEntry(String id) {
    _repository.delete(id);
    _sync();
  }

  List<MealEntry> entriesForWeekday(int weekday) {
    return state.entries.where((e) => e.weekday == weekday).toList()
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
