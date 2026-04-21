import 'package:my_data_app/src/events/model/event_model.dart';

class EventState {
  final List<EventFund> events;
  final Map<String, List<EventExpense>> expensesByEvent;

  const EventState({
    required this.events,
    required this.expensesByEvent,
  });

  EventState copyWith({
    List<EventFund>? events,
    Map<String, List<EventExpense>>? expensesByEvent,
  }) {
    return EventState(
      events: events ?? this.events,
      expensesByEvent: expensesByEvent ?? this.expensesByEvent,
    );
  }
}
