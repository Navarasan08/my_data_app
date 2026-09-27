import 'package:my_data_app/src/core/sync/sync_snapshot.dart';
import 'package:my_data_app/src/days_counter/model/days_counter_model.dart';

class DaysCounterState {
  final List<DaysCounterEvent> events;
  final List<DaysCounterEventType> eventTypes;

  /// Where the lists came from: `loading` before the first snapshot,
  /// `cached` until the server confirms, `live` after.
  final SyncStatus syncStatus;

  const DaysCounterState({
    required this.events,
    required this.eventTypes,
    this.syncStatus = SyncStatus.loading,
  });

  bool get isLive => syncStatus.isLive;

  DaysCounterState copyWith({
    List<DaysCounterEvent>? events,
    List<DaysCounterEventType>? eventTypes,
    SyncStatus? syncStatus,
  }) => DaysCounterState(
    events: events ?? this.events,
    eventTypes: eventTypes ?? this.eventTypes,
    syncStatus: syncStatus ?? this.syncStatus,
  );
}
