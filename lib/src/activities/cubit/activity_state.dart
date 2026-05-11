import 'package:my_data_app/src/activities/model/activity_model.dart';

class ActivityState {
  final List<ActivityRecord> records;
  final Set<ActivityCategory> selectedCategories;

  const ActivityState({
    required this.records,
    this.selectedCategories = const {},
  });

  ActivityState copyWith({
    List<ActivityRecord>? records,
    Set<ActivityCategory>? selectedCategories,
  }) =>
      ActivityState(
        records: records ?? this.records,
        selectedCategories: selectedCategories ?? this.selectedCategories,
      );
}
