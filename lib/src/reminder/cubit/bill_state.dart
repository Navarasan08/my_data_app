import 'package:my_data_app/src/reminder/model/bill_model.dart';

class BillState {
  final List<Bill> bills;

  /// The month currently being viewed (first-of-month). Drives the per-month
  /// paid status and days-left shown for each bill.
  final DateTime selectedMonth;

  const BillState({
    required this.bills,
    required this.selectedMonth,
  });

  BillState copyWith({
    List<Bill>? bills,
    DateTime? selectedMonth,
  }) {
    return BillState(
      bills: bills ?? this.bills,
      selectedMonth: selectedMonth ?? this.selectedMonth,
    );
  }
}
