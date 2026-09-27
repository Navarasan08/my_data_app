import 'package:my_data_app/src/core/sync/sync_snapshot.dart';
import 'package:my_data_app/src/loans/model/loan_model.dart';

class LoanState {
  final List<Loan> loans;

  /// Where [loans] came from: `loading` before the first snapshot, `cached`
  /// until the server confirms, `live` after.
  final SyncStatus syncStatus;

  const LoanState({required this.loans, this.syncStatus = SyncStatus.loading});

  bool get isLive => syncStatus.isLive;

  LoanState copyWith({List<Loan>? loans, SyncStatus? syncStatus}) => LoanState(
    loans: loans ?? this.loans,
    syncStatus: syncStatus ?? this.syncStatus,
  );
}
