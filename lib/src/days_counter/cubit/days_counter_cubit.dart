import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_data_app/src/days_counter/cubit/days_counter_state.dart';
import 'package:my_data_app/src/days_counter/model/days_counter_model.dart';
import 'package:my_data_app/src/days_counter/repository/days_counter_repository.dart';

class DaysCounterCubit extends Cubit<DaysCounterState> {
  final DaysCounterRepository _repository;
  StreamSubscription<void>? _sub;

  DaysCounterCubit(this._repository)
    : super(
        DaysCounterState(
          events: _repository.getEvents(),
          eventTypes: _repository.getEventTypes(),
          syncStatus: _repository.syncStatus,
        ),
      ) {
    _sub = _repository.changes.listen((_) => _sync());
  }

  /// Pulls the repository's current lists and sync status into state. Runs
  /// on every realtime change and after each local write.
  void _sync() {
    emit(
      state.copyWith(
        events: _repository.getEvents(),
        eventTypes: _repository.getEventTypes(),
        syncStatus: _repository.syncStatus,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }

  // ── Events ───────────────────────────────────────────────────────────────

  void addEvent(DaysCounterEvent e) {
    _repository.addEvent(e);
    _sync();
  }

  void updateEvent(DaysCounterEvent e) {
    _repository.updateEvent(e.copyWith(updatedAt: DateTime.now()));
    _sync();
  }

  void deleteEvent(String id) {
    _repository.deleteEvent(id);
    _sync();
  }

  // ── Event types ──────────────────────────────────────────────────────────

  void addEventType(DaysCounterEventType t) {
    _repository.addEventType(t);
    _sync();
  }

  /// Updating a type also rewrites the embedded snapshot on every event
  /// currently using that id, so existing events reflect the new
  /// name / icon / color rather than a stale copy.
  void updateEventType(DaysCounterEventType t) {
    _repository.updateEventType(t);
    for (final e in state.events) {
      if (e.eventType.id == t.id) {
        _repository.updateEvent(
          e.copyWith(eventType: t, updatedAt: DateTime.now()),
        );
      }
    }
    _sync();
  }

  void deleteEventType(String id) {
    _repository.deleteEventType(id);
    _sync();
  }

  bool isEventTypeInUse(String id) =>
      state.events.any((e) => e.eventType.id == id);

  // ── Filters ──────────────────────────────────────────────────────────────

  void toggleTypeFilter(String typeId) {
    final next = Set<String>.from(state.typeFilter);
    if (!next.remove(typeId)) next.add(typeId);
    emit(state.copyWith(typeFilter: next));
  }

  void setWindow(DaysCounterWindow window) =>
      emit(state.copyWith(window: window));

  /// Pass null to show both yearly and one-time events.
  void setRecurrenceFilter(DaysCounterRecurrence? recurrence) => emit(
    state.copyWith(
      recurrenceFilter: recurrence,
      clearRecurrenceFilter: recurrence == null,
    ),
  );

  void setSearch(String query) => emit(state.copyWith(search: query));

  void clearFilters() => emit(
    state.copyWith(
      typeFilter: const {},
      window: DaysCounterWindow.all,
      clearRecurrenceFilter: true,
      search: '',
    ),
  );

  /// Type, recurrence and search filters; the day window is applied by
  /// the callers because it means "ahead" for upcoming and "back" for past.
  bool _passesFilters(DaysCounterEvent e) {
    final s = state;
    if (s.typeFilter.isNotEmpty && !s.typeFilter.contains(e.eventType.id)) {
      return false;
    }
    if (s.recurrenceFilter != null && e.recurrence != s.recurrenceFilter) {
      return false;
    }
    final q = s.search.trim().toLowerCase();
    if (q.isNotEmpty &&
        !e.title.toLowerCase().contains(q) &&
        !(e.notes?.toLowerCase().contains(q) ?? false)) {
      return false;
    }
    return true;
  }

  // ── Derived views ────────────────────────────────────────────────────────

  List<DaysCounterEvent> get _upcomingAll =>
      state.events.where((e) => e.nextOccurrence != null).toList()
        ..sort((a, b) {
          final ad = a.daysUntilNext ?? 1 << 30;
          final bd = b.daysUntilNext ?? 1 << 30;
          return ad.compareTo(bd);
        });

  /// Events with a future-or-today occurrence that pass the active filters,
  /// sorted by days-until-next ascending. Yearly events always belong here
  /// (they always have a future anniversary); one-time events only while
  /// their date is still ahead.
  List<DaysCounterEvent> get upcoming {
    final limit = state.window.days;
    return _upcomingAll.where((e) {
      if (!_passesFilters(e)) return false;
      return limit == null || (e.daysUntilNext ?? 0) <= limit;
    }).toList();
  }

  /// One-time events whose date is already in the past and that pass the
  /// active filters, sorted by most recent first.
  List<DaysCounterEvent> get past {
    final limit = state.window.days;
    final list =
        state.events.where((e) {
          if (e.isYearly || e.nextOccurrence != null) return false;
          final since = e.daysSincePast;
          if (since == null) return false;
          if (!_passesFilters(e)) return false;
          return limit == null || since <= limit;
        }).toList()..sort(
          (a, b) => (a.daysSincePast ?? 0).compareTo(b.daysSincePast ?? 0),
        );
    return list;
  }

  /// Number of events hidden by the current filters, for the "n hidden"
  /// hint in the filter bar.
  int get hiddenByFilters {
    final total = _upcomingAll.length + _pastAllCount;
    return total - upcoming.length - past.length;
  }

  int get _pastAllCount =>
      state.events.where((e) => !e.isYearly && e.nextOccurrence == null).length;

  /// Quick summary number for the dashboard badge, unaffected by filters.
  int get upcomingCount => _upcomingAll.length;
}
