import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_data_app/src/goals/model/goal_model.dart';
import 'package:my_data_app/src/goals/repository/goal_repository.dart';
import 'package:my_data_app/src/goals/cubit/goal_state.dart';

class GoalCubit extends Cubit<GoalState> {
  final GoalRepository _repository;

  GoalCubit(this._repository)
      : super(GoalState(goals: _repository.getAll())) {
    autoMarkMissedFailures();
  }

  void addGoal(Goal goal) {
    _repository.add(goal);
    emit(state.copyWith(goals: _repository.getAll()));
    if (goal.autoMarkFailures) autoMarkMissedFailures();
  }

  void updateGoal(Goal goal) {
    _repository.update(goal);
    emit(state.copyWith(goals: _repository.getAll()));
    if (goal.autoMarkFailures) autoMarkMissedFailures();
  }

  void deleteGoal(String id) {
    _repository.delete(id);
    emit(state.copyWith(goals: _repository.getAll()));
  }

  void logDay(String goalId, DateTime date, GoalDayStatus status, {String? note}) {
    final goal = state.goals.firstWhere((g) => g.id == goalId);
    final key = Goal.dateKey(date);
    final logs = List<GoalLog>.from(goal.logs)
      ..removeWhere((l) => l.date == key);
    logs.add(GoalLog(date: key, status: status, note: note));
    _repository.update(goal.copyWith(logs: logs));
    emit(state.copyWith(goals: _repository.getAll()));
  }

  void removeLog(String goalId, DateTime date) {
    final goal = state.goals.firstWhere((g) => g.id == goalId);
    final key = Goal.dateKey(date);
    final logs = List<GoalLog>.from(goal.logs)
      ..removeWhere((l) => l.date == key);
    _repository.update(goal.copyWith(logs: logs));
    emit(state.copyWith(goals: _repository.getAll()));
  }

  void archiveGoal(String goalId) {
    final goal = state.goals.firstWhere((g) => g.id == goalId);
    _repository.update(goal.copyWith(isArchived: true));
    emit(state.copyWith(goals: _repository.getAll()));
  }

  /// Backfills missing past-due dates as failures for every active goal that
  /// has [Goal.autoMarkFailures] enabled. Today and future dates are never
  /// touched. Safe to call repeatedly — only writes when something changes.
  void autoMarkMissedFailures() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var anyChanged = false;

    for (final goal in state.goals) {
      if (!goal.autoMarkFailures || goal.isArchived) continue;

      final existingKeys = goal.logs.map((l) => l.date).toSet();
      final newLogs = List<GoalLog>.from(goal.logs);
      var changed = false;

      var cursor = DateTime(
          goal.startDate.year, goal.startDate.month, goal.startDate.day);
      while (cursor.isBefore(today)) {
        if (goal.isDueForDate(cursor)) {
          final key = Goal.dateKey(cursor);
          if (!existingKeys.contains(key)) {
            newLogs.add(GoalLog(date: key, status: GoalDayStatus.failure));
            changed = true;
          }
        }
        cursor = cursor.add(const Duration(days: 1));
      }

      if (changed) {
        _repository.update(goal.copyWith(logs: newLogs));
        anyChanged = true;
      }
    }

    if (anyChanged) {
      emit(state.copyWith(goals: _repository.getAll()));
    }
  }

  Goal? getGoalById(String id) {
    final matches = state.goals.where((g) => g.id == id);
    return matches.isNotEmpty ? matches.first : null;
  }

  List<Goal> get activeGoals =>
      state.goals.where((g) => !g.isArchived && !g.isCompleted).toList();

  List<Goal> get completedGoals =>
      state.goals.where((g) => !g.isArchived && g.isCompleted).toList();

  List<Goal> get archivedGoals =>
      state.goals.where((g) => g.isArchived).toList();
}
