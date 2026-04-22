import 'package:my_data_app/src/loans/cubit/loan_cubit.dart';
import 'package:my_data_app/src/notifications/reminder_source.dart';

/// Emits a reminder for the next pending EMI of every active borrowed loan
/// when its due date falls in the sweep window. The notification disappears
/// automatically once the EMI is recorded (because [Loan.nextEmiDate]
/// advances and the previous due date no longer falls in window).
class LoanReminderSource implements ReminderSource {
  final LoanCubit cubit;
  LoanReminderSource({required this.cubit});

  @override
  String get module => 'loans';

  @override
  Stream<dynamic> get changes => cubit.stream;

  @override
  List<ReminderItem> pendingIn(DateTime windowStart, DateTime windowEnd) {
    final out = <ReminderItem>[];
    for (final loan in cubit.state.loans) {
      if (loan.isClosed) continue;
      if (loan.remainingEmis <= 0) continue;
      final due = loan.nextEmiDate;
      if (due.isBefore(windowStart) || due.isAfter(windowEnd)) continue;
      out.add(ReminderItem(
        itemId: loan.id,
        dueDate: due,
        title: '${loan.name} EMI',
        body: 'EMI ${loan.paidEmiCount + 1} of ${loan.tenureMonths}'
            ' — ₹${loan.emiAmount.toStringAsFixed(0)}',
        meta: {'type': loan.type.name},
      ));
    }
    return out;
  }
}
