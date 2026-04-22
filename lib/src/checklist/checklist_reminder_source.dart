import 'package:my_data_app/src/checklist/cubit/checklist_cubit.dart';
import 'package:my_data_app/src/notifications/reminder_source.dart';

/// Emits a reminder per checklist whose target date is in the sweep window
/// and is not yet fully completed.
class ChecklistReminderSource implements ReminderSource {
  final ChecklistCubit cubit;
  ChecklistReminderSource({required this.cubit});

  @override
  String get module => 'checklists';

  @override
  Stream<dynamic> get changes => cubit.stream;

  @override
  List<ReminderItem> pendingIn(DateTime windowStart, DateTime windowEnd) {
    final out = <ReminderItem>[];
    for (final group in cubit.state.checklists) {
      if (group.isAllCompleted) continue;
      final due = group.targetDate;
      if (due.isBefore(windowStart) || due.isAfter(windowEnd)) continue;
      out.add(ReminderItem(
        itemId: group.id,
        dueDate: due,
        title: group.name,
        body:
            '${group.completedItems}/${group.totalItems} items done',
      ));
    }
    return out;
  }
}
