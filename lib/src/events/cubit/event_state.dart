import 'package:my_data_app/src/core/sync/sync_snapshot.dart';
import 'package:my_data_app/src/events/model/event_model.dart';

class EventState {
  final List<EventFund> events;
  final Map<String, List<EventExpense>> expensesByEvent;

  /// Where the data came from: `loading` before every listener (events and
  /// each event's expenses) has reported, `cached` until the server
  /// confirms, `live` after.
  final SyncStatus syncStatus;

  const EventState({
    required this.events,
    required this.expensesByEvent,
    this.syncStatus = SyncStatus.loading,
  });

  bool get isLive => syncStatus.isLive;

  EventState copyWith({
    List<EventFund>? events,
    Map<String, List<EventExpense>>? expensesByEvent,
    SyncStatus? syncStatus,
  }) {
    return EventState(
      events: events ?? this.events,
      expensesByEvent: expensesByEvent ?? this.expensesByEvent,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
