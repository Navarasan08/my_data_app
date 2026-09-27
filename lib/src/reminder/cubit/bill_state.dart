import 'package:my_data_app/src/core/sync/sync_snapshot.dart';
import 'package:my_data_app/src/reminder/model/bill_model.dart';

class BillState {
  final List<Bill> bills;

  /// The month currently being viewed (first-of-month). Drives the per-month
  /// paid status and days-left shown for each bill.
  final DateTime selectedMonth;

  /// Where [bills] came from: `loading` before the first snapshot, `cached`
  /// until the server confirms, `live` after.
  final SyncStatus syncStatus;

  const BillState({
    required this.bills,
    required this.selectedMonth,
    this.syncStatus = SyncStatus.loading,
  });

  bool get isLive => syncStatus.isLive;

  BillState copyWith({
    List<Bill>? bills,
    DateTime? selectedMonth,
    SyncStatus? syncStatus,
  }) {
    return BillState(
      bills: bills ?? this.bills,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
