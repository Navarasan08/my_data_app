import 'package:my_data_app/src/reminder/model/bill_model.dart';

class BillState {
  final List<BillTask> tasks;
  final DateTime selectedDate;

  const BillState({
    required this.tasks,
    required this.selectedDate,
  });

  BillState copyWith({
    List<BillTask>? tasks,
    DateTime? selectedDate,
  }) {
    return BillState(
      tasks: tasks ?? this.tasks,
      selectedDate: selectedDate ?? this.selectedDate,
    );
  }
}
