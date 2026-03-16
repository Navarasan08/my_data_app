import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_data_app/src/loans/model/loan_model.dart';
import 'package:my_data_app/src/loans/repository/loan_repository.dart';
import 'package:my_data_app/src/loans/cubit/loan_state.dart';

class LoanCubit extends Cubit<LoanState> {
  final LoanRepository _repository;

  LoanCubit(this._repository)
      : super(LoanState(loans: _repository.getAll()));

  void addLoan(Loan loan) {
    // Auto-generate past EMIs if start date is before this month
    final now = DateTime.now();
    final elapsed = (now.year - loan.startDate.year) * 12 +
        now.month - loan.startDate.month;
    if (elapsed > 0 && loan.repayments.isEmpty) {
      final autoCount = elapsed.clamp(0, loan.tenureMonths);
      final autoRepayments = List<Repayment>.generate(autoCount, (i) {
        final monthNum = i + 1;
        final paidDate = DateTime(
            loan.startDate.year, loan.startDate.month + monthNum, loan.startDate.day);
        return Repayment(
          id: '${loan.id}_auto_$monthNum',
          monthNumber: monthNum,
          amount: loan.emiAmount,
          paidDate: paidDate,
          notes: 'Auto-generated',
        );
      });
      final loanWithEmis = loan.copyWith(repayments: autoRepayments);
      _repository.add(loanWithEmis);
    } else {
      _repository.add(loan);
    }
    emit(state.copyWith(loans: _repository.getAll()));
  }

  void updateLoan(Loan loan) {
    _repository.update(loan);
    emit(state.copyWith(loans: _repository.getAll()));
  }

  void deleteLoan(String id) {
    _repository.delete(id);
    emit(state.copyWith(loans: _repository.getAll()));
  }

  void addRepayment(String loanId, Repayment repayment) {
    final loan = state.loans.firstWhere((l) => l.id == loanId);
    final updated = loan.copyWith(
      repayments: [...loan.repayments, repayment],
    );
    _repository.update(updated);
    emit(state.copyWith(loans: _repository.getAll()));
  }

  void deleteRepayment(String loanId, String repaymentId) {
    final loan = state.loans.firstWhere((l) => l.id == loanId);
    final updated = loan.copyWith(
      repayments: loan.repayments.where((r) => r.id != repaymentId).toList(),
    );
    _repository.update(updated);
    emit(state.copyWith(loans: _repository.getAll()));
  }

  void addPartPayment(String loanId, Repayment partPayment) {
    final loan = state.loans.firstWhere((l) => l.id == loanId);
    final updated = loan.copyWith(
      repayments: [...loan.repayments, partPayment.copyWith(isPartPayment: true)],
    );
    _repository.update(updated);
    emit(state.copyWith(loans: _repository.getAll()));
  }

  void closeLoan(String loanId) {
    final loan = state.loans.firstWhere((l) => l.id == loanId);
    _repository.update(loan.copyWith(isClosed: true, endDate: DateTime.now()));
    emit(state.copyWith(loans: _repository.getAll()));
  }

  Loan? getLoanById(String id) {
    final matches = state.loans.where((l) => l.id == id);
    return matches.isNotEmpty ? matches.first : null;
  }

  List<Loan> get activeLoans =>
      state.loans.where((l) => !l.isClosed).toList();

  List<Loan> get closedLoans =>
      state.loans.where((l) => l.isClosed).toList();

  List<Loan> get borrowedLoans =>
      state.loans.where((l) => l.direction == LoanDirection.borrowed).toList();

  List<Loan> get lentLoans =>
      state.loans.where((l) => l.direction == LoanDirection.lent).toList();

  double get totalBorrowed => borrowedLoans
      .where((l) => !l.isClosed)
      .fold(0.0, (sum, l) => sum + l.outstandingBalance);

  double get totalLent => lentLoans
      .where((l) => !l.isClosed)
      .fold(0.0, (sum, l) => sum + l.outstandingBalance);

  double get totalMonthlyEmi => activeLoans
      .where((l) => l.direction == LoanDirection.borrowed)
      .fold(0.0, (sum, l) => sum + l.emiAmount);
}
