import 'package:my_data_app/src/chits/model/chit_model.dart';
import 'package:my_data_app/src/home/home_record_model.dart';
import 'package:my_data_app/src/interest/model/interest_model.dart';
import 'package:my_data_app/src/loans/model/loan_model.dart';
import 'package:my_data_app/src/money_owe/model/money_owe_model.dart';
import 'package:my_data_app/src/reminder/model/bill_model.dart';
import 'package:my_data_app/src/vehicle/model/vehicle_model.dart';

/// One line of the monthly tally: salary, bills, loan EMIs, …
class MonthlyStatItem {
  /// Stable identifier ('salary', 'bills', …) the page maps to an icon/color.
  final String id;
  final String label;
  final double amount;

  /// True for money coming in, false for money going out.
  final bool isIncome;

  /// Short context line, e.g. '2 of 4 paid' or '3 fuel fills'.
  final String? detail;

  /// Dashboard feature id to open when the row is tapped.
  final String featureId;

  const MonthlyStatItem({
    required this.id,
    required this.label,
    required this.amount,
    required this.isIncome,
    this.detail,
    required this.featureId,
  });
}

/// The tallied money picture of one month, computed from every finance
/// module's data. Pure: no cubit or Firestore dependencies, so it is unit
/// testable and always consistent with whatever the listeners last emitted.
class MonthlySummary {
  /// First day of the calendar month being summarised.
  final DateTime month;
  final List<MonthlyStatItem> items;

  const MonthlySummary({required this.month, required this.items});

  List<MonthlyStatItem> get incomeItems =>
      items.where((i) => i.isIncome).toList();

  List<MonthlyStatItem> get outgoingItems =>
      items.where((i) => !i.isIncome).toList();

  double get totalIncome =>
      incomeItems.fold(0.0, (sum, i) => sum + i.amount);

  double get totalOutgoing =>
      outgoingItems.fold(0.0, (sum, i) => sum + i.amount);

  double get balance => totalIncome - totalOutgoing;

  /// True when no module has any money movement in this month.
  bool get isEmpty => items.every((i) => i.amount == 0);

  /// Tallies [month] across every module.
  ///
  /// [homeWindow] is the expense tracker's cycle window for the month
  /// (inclusive start, exclusive end), so income/expense figures here match
  /// the tracker even with a custom monthly start day. Everything else uses
  /// the plain calendar month.
  static MonthlySummary compute({
    required DateTime month,
    required ({DateTime start, DateTime end}) homeWindow,
    required List<HomeRecord> records,
    required List<Bill> bills,
    required List<Loan> loans,
    required List<DebtEntry> debts,
    required List<Vehicle> vehicles,
    required List<ChitFund> chitFunds,
    required List<InterestRecord> interestRecords,
  }) {
    final m = DateTime(month.year, month.month);
    final monthEnd = DateTime(m.year, m.month + 1);

    bool inCalendarMonth(DateTime d) => d.year == m.year && d.month == m.month;
    bool inHomeWindow(DateTime date) {
      final d = DateTime(date.year, date.month, date.day);
      return !d.isBefore(homeWindow.start) && d.isBefore(homeWindow.end);
    }

    // ── Income: home records flagged isIncome, salary split out ──────────
    final incomeRecords =
        records.where((r) => r.isIncome && inHomeWindow(r.date)).toList();
    final salaryRecords =
        incomeRecords.where((r) => r.category.id == 'salary').toList();
    final otherIncomeRecords =
        incomeRecords.where((r) => r.category.id != 'salary').toList();

    final salary =
        salaryRecords.fold(0.0, (sum, r) => sum + r.amount);
    final otherIncome =
        otherIncomeRecords.fold(0.0, (sum, r) => sum + r.amount);

    // ── Bills active this month ──────────────────────────────────────────
    final activeBills = bills.where((b) => b.isActiveInMonth(m)).toList();
    final billsTotal =
        activeBills.fold(0.0, (sum, b) => sum + (b.amount ?? 0));
    final billsPaid = activeBills.where((b) => b.isPaidForMonth(m)).length;

    // ── Loan EMIs due this month (borrowed, open, within tenure) ─────────
    // EMI n falls in startDate.month + n, n = 1..tenureMonths.
    double emiTotal = 0;
    int emiCount = 0;
    for (final l in loans) {
      if (l.isClosed || l.direction != LoanDirection.borrowed) continue;
      final n = (m.year - l.startDate.year) * 12 + m.month - l.startDate.month;
      if (n >= 1 && n <= l.tenureMonths) {
        emiTotal += l.emiAmount;
        emiCount++;
      }
    }

    // ── Chit contributions due this month ────────────────────────────────
    // Participant: my payments (members.first) due in the month. Owner: the
    // fund is mine, so my own monthly contribution while the fund runs.
    double chitTotal = 0;
    int chitCount = 0;
    for (final c in chitFunds) {
      if (c.role == ChitRole.participant) {
        if (c.members.isEmpty) continue;
        final due = c.members.first.payments
            .where((p) => inCalendarMonth(p.dueDate))
            .fold(0.0, (sum, p) => sum + p.actualAmount);
        if (due > 0) {
          chitTotal += due;
          chitCount++;
        }
      } else if (c.status == ChitStatus.active) {
        final n = (m.year - c.startDate.year) * 12 +
            m.month -
            c.startDate.month +
            1;
        if (n >= 1 && n <= c.durationMonths) {
          chitTotal += c.monthlyContribution;
          chitCount++;
        }
      }
    }

    // ── Interest payable this month on borrowed principals ───────────────
    final openBorrowedInterest = interestRecords
        .where((r) => r.direction == InterestDirection.borrowed && !r.isClosed)
        .toList();
    final interestTotal = openBorrowedInterest.fold(
      0.0,
      (sum, r) => sum + r.monthlyInterestOnPrincipal,
    );

    // ── Household expenses (expense tracker) ─────────────────────────────
    final expenseRecords =
        records.where((r) => !r.isIncome && inHomeWindow(r.date)).toList();
    final expensesTotal =
        expenseRecords.fold(0.0, (sum, r) => sum + r.amount);

    // ── Debts to pay: borrowed, unsettled, due by end of this month ──────
    final dueDebts = debts
        .where((d) =>
            d.direction == DebtDirection.borrowed &&
            !d.isFullySettled &&
            d.dueDate != null &&
            d.dueDate!.isBefore(monthEnd))
        .toList();
    final debtsTotal =
        dueDebts.fold(0.0, (sum, d) => sum + d.pendingAmount);

    // ── Vehicle spend this month, with the petrol share ──────────────────
    double vehicleTotal = 0;
    int fuelFills = 0;
    for (final v in vehicles) {
      for (final r in v.records) {
        if (r.amount == null || !inCalendarMonth(r.date)) continue;
        vehicleTotal += r.amount!;
        if (r.type == RecordType.fuel) fuelFills++;
      }
    }

    String plural(int n, String unit) => '$n $unit${n == 1 ? '' : 's'}';

    return MonthlySummary(
      month: m,
      items: [
        MonthlyStatItem(
          id: 'salary',
          label: 'Salary',
          amount: salary,
          isIncome: true,
          detail: salaryRecords.isEmpty
              ? null
              : plural(salaryRecords.length, 'credit'),
          featureId: 'home',
        ),
        MonthlyStatItem(
          id: 'other_income',
          label: 'Other Income',
          amount: otherIncome,
          isIncome: true,
          detail: otherIncomeRecords.isEmpty
              ? null
              : plural(otherIncomeRecords.length, 'credit'),
          featureId: 'home',
        ),
        MonthlyStatItem(
          id: 'expenses',
          label: 'Expenses',
          amount: expensesTotal,
          isIncome: false,
          detail: expenseRecords.isEmpty
              ? null
              : plural(expenseRecords.length, 'record'),
          featureId: 'home',
        ),
        MonthlyStatItem(
          id: 'bills',
          label: 'Bills',
          amount: billsTotal,
          isIncome: false,
          detail: activeBills.isEmpty
              ? null
              : '$billsPaid of ${activeBills.length} paid',
          featureId: 'bills',
        ),
        MonthlyStatItem(
          id: 'loans',
          label: 'Loan EMIs',
          amount: emiTotal,
          isIncome: false,
          detail: emiCount == 0 ? null : plural(emiCount, 'EMI'),
          featureId: 'loans',
        ),
        MonthlyStatItem(
          id: 'chits',
          label: 'Chit Contributions',
          amount: chitTotal,
          isIncome: false,
          detail: chitCount == 0 ? null : plural(chitCount, 'chit'),
          featureId: 'chits',
        ),
        MonthlyStatItem(
          id: 'interest',
          label: 'Interest Payable',
          amount: interestTotal,
          isIncome: false,
          detail: openBorrowedInterest.isEmpty
              ? null
              : plural(openBorrowedInterest.length, 'lender'),
          featureId: 'interest',
        ),
        MonthlyStatItem(
          id: 'debts',
          label: 'Debts to Pay',
          amount: debtsTotal,
          isIncome: false,
          detail: dueDebts.isEmpty
              ? null
              : dueDebts.length == 1
                  ? '1 person'
                  : '${dueDebts.length} people',
          featureId: 'money_owe',
        ),
        MonthlyStatItem(
          id: 'vehicle',
          label: 'Petrol & Vehicle',
          amount: vehicleTotal,
          isIncome: false,
          detail: fuelFills == 0 ? null : plural(fuelFills, 'fuel fill'),
          featureId: 'vehicles',
        ),
      ],
    );
  }
}
