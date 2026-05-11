import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_data_app/src/activities/cubit/activity_state.dart';
import 'package:my_data_app/src/activities/model/activity_model.dart';
import 'package:my_data_app/src/activities/repository/activity_repository.dart';

class ActivityCubit extends Cubit<ActivityState> {
  final ActivityRepository _repository;

  ActivityCubit(this._repository)
      : super(ActivityState(records: _repository.getAll()));

  void addRecord(ActivityRecord r) {
    _repository.add(r);
    _emit();
  }

  void updateRecord(ActivityRecord r) {
    _repository.update(r.copyWith(updatedAt: DateTime.now()));
    _emit();
  }

  void deleteRecord(String id) {
    _repository.delete(id);
    _emit();
  }

  ActivityRecord? getById(String id) {
    final m = state.records.where((r) => r.id == id);
    return m.isNotEmpty ? m.first : null;
  }

  /// Records sorted by start date (most recent first), filtered by the
  /// selected categories.
  List<ActivityRecord> get filtered {
    var list = state.records;
    if (state.selectedCategories.isNotEmpty) {
      list = list
          .where((r) => state.selectedCategories.contains(r.category))
          .toList();
    }
    return List<ActivityRecord>.from(list)
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
  }

  void toggleCategory(ActivityCategory c) {
    final next = Set<ActivityCategory>.from(state.selectedCategories);
    if (next.contains(c)) {
      next.remove(c);
    } else {
      next.add(c);
    }
    emit(state.copyWith(selectedCategories: next));
  }

  void clearCategoryFilter() {
    emit(state.copyWith(selectedCategories: const {}));
  }

  int get currentMonthCount {
    final now = DateTime.now();
    return state.records.where((r) =>
        r.startDate.year == now.year && r.startDate.month == now.month).length;
  }

  void _emit() => emit(state.copyWith(records: _repository.getAll()));
}
