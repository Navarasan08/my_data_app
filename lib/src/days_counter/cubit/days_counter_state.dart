import 'package:my_data_app/src/core/sync/sync_snapshot.dart';
import 'package:my_data_app/src/days_counter/model/days_counter_model.dart';

/// How far ahead (upcoming) or back (past) the lists reach.
enum DaysCounterWindow {
  all('All', null),
  week('7 days', 7),
  month('30 days', 30),
  quarter('90 days', 90),
  year('1 year', 365);

  final String label;

  /// Inclusive day limit; null means no limit.
  final int? days;
  const DaysCounterWindow(this.label, this.days);
}

class DaysCounterState {
  final List<DaysCounterEvent> events;
  final List<DaysCounterEventType> eventTypes;

  /// Where the lists came from: `loading` before the first snapshot,
  /// `cached` until the server confirms, `live` after.
  final SyncStatus syncStatus;

  // ── Filters (UI state, not persisted) ────────────────────────────────────

  /// Event type ids to show. Empty means every type.
  final Set<String> typeFilter;
  final DaysCounterWindow window;

  /// Restrict to yearly or one-time events; null shows both.
  final DaysCounterRecurrence? recurrenceFilter;

  /// Case-insensitive match against title and notes.
  final String search;

  const DaysCounterState({
    required this.events,
    required this.eventTypes,
    this.syncStatus = SyncStatus.loading,
    this.typeFilter = const {},
    this.window = DaysCounterWindow.all,
    this.recurrenceFilter,
    this.search = '',
  });

  bool get isLive => syncStatus.isLive;

  bool get hasActiveFilters =>
      typeFilter.isNotEmpty ||
      window != DaysCounterWindow.all ||
      recurrenceFilter != null ||
      search.trim().isNotEmpty;

  int get activeFilterCount =>
      (typeFilter.isNotEmpty ? 1 : 0) +
      (window != DaysCounterWindow.all ? 1 : 0) +
      (recurrenceFilter != null ? 1 : 0) +
      (search.trim().isNotEmpty ? 1 : 0);

  DaysCounterState copyWith({
    List<DaysCounterEvent>? events,
    List<DaysCounterEventType>? eventTypes,
    SyncStatus? syncStatus,
    Set<String>? typeFilter,
    DaysCounterWindow? window,
    DaysCounterRecurrence? recurrenceFilter,
    bool clearRecurrenceFilter = false,
    String? search,
  }) => DaysCounterState(
    events: events ?? this.events,
    eventTypes: eventTypes ?? this.eventTypes,
    syncStatus: syncStatus ?? this.syncStatus,
    typeFilter: typeFilter ?? this.typeFilter,
    window: window ?? this.window,
    recurrenceFilter: clearRecurrenceFilter
        ? null
        : (recurrenceFilter ?? this.recurrenceFilter),
    search: search ?? this.search,
  );
}
