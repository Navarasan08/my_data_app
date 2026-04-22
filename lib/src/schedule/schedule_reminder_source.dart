import 'package:my_data_app/src/notifications/reminder_source.dart';
import 'package:my_data_app/src/schedule/cubit/schedule_cubit.dart';

/// Adapter that exposes the user's schedule entries to the generic
/// [ReminderSweeper]. All reminder logic (severity, dedupe, auto-dismiss) is
/// owned by the sweeper — this source just answers "what's due in this
/// window and not yet completed?".
class ScheduleReminderSource implements ReminderSource {
  final ScheduleCubit scheduleCubit;

  ScheduleReminderSource({required this.scheduleCubit});

  @override
  String get module => 'schedule';

  @override
  Stream<dynamic> get changes => scheduleCubit.stream;

  @override
  List<ReminderItem> pendingIn(DateTime windowStart, DateTime windowEnd) {
    final out = <ReminderItem>[];
    for (final entry in scheduleCubit.state.entries) {
      for (final date in entry.occurrencesInRange(windowStart, windowEnd)) {
        if (entry.isCompletedOn(date)) continue;
        out.add(ReminderItem(
          itemId: entry.id,
          dueDate: date,
          title: entry.title,
          meta: {'category': entry.category.label},
        ));
      }
    }
    return out;
  }
}
