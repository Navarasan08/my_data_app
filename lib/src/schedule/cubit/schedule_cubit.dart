import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_data_app/src/schedule/model/schedule_model.dart';
import 'package:my_data_app/src/schedule/repository/schedule_repository.dart';
import 'package:my_data_app/src/schedule/cubit/schedule_state.dart';

class ScheduleCubit extends Cubit<ScheduleState> {
  final ScheduleRepository _repository;

  ScheduleCubit(this._repository)
      : super(ScheduleState(
          entries: _repository.getAll(),
          selectedDate: DateTime.now(),
        ));

  void addEntry(ScheduleEntry entry) {
    _repository.add(entry);
    emit(state.copyWith(entries: _repository.getAll()));
  }

  void updateEntry(ScheduleEntry entry) {
    _repository.update(entry);
    emit(state.copyWith(entries: _repository.getAll()));
  }

  void deleteEntry(String id) {
    _repository.delete(id);
    emit(state.copyWith(entries: _repository.getAll()));
  }

  void toggleComplete(String id) {
    final entry = state.entries.firstWhere((e) => e.id == id);
    updateEntry(entry.copyWith(isCompleted: !entry.isCompleted));
  }

  void changeDate(DateTime date) {
    emit(state.copyWith(selectedDate: date));
  }

  List<ScheduleEntry> get entriesForSelectedDate {
    final sel = state.selectedDate;
    return state.entries
        .where((e) =>
            e.dateTime.year == sel.year &&
            e.dateTime.month == sel.month &&
            e.dateTime.day == sel.day)
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  List<ScheduleEntry> get upcomingEntries {
    final now = DateTime.now();
    return state.entries
        .where((e) => !e.isCompleted && !e.dateTime.isBefore(now))
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  List<ScheduleEntry> get todayEntries {
    final now = DateTime.now();
    return state.entries
        .where((e) =>
            e.dateTime.year == now.year &&
            e.dateTime.month == now.month &&
            e.dateTime.day == now.day)
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  int get pendingCount =>
      state.entries.where((e) => !e.isCompleted).length;
}
