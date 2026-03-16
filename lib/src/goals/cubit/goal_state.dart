import 'package:my_data_app/src/goals/model/goal_model.dart';

class GoalState {
  final List<Goal> goals;

  const GoalState({required this.goals});

  GoalState copyWith({List<Goal>? goals}) =>
      GoalState(goals: goals ?? this.goals);
}
