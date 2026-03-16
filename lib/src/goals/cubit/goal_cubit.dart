import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_data_app/src/goals/model/goal_model.dart';
import 'package:my_data_app/src/goals/repository/goal_repository.dart';
import 'package:my_data_app/src/goals/cubit/goal_state.dart';

class GoalCubit extends Cubit<GoalState> {
  final GoalRepository _repository;

  GoalCubit(this._repository)
      : super(GoalState(goals: _repository.getAll()));

  void addGoal(Goal goal) {
    _repository.add(goal);
    emit(state.copyWith(goals: _repository.getAll()));
  }

  void updateGoal(Goal goal) {
    _repository.update(goal);
    emit(state.copyWith(goals: _repository.getAll()));
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

  Goal? getGoalById(String id) {
    final matches = state.goals.where((g) => g.id == id);
    return matches.isNotEmpty ? matches.first : null;
  }

  List<Goal> get activeGoals =>
      state.goals.where((g) => !g.isArchived).toList();

  List<Goal> get archivedGoals =>
      state.goals.where((g) => g.isArchived).toList();
}
