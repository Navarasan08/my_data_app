import 'package:my_data_app/src/days_counter/model/days_counter_model.dart';

class DaysCounterState {
  final List<DaysCounterEvent> events;
  final List<DaysCounterEventType> eventTypes;

  const DaysCounterState({
    required this.events,
    required this.eventTypes,
  });

  DaysCounterState copyWith({
    List<DaysCounterEvent>? events,
    List<DaysCounterEventType>? eventTypes,
  }) =>
      DaysCounterState(
        events: events ?? this.events,
        eventTypes: eventTypes ?? this.eventTypes,
      );
}
