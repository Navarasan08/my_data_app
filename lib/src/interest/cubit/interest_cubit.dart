import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_data_app/src/interest/cubit/interest_state.dart';
import 'package:my_data_app/src/interest/model/interest_model.dart';
import 'package:my_data_app/src/interest/repository/interest_repository.dart';

class InterestCubit extends Cubit<InterestState> {
  final InterestRepository _repository;

  InterestCubit(this._repository)
      : super(InterestState(records: _repository.getAll()));

  // ── Records ─────────────────────────────────────────────────────────────

  void addRecord(InterestRecord r) {
    _repository.add(r);
    _emit();
  }

  void updateRecord(InterestRecord r) {
    _repository.update(r.copyWith(updatedAt: DateTime.now()));
    _emit();
  }

  void deleteRecord(String id) {
    _repository.delete(id);
    _emit();
  }

  void closeRecord(String id) {
    final r = state.records.firstWhere((x) => x.id == id);
    updateRecord(r.copyWith(isClosed: true, closedDate: DateTime.now()));
  }

  void reopenRecord(String id) {
    final r = state.records.firstWhere((x) => x.id == id);
    updateRecord(r.copyWith(isClosed: false, clearClosedDate: true));
  }

  InterestRecord? getById(String id) {
    final m = state.records.where((r) => r.id == id);
    return m.isNotEmpty ? m.first : null;
  }

  // ── Payments ────────────────────────────────────────────────────────────

  void addPayment(String recordId, InterestPayment payment) {
    final r = getById(recordId);
    if (r == null) return;
    updateRecord(r.copyWith(payments: [...r.payments, payment]));
  }

  void updatePayment(String recordId, InterestPayment payment) {
    final r = getById(recordId);
    if (r == null) return;
    final list = r.payments
        .map((p) => p.id == payment.id ? payment : p)
        .toList();
    updateRecord(r.copyWith(payments: list));
  }

  void deletePayment(String recordId, String paymentId) {
    final r = getById(recordId);
    if (r == null) return;
    final list = r.payments.where((p) => p.id != paymentId).toList();
    updateRecord(r.copyWith(payments: list));
  }

  // ── Filtered views ──────────────────────────────────────────────────────

  List<InterestRecord> get lent => state.records
      .where((r) => r.direction == InterestDirection.lent)
      .toList()
    ..sort(_orderActiveFirst);

  List<InterestRecord> get borrowed => state.records
      .where((r) => r.direction == InterestDirection.borrowed)
      .toList()
    ..sort(_orderActiveFirst);

  int _orderActiveFirst(InterestRecord a, InterestRecord b) {
    if (a.isClosed != b.isClosed) return a.isClosed ? 1 : -1;
    return b.updatedAt.compareTo(a.updatedAt);
  }

  // ── Aggregates ──────────────────────────────────────────────────────────

  double get totalLentOutstanding => lent
      .where((r) => !r.isClosed)
      .fold(0.0, (s, r) => s + r.totalOutstanding);
  double get totalBorrowedOutstanding => borrowed
      .where((r) => !r.isClosed)
      .fold(0.0, (s, r) => s + r.totalOutstanding);

  double get totalInterestEarned => lent.fold(0.0, (s, r) => s + r.totalInterestPaid);
  double get totalInterestPaid =>
      borrowed.fold(0.0, (s, r) => s + r.totalInterestPaid);

  void _emit() => emit(state.copyWith(records: _repository.getAll()));
}
