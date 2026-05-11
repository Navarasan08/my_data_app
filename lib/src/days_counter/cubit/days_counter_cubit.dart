import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_data_app/src/days_counter/cubit/days_counter_state.dart';
import 'package:my_data_app/src/days_counter/model/days_counter_model.dart';
import 'package:my_data_app/src/days_counter/repository/days_counter_repository.dart';

class DaysCounterCubit extends Cubit<DaysCounterState> {
  final DaysCounterRepository _repository;

  DaysCounterCubit(this._repository)
      : super(DaysCounterState(
          events: _repository.getEvents(),
          eventTypes: _repository.getEventTypes(),
        ));

  // ── Events ───────────────────────────────────────────────────────────────

  void addEvent(DaysCounterEvent e) {
    _repository.addEvent(e);
    emit(state.copyWith(events: _repository.getEvents()));
  }

  void updateEvent(DaysCounterEvent e) {
    _repository.updateEvent(e.copyWith(updatedAt: DateTime.now()));
    emit(state.copyWith(events: _repository.getEvents()));
  }

  void deleteEvent(String id) {
    _repository.deleteEvent(id);
    emit(state.copyWith(events: _repository.getEvents()));
  }

  // ── Event types ──────────────────────────────────────────────────────────

  void addEventType(DaysCounterEventType t) {
    _repository.addEventType(t);
    emit(state.copyWith(eventTypes: _repository.getEventTypes()));
  }

  /// Updating a type also rewrites the embedded snapshot on every event
  /// currently using that id, so existing events reflect the new
  /// name / icon / color rather than a stale copy.
  void updateEventType(DaysCounterEventType t) {
    _repository.updateEventType(t);
    final updated = state.events.map((e) {
      if (e.eventType.id == t.id) {
        final next = e.copyWith(eventType: t, updatedAt: DateTime.now());
        _repository.updateEvent(next);
        return next;
      }
      return e;
    }).toList();
    emit(state.copyWith(
      eventTypes: _repository.getEventTypes(),
      events: updated,
    ));
  }

  void deleteEventType(String id) {
    _repository.deleteEventType(id);
    emit(state.copyWith(eventTypes: _repository.getEventTypes()));
  }

  bool isEventTypeInUse(String id) =>
      state.events.any((e) => e.eventType.id == id);

  // ── Derived views ────────────────────────────────────────────────────────

  /// Events with a future-or-today occurrence, sorted by days-until-next
  /// ascending. Yearly events always belong here (they always have a future
  /// anniversary); one-time events only while their date is still ahead.
  List<DaysCounterEvent> get upcoming {
    final list = state.events
        .where((e) => e.nextOccurrence != null)
        .toList()
      ..sort((a, b) {
        final ad = a.daysUntilNext ?? 1 << 30;
        final bd = b.daysUntilNext ?? 1 << 30;
        return ad.compareTo(bd);
      });
    return list;
  }

  /// One-time events whose date is already in the past, sorted by most
  /// recent first.
  List<DaysCounterEvent> get past {
    final list = state.events
        .where((e) =>
            !e.isYearly && e.nextOccurrence == null && e.daysSincePast != null)
        .toList()
      ..sort((a, b) => (a.daysSincePast ?? 0).compareTo(b.daysSincePast ?? 0));
    return list;
  }

  /// Quick summary number for the dashboard badge.
  int get upcomingCount => upcoming.length;
}
