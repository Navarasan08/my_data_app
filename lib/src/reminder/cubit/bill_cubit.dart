import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_data_app/src/reminder/model/bill_model.dart';
import 'package:my_data_app/src/reminder/repository/bill_repository.dart';
import 'package:my_data_app/src/reminder/cubit/bill_state.dart';

class BillCubit extends Cubit<BillState> {
  final BillRepository _repository;

  BillCubit(this._repository)
      : super(BillState(
          tasks: _repository.getAll(),
          selectedDate: DateTime.now(),
        ));

  void addTask(BillTask task) {
    _repository.add(task);
    emit(state.copyWith(tasks: _repository.getAll()));
  }

  void updateTask(BillTask updatedTask) {
    final existing = state.tasks.firstWhere((t) => t.id == updatedTask.id);
    final merged = updatedTask.copyWith(
      completedOccurrences: existing.completedOccurrences,
    );
    _repository.update(merged);
    emit(state.copyWith(tasks: _repository.getAll()));
  }

  void deleteTask(String taskId) {
    _repository.delete(taskId);
    emit(state.copyWith(tasks: _repository.getAll()));
  }

  void toggleCompletion(String taskId, DateTime date) {
    final task = state.tasks.firstWhere((t) => t.id == taskId);
    final updatedOccurrences = List<DateTime>.from(task.completedOccurrences);

    if (task.isCompletedForDate(date)) {
      updatedOccurrences.removeWhere((d) =>
          d.year == date.year && d.month == date.month && d.day == date.day);
    } else {
      updatedOccurrences.add(date);
    }

    _repository.update(task.copyWith(completedOccurrences: updatedOccurrences));
    emit(state.copyWith(tasks: _repository.getAll()));
  }

  void changeMonth(int monthDelta) {
    final current = state.selectedDate;
    emit(state.copyWith(
      selectedDate: DateTime(current.year, current.month + monthDelta, 1),
    ));
  }

  List<BillTask> get tasksForSelectedMonth {
    final sel = state.selectedDate;
    return state.tasks.where((task) {
      final daysInMonth = DateTime(sel.year, sel.month + 1, 0).day;
      for (int day = 1; day <= daysInMonth; day++) {
        final date = DateTime(sel.year, sel.month, day);
        if (task.isDueForDate(date)) return true;
      }
      return false;
    }).toList();
  }

  Map<String, dynamic> get monthStatistics {
    final tasksForMonth = tasksForSelectedMonth;
    final sel = state.selectedDate;
    final now = DateTime.now();

    int totalOccurrences = 0;
    int completedOccurrences = 0;
    int missedOccurrences = 0;
    int pendingOccurrences = 0;
    double totalAmount = 0;
    double paidAmount = 0;
    double missedAmount = 0;
    double pendingAmount = 0;

    for (var task in tasksForMonth) {
      final daysInMonth = DateTime(sel.year, sel.month + 1, 0).day;

      for (int day = 1; day <= daysInMonth; day++) {
        final date = DateTime(sel.year, sel.month, day);
        if (task.isDueForDate(date)) {
          totalOccurrences++;

          if (task.isCompletedForDate(date)) {
            completedOccurrences++;
            if (task.amount != null) paidAmount += task.amount!;
          } else {
            final dateOnly = DateTime(date.year, date.month, date.day);
            final nowOnly = DateTime(now.year, now.month, now.day);

            if (dateOnly.isBefore(nowOnly)) {
              missedOccurrences++;
              if (task.amount != null) missedAmount += task.amount!;
            } else {
              pendingOccurrences++;
              if (task.amount != null) pendingAmount += task.amount!;
            }
          }

          if (task.amount != null) totalAmount += task.amount!;
        }
      }
    }

    return {
      'total': totalOccurrences,
      'completed': completedOccurrences,
      'missed': missedOccurrences,
      'pending': pendingOccurrences,
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'missedAmount': missedAmount,
      'pendingAmount': pendingAmount,
    };
  }
}
