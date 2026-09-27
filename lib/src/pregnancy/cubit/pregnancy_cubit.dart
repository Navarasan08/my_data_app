import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_data_app/src/pregnancy/cubit/pregnancy_state.dart';
import 'package:my_data_app/src/pregnancy/model/pregnancy_model.dart';
import 'package:my_data_app/src/pregnancy/repository/pregnancy_repository.dart';

class PregnancyCubit extends Cubit<PregnancyState> {
  final PregnancyRepository _repository;
  StreamSubscription<void>? _sub;

  /// Injectable clock so tests can pin "today".
  final DateTime Function() _now;

  PregnancyCubit(this._repository, {DateTime Function()? now})
    : _now = now ?? DateTime.now,
      super(
        PregnancyState(
          profile: _repository.getProfile(),
          checks: _repository.getChecks(),
          logs: _repository.getLogs(),
          syncStatus: _repository.syncStatus,
        ),
      ) {
    _sub = _repository.changes.listen((_) => _sync());
  }

  void _sync() {
    emit(
      state.copyWith(
        profile: _repository.getProfile(),
        checks: _repository.getChecks(),
        logs: _repository.getLogs(),
        syncStatus: _repository.syncStatus,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }

  // ── Derived ──────────────────────────────────────────────────────────────

  DateTime get today {
    final n = _now();
    return DateTime(n.year, n.month, n.day);
  }

  PregnancyProfile get profile => state.profile;
  bool get isTracking => profile.isSet;

  int get currentWeek => profile.weekOn(today);
  int get currentDayOfWeek => profile.dayOfWeekOn(today);
  int get trimester => PregnancyProfile.trimesterOf(currentWeek);
  DateTime? get dueDate => profile.dueDate;

  /// Days until the due date; negative once it has passed.
  int get daysToGo {
    final due = dueDate;
    return due == null ? 0 : due.difference(today).inDays;
  }

  /// 0..1 fraction of the 40 weeks that has elapsed.
  double get progress {
    final start = profile.startDate;
    if (start == null) return 0;
    final days = today.difference(start).inDays;
    return (days / kPregnancyDays).clamp(0.0, 1.0);
  }

  List<PregnancyCheckItem> get sortedChecks =>
      List<PregnancyCheckItem>.from(state.checks)..sort(_byWindow);

  static int _byWindow(PregnancyCheckItem a, PregnancyCheckItem b) {
    if (a.toWeek != b.toWeek) return a.toWeek.compareTo(b.toWeek);
    if (a.fromWeek != b.fromWeek) return a.fromWeek.compareTo(b.fromWeek);
    return a.order.compareTo(b.order);
  }

  List<PregnancyCheckItem> checksForTrimester(int t) =>
      sortedChecks.where((c) => c.trimester == t).toList();

  List<PregnancyCheckItem> get pendingChecks =>
      sortedChecks.where((c) => !c.done).toList();

  List<PregnancyCheckItem> get overdueChecks =>
      pendingChecks.where((c) => c.isOverdueAt(currentWeek)).toList();

  /// Pending items whose window includes the current week.
  List<PregnancyCheckItem> get currentChecks =>
      pendingChecks.where((c) => c.isCurrentAt(currentWeek)).toList();

  /// The next few pending items in window order, current ones first.
  List<PregnancyCheckItem> upcomingChecks({int limit = 3}) {
    final list = [
      ...currentChecks,
      ...pendingChecks.where((c) => c.fromWeek > currentWeek),
    ];
    return list.take(limit).toList();
  }

  int get completedCount => state.checks.where((c) => c.done).length;

  List<PregnancyLog> get sortedLogs =>
      List<PregnancyLog>.from(state.logs)
        ..sort((a, b) => b.date.compareTo(a.date));

  PregnancyLog? get latestLog => sortedLogs.isEmpty ? null : sortedLogs.first;

  /// Weight change from the first logged weight to the latest, in kg.
  double? get weightChange {
    final weighed = sortedLogs.where((l) => l.weightKg != null).toList();
    if (weighed.length < 2) return null;
    return weighed.first.weightKg! - weighed.last.weightKg!;
  }

  // ── Profile ──────────────────────────────────────────────────────────────

  /// Begins tracking. Give either the LMP date or the doctor's due date.
  /// The standard checklist is seeded the first time.
  void startPregnancy({DateTime? lmpDate, DateTime? dueDate}) {
    assert(lmpDate != null || dueDate != null);
    final next = state.profile.copyWith(
      lmpDate: lmpDate,
      clearLmp: lmpDate == null,
      dueDateOverride: dueDate,
      clearDueDateOverride: dueDate == null,
      active: true,
      checksSeeded: true,
    );
    _repository.saveProfile(next);
    if (!state.profile.checksSeeded || state.checks.isEmpty) {
      _repository.seedDefaultChecks();
    }
    _sync();
  }

  void updateProfile(PregnancyProfile profile) {
    _repository.saveProfile(profile);
    _sync();
  }

  /// Stops tracking but keeps the history.
  void endPregnancy() {
    _repository.saveProfile(state.profile.copyWith(active: false));
    _sync();
  }

  /// Wipes checks, logs and the profile.
  void resetAll() {
    _repository.clearAll();
    _repository.saveProfile(PregnancyProfile.defaults);
    _sync();
  }

  // ── Checks ───────────────────────────────────────────────────────────────

  void toggleCheck(String id) {
    final item = state.checks.firstWhere((c) => c.id == id);
    _repository.updateCheck(
      item.done
          ? item.copyWith(done: false, clearDoneDate: true)
          : item.copyWith(done: true, doneDate: today),
    );
    _sync();
  }

  void addCheck(PregnancyCheckItem item) {
    _repository.addCheck(item.copyWith(isCustom: true));
    _sync();
  }

  void updateCheck(PregnancyCheckItem item) {
    _repository.updateCheck(item);
    _sync();
  }

  void deleteCheck(String id) {
    _repository.deleteCheck(id);
    _sync();
  }

  // ── Journal ──────────────────────────────────────────────────────────────

  void addLog(PregnancyLog log) {
    _repository.addLog(log);
    _sync();
  }

  void updateLog(PregnancyLog log) {
    _repository.updateLog(log);
    _sync();
  }

  void deleteLog(String id) {
    _repository.deleteLog(id);
    _sync();
  }
}
