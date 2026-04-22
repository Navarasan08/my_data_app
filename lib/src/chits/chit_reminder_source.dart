import 'package:my_data_app/src/chits/cubit/chit_cubit.dart';
import 'package:my_data_app/src/chits/model/chit_model.dart';
import 'package:my_data_app/src/notifications/reminder_source.dart';

/// Emits a reminder for every unpaid chit-fund payment due in the sweep
/// window. We use `members.first.payments` since the chit module always
/// stores the user's payments under the first member (both organizer and
/// participant flows).
class ChitReminderSource implements ReminderSource {
  final ChitCubit cubit;
  ChitReminderSource({required this.cubit});

  @override
  String get module => 'chits';

  @override
  Stream<dynamic> get changes => cubit.stream;

  @override
  List<ReminderItem> pendingIn(DateTime windowStart, DateTime windowEnd) {
    final out = <ReminderItem>[];
    for (final fund in cubit.state.chitFunds) {
      if (fund.status == ChitStatus.completed) continue;
      if (fund.members.isEmpty) continue;
      for (final p in fund.members.first.payments) {
        if (p.isPaid) continue;
        if (p.dueDate.isBefore(windowStart) ||
            p.dueDate.isAfter(windowEnd)) continue;
        out.add(ReminderItem(
          itemId: fund.id,
          dueDate: p.dueDate,
          title: '${fund.name} — month ${p.monthNumber}',
          body: '₹${p.amount.toStringAsFixed(0)} due',
          meta: {'monthNumber': p.monthNumber.toString()},
        ));
      }
    }
    return out;
  }
}
