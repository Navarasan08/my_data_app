import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_data_app/src/reminder/model/bill_model.dart';
import 'package:my_data_app/src/reminder/repository/bill_repository.dart';
import 'package:my_data_app/src/reminder/cubit/bill_state.dart';

class BillCubit extends Cubit<BillState> {
  final BillRepository _repository;

  BillCubit(this._repository)
      : super(BillState(
          bills: _repository.getAll(),
          selectedMonth: DateTime(DateTime.now().year, DateTime.now().month),
        ));

  /// Re-emits state from the repository after a background server refresh.
  void reloadFromRepository() {
    emit(state.copyWith(bills: _repository.getAll()));
  }

  void addBill(Bill bill) {
    _repository.add(bill);
    emit(state.copyWith(bills: _repository.getAll()));
  }

  void updateBill(Bill bill) {
    // Preserve the per-month paid history, which the edit form doesn't manage.
    final existing = state.bills.firstWhere((b) => b.id == bill.id,
        orElse: () => bill);
    _repository.update(bill.copyWith(paidMonths: existing.paidMonths));
    emit(state.copyWith(bills: _repository.getAll()));
  }

  void deleteBill(String billId) {
    _repository.delete(billId);
    emit(state.copyWith(bills: _repository.getAll()));
  }

  /// Toggle whether [billId] is paid for [month] (normalised to year-month).
  void togglePaidForMonth(String billId, DateTime month) {
    final bill = state.bills.firstWhere((b) => b.id == billId);
    final ym = DateTime(month.year, month.month);
    final paid = List<DateTime>.from(bill.paidMonths);
    if (bill.isPaidForMonth(ym)) {
      paid.removeWhere((p) => p.year == ym.year && p.month == ym.month);
    } else {
      paid.add(ym);
    }
    _repository.update(bill.copyWith(paidMonths: paid));
    emit(state.copyWith(bills: _repository.getAll()));
  }

  void changeMonth(int delta) {
    final cur = state.selectedMonth;
    emit(state.copyWith(
      selectedMonth: DateTime(cur.year, cur.month + delta),
    ));
  }

  /// Bills active in the selected month, ordered: unpaid first (soonest /
  /// most overdue at the top), then paid underneath, both by due day.
  List<Bill> get billsForSelectedMonth {
    final month = state.selectedMonth;
    final bills =
        state.bills.where((b) => b.isActiveInMonth(month)).toList();
    bills.sort((a, b) {
      final ap = a.isPaidForMonth(month);
      final bp = b.isPaidForMonth(month);
      if (ap != bp) return ap ? 1 : -1;
      return a.dueDateInMonth(month).compareTo(b.dueDateInMonth(month));
    });
    return bills;
  }

  int get overdueCount => billsForSelectedMonth
      .where((b) => b.isOverdueInMonth(state.selectedMonth))
      .length;

  int get pendingCount => billsForSelectedMonth.where((b) {
        final m = state.selectedMonth;
        return !b.isPaidForMonth(m) && !b.isOverdueInMonth(m);
      }).length;

  int get paidCount => billsForSelectedMonth
      .where((b) => b.isPaidForMonth(state.selectedMonth))
      .length;

  /// Total amount still owed in the selected month (active, unpaid bills).
  /// Reduces as bills are marked paid.
  double get totalDue => billsForSelectedMonth
      .where((b) => !b.isPaidForMonth(state.selectedMonth))
      .fold(0.0, (sum, b) => sum + (b.amount ?? 0));

  /// Total amount of all active bills in the selected month, regardless of
  /// paid status. Stays fixed as bills are ticked.
  double get totalAmount => billsForSelectedMonth
      .fold(0.0, (sum, b) => sum + (b.amount ?? 0));
}
