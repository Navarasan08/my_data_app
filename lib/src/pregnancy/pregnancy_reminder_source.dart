import 'package:my_data_app/src/notifications/reminder_source.dart';
import 'package:my_data_app/src/pregnancy/cubit/pregnancy_cubit.dart';

/// Emits a reminder for each pending pregnancy check whose window closes
/// inside the sweep window, so nothing on the schedule slips past quietly.
class PregnancyReminderSource implements ReminderSource {
  final PregnancyCubit cubit;
  PregnancyReminderSource({required this.cubit});

  @override
  String get module => 'pregnancy';

  @override
  Stream<dynamic> get changes => cubit.stream;

  @override
  List<ReminderItem> pendingIn(DateTime windowStart, DateTime windowEnd) {
    if (!cubit.isTracking) return const [];
    final profile = cubit.profile;
    final out = <ReminderItem>[];
    for (final item in cubit.pendingChecks) {
      final due = item.dueDate(profile);
      if (due == null) continue;
      if (due.isBefore(windowStart) || due.isAfter(windowEnd)) continue;
      out.add(
        ReminderItem(
          itemId: item.id,
          dueDate: due,
          title: item.title,
          body: '${item.windowLabel} · ${item.category.label}',
          meta: {'category': item.category.label},
        ),
      );
    }
    return out;
  }
}
