import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_data_app/src/periods/model/period_model.dart';
import 'package:my_data_app/src/periods/repository/period_repository.dart';
import 'package:my_data_app/src/periods/cubit/period_state.dart';

class PeriodCubit extends Cubit<PeriodState> {
  final PeriodRepository _repository;

  PeriodCubit(this._repository)
      : super(PeriodState(
          entries: _repository.getAll(),
          selectedMonth: DateTime.now(),
        ));

  void addEntry(PeriodEntry entry) {
    _repository.add(entry);
    emit(state.copyWith(entries: _repository.getAll()));
  }

  void updateEntry(PeriodEntry entry) {
    _repository.update(entry);
    emit(state.copyWith(entries: _repository.getAll()));
  }

  void deleteEntry(String entryId) {
    _repository.delete(entryId);
    emit(state.copyWith(entries: _repository.getAll()));
  }

  void changeMonth(int delta) {
    final current = state.selectedMonth;
    emit(state.copyWith(
      selectedMonth: DateTime(current.year, current.month + delta, 1),
    ));
  }

  /// Entries sorted by start date (most recent first)
  List<PeriodEntry> get sortedEntries {
    final sorted = List<PeriodEntry>.from(state.entries);
    sorted.sort((a, b) => b.startDate.compareTo(a.startDate));
    return sorted;
  }

  /// Average cycle length in days (gap between consecutive period starts)
  int get averageCycleLength {
    final sorted = List<PeriodEntry>.from(state.entries);
    sorted.sort((a, b) => a.startDate.compareTo(b.startDate));
    if (sorted.length < 2) return 28;

    int totalDays = 0;
    int count = 0;
    for (int i = 1; i < sorted.length; i++) {
      totalDays += sorted[i].startDate.difference(sorted[i - 1].startDate).inDays;
      count++;
    }
    return (totalDays / count).round();
  }

  /// Average period duration in days
  int get averagePeriodLength {
    if (state.entries.isEmpty) return 5;
    final total =
        state.entries.fold<int>(0, (sum, e) => sum + e.periodLength);
    return (total / state.entries.length).round();
  }

  /// Predicted next period start date
  DateTime? get nextPeriodStart {
    if (state.entries.isEmpty) return null;
    final sorted = sortedEntries;
    final lastStart = sorted.first.startDate;
    return lastStart.add(Duration(days: averageCycleLength));
  }

  /// Predicted ovulation date (14 days before next period)
  DateTime? get ovulationDate {
    final next = nextPeriodStart;
    if (next == null) return null;
    return next.subtract(const Duration(days: 14));
  }

  /// Fertile window start (5 days before ovulation)
  DateTime? get fertileWindowStart {
    final ov = ovulationDate;
    if (ov == null) return null;
    return ov.subtract(const Duration(days: 5));
  }

  /// Fertile window end (1 day after ovulation)
  DateTime? get fertileWindowEnd {
    final ov = ovulationDate;
    if (ov == null) return null;
    return ov.add(const Duration(days: 1));
  }

  /// Check if a date falls within any logged period
  bool isPeriodDay(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    for (final entry in state.entries) {
      final start =
          DateTime(entry.startDate.year, entry.startDate.month, entry.startDate.day);
      final end =
          DateTime(entry.endDate.year, entry.endDate.month, entry.endDate.day);
      if (!d.isBefore(start) && !d.isAfter(end)) return true;
    }
    return false;
  }

  /// Check if a date falls in the predicted next period
  bool isPredictedPeriodDay(DateTime date) {
    final next = nextPeriodStart;
    if (next == null) return false;
    final d = DateTime(date.year, date.month, date.day);
    final start = DateTime(next.year, next.month, next.day);
    final end = start.add(Duration(days: averagePeriodLength - 1));
    return !d.isBefore(start) && !d.isAfter(end);
  }

  /// Check if a date is in the fertile window
  bool isFertileDay(DateTime date) {
    final start = fertileWindowStart;
    final end = fertileWindowEnd;
    if (start == null || end == null) return false;
    final d = DateTime(date.year, date.month, date.day);
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);
    return !d.isBefore(s) && !d.isAfter(e);
  }

  /// Check if a date is the ovulation day
  bool isOvulationDay(DateTime date) {
    final ov = ovulationDate;
    if (ov == null) return false;
    return date.year == ov.year &&
        date.month == ov.month &&
        date.day == ov.day;
  }
}
