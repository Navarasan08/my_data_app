import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_data_app/src/schedule/model/schedule_model.dart';
import 'package:my_data_app/src/schedule/repository/schedule_repository.dart';
import 'package:my_data_app/src/schedule/cubit/schedule_state.dart';

/// A single occurrence instance of a schedule entry (expanded from recurrence)
class ScheduleOccurrence {
  final ScheduleEntry entry;
  final DateTime date;

  const ScheduleOccurrence({required this.entry, required this.date});
}

class ScheduleCubit extends Cubit<ScheduleState> {
  final ScheduleRepository _repository;

  ScheduleCubit(this._repository)
      : super(ScheduleState(
          entries: _repository.getAll(),
          selectedDate: DateTime.now(),
          customCategories: _repository.getCustomCategories(),
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

  /// Toggle completion for a single occurrence date (per-task model).
  void toggleCompleteOn(String id, DateTime date) {
    final entry = state.entries.firstWhere((e) => e.id == id);
    final d = DateTime(date.year, date.month, date.day);
    final list = List<DateTime>.from(entry.completedDates);
    if (entry.isCompletedOn(d)) {
      list.removeWhere(
          (c) => DateTime(c.year, c.month, c.day) == d);
    } else {
      list.add(d);
    }
    updateEntry(entry.copyWith(completedDates: list));
  }

  /// Skip (i.e. "delete") a single occurrence — adds it to skippedDates so
  /// the recurrence engine no longer expands that date.
  void skipOccurrenceOn(String id, DateTime date) {
    final entry = state.entries.firstWhere((e) => e.id == id);
    final d = DateTime(date.year, date.month, date.day);
    if (entry.isSkippedOn(d)) return;
    final list = [...entry.skippedDates, d];
    // Also remove any completion record for that date
    final completed = entry.completedDates
        .where((c) => DateTime(c.year, c.month, c.day) != d)
        .toList();
    updateEntry(entry.copyWith(
      skippedDates: list,
      completedDates: completed,
    ));
  }

  /// Edit a single occurrence: skip the original at [date] and create a new
  /// one-time entry derived from [edited]. Returns the new entry id.
  String splitOccurrenceAt(String id, DateTime date, ScheduleEntry edited) {
    skipOccurrenceOn(id, date);
    final newId = '${id}_split_${DateTime.now().millisecondsSinceEpoch}';
    final newEntry = edited.copyWith(
      id: newId,
      repeatMode: RecurrenceMode.none,
      clearCustomDays: true,
      clearInterval: true,
      clearEndDate: true,
      completedDates: const [],
      skippedDates: const [],
    );
    addEntry(newEntry);
    return newId;
  }

  void changeDate(DateTime date) {
    emit(state.copyWith(selectedDate: date));
  }

  void setFilter(ScheduleFilter filter) {
    emit(state.copyWith(filter: filter));
  }

  // ── Category management ─────────────────────────────────────────────────

  List<ScheduleCategory> get allCategories =>
      [...ScheduleCategory.defaults, ...state.customCategories];

  void addCustomCategory(ScheduleCategory category) {
    _repository.addCustomCategory(category);
    emit(state.copyWith(customCategories: _repository.getCustomCategories()));
  }

  void updateCustomCategory(ScheduleCategory category) {
    _repository.updateCustomCategory(category);
    // Reflect the new name/icon/color on entries that reference it
    final updated = state.entries.map((e) {
      if (e.category.id == category.id) {
        return e.copyWith(category: category);
      }
      return e;
    }).toList();
    // Persist updated entries too so they round-trip correctly later
    for (final e in updated) {
      if (e.category.id == category.id) _repository.update(e);
    }
    emit(state.copyWith(
      customCategories: _repository.getCustomCategories(),
      entries: _repository.getAll(),
    ));
  }

  /// Delete a custom category. Any entries referring to it are migrated to
  /// [fallback] (defaults to "Other").
  void deleteCustomCategory(String categoryId,
      {ScheduleCategory? fallback}) {
    final fb = fallback ?? ScheduleCategory.other;

    // Migrate entries to fallback first
    for (final e in state.entries) {
      if (e.category.id == categoryId) {
        _repository.update(e.copyWith(category: fb));
      }
    }

    _repository.deleteCustomCategory(categoryId);
    emit(state.copyWith(
      customCategories: _repository.getCustomCategories(),
      entries: _repository.getAll(),
    ));
  }

  bool isCategoryInUse(String categoryId) {
    return state.entries.any((e) => e.category.id == categoryId);
  }

  // ── Occurrence expansion ────────────────────────────────────────────────

  List<ScheduleOccurrence> expandedOccurrences({
    DateTime? rangeStart,
    DateTime? rangeEnd,
  }) {
    final now = DateTime.now();
    final start = rangeStart ?? DateTime(now.year - 1, 1, 1);
    final end = rangeEnd ?? DateTime(now.year + 2, 12, 31);

    final all = <ScheduleOccurrence>[];
    for (final e in state.entries) {
      final dates = e.occurrencesInRange(start, end);
      for (final d in dates) {
        all.add(ScheduleOccurrence(entry: e, date: d));
      }
    }
    all.sort((a, b) => a.date.compareTo(b.date));
    return all;
  }

  List<ScheduleOccurrence> get filteredOccurrences {
    if (state.filter == ScheduleFilter.thisMonth) {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, 1);
      final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      return expandedOccurrences(rangeStart: start, rangeEnd: end);
    }
    return expandedOccurrences();
  }

  Map<String, List<ScheduleOccurrence>> get groupedFilteredByMonth {
    final occ = filteredOccurrences;
    final map = <String, List<ScheduleOccurrence>>{};
    for (final o in occ) {
      final key =
          '${o.date.year}-${o.date.month.toString().padLeft(2, '0')}';
      (map[key] ??= []).add(o);
    }
    return map;
  }

  int get pendingCount =>
      state.entries.where((e) => !e.isCompleted).length;

  int get filteredCount => filteredOccurrences.length;
}
