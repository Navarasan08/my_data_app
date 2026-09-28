import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_data_app/src/loans/model/loan_model.dart';
import 'package:my_data_app/src/loans/repository/loan_repository.dart';
import 'package:my_data_app/src/loans/cubit/loan_state.dart';

class LoanCubit extends Cubit<LoanState> {
  final LoanRepository _repository;
  StreamSubscription<void>? _sub;

  LoanCubit(this._repository)
    : super(
        LoanState(
          loans: _repository.getAll(),
          syncStatus: _repository.syncStatus,
        ),
      ) {
    _sub = _repository.changes.listen((_) => _sync());
  }

  /// Pulls the repository's current list and sync status into state. Runs
  /// on every realtime change and after each local write.
  void _sync() {
    emit(
      state.copyWith(
        loans: _repository.getAll(),
        syncStatus: _repository.syncStatus,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }

  /// Split an EMI into principal & interest using amortization formula
  static ({double principal, double interest}) _splitEmi(
    double balance,
    double annualRate,
    double emi,
  ) {
    if (annualRate == 0) {
      return (principal: emi, interest: 0.0);
    }
    final monthlyRate = annualRate / 12 / 100;
    final interest = balance * monthlyRate;
    final principal = (emi - interest).clamp(0.0, balance);
    return (principal: principal, interest: interest);
  }

  void addLoan(Loan loan) {
    // Auto-generate past EMIs if start date is before this month
    final now = DateTime.now();
    final elapsed =
        (now.year - loan.startDate.year) * 12 +
        now.month -
        loan.startDate.month;
    if (elapsed > 0 && loan.repayments.isEmpty) {
      final autoCount = elapsed.clamp(0, loan.tenureMonths);
      double balance = loan.principalAmount;
      final autoRepayments = <Repayment>[];
      for (int i = 0; i < autoCount; i++) {
        final monthNum = i + 1;
        final paidDate = DateTime(
          loan.startDate.year,
          loan.startDate.month + monthNum,
          loan.startDate.day,
        );
        final split = _splitEmi(balance, loan.interestRate, loan.emiAmount);
        balance -= split.principal;
        autoRepayments.add(
          Repayment(
            id: '${loan.id}_auto_$monthNum',
            monthNumber: monthNum,
            amount: loan.emiAmount,
            principalPortion: split.principal,
            interestPortion: split.interest,
            paidDate: paidDate,
            notes: 'Auto-generated',
          ),
        );
      }
      final loanWithEmis = loan.copyWith(repayments: autoRepayments);
      _repository.add(loanWithEmis);
    } else {
      _repository.add(loan);
    }
    _sync();
  }

  void updateLoan(Loan loan) {
    final existing = state.loans.firstWhere(
      (l) => l.id == loan.id,
      orElse: () => loan,
    );

    final startChanged = existing.startDate != loan.startDate;

    Loan toSave = loan;

    if (startChanged) {
      // Rebuild the EMI schedule to span exactly from the new startDate to
      // today. Keep part-payments untouched (they track real cash events).
      final partPayments = loan.repayments
          .where((r) => r.isPartPayment)
          .toList();

      final now = DateTime.now();
      final elapsed =
          (now.year - loan.startDate.year) * 12 +
          (now.month - loan.startDate.month);
      final target = elapsed.clamp(0, loan.tenureMonths);

      final rebuiltEmis = <Repayment>[];

      for (int m = 1; m <= target; m++) {
        final paidDate = DateTime(
          loan.startDate.year,
          loan.startDate.month + m,
          loan.startDate.day,
        );

        // Reduce balance by any part-payments that fall on/before this EMI's
        // due date so the amortization stays realistic.
        final ppBefore = partPayments
            .where((pp) => !pp.paidDate.isAfter(paidDate))
            .fold(0.0, (s, pp) => s + pp.amount);
        final effectiveBalance =
            (loan.principalAmount - ppBefore - _paidSoFar(rebuiltEmis))
                .clamp(0.0, loan.principalAmount)
                .toDouble();

        final split = _splitEmi(
          effectiveBalance,
          loan.interestRate,
          loan.emiAmount,
        );
        rebuiltEmis.add(
          Repayment(
            id: '${loan.id}_auto_${DateTime.now().millisecondsSinceEpoch}_$m',
            monthNumber: m,
            amount: loan.emiAmount,
            principalPortion: split.principal,
            interestPortion: split.interest,
            paidDate: paidDate,
            notes: 'Auto-generated',
          ),
        );
      }

      toSave = loan.copyWith(repayments: [...rebuiltEmis, ...partPayments]);
    }

    _repository.update(toSave);
    _sync();
  }

  double _paidSoFar(List<Repayment> emis) =>
      emis.fold(0.0, (s, r) => s + (r.principalPortion ?? 0));

  void deleteLoan(String id) {
    _repository.delete(id);
    _sync();
  }

  void addRepayment(String loanId, Repayment repayment) {
    final loan = state.loans.firstWhere((l) => l.id == loanId);
    // Fill in whichever side of the principal/interest split is missing —
    // outstandingBalance only shrinks through principalPortion, so a
    // repayment must never be stored with both halves null.
    Repayment finalRepayment = repayment;
    if (repayment.principalPortion == null &&
        repayment.interestPortion == null) {
      final balance = loan.outstandingBalance;
      final split = _splitEmi(balance, loan.interestRate, repayment.amount);
      finalRepayment = repayment.copyWith(
        principalPortion: split.principal,
        interestPortion: split.interest,
      );
    } else if (repayment.principalPortion == null) {
      finalRepayment = repayment.copyWith(
        principalPortion: (repayment.amount - repayment.interestPortion!)
            .clamp(0.0, repayment.amount),
      );
    } else if (repayment.interestPortion == null) {
      finalRepayment = repayment.copyWith(
        interestPortion: (repayment.amount - repayment.principalPortion!)
            .clamp(0.0, repayment.amount),
      );
    }
    final updated = loan.copyWith(
      repayments: [...loan.repayments, finalRepayment],
    );
    _repository.update(updated);
    _sync();
  }

  void deleteRepayment(String loanId, String repaymentId) {
    final loan = state.loans.firstWhere((l) => l.id == loanId);
    final updated = loan.copyWith(
      repayments: loan.repayments.where((r) => r.id != repaymentId).toList(),
    );
    _repository.update(updated);
    _sync();
  }

  void addPartPayment(
    String loanId,
    Repayment partPayment,
    PartPaymentStrategy strategy, {
    double? newEmi,
  }) {
    final loan = state.loans.firstWhere((l) => l.id == loanId);
    final updatedRepayments = [
      ...loan.repayments,
      partPayment.copyWith(isPartPayment: true, strategy: strategy),
    ];

    final remainingPrincipal =
        (loan.principalAmount -
                updatedRepayments
                    .where((r) => r.isPartPayment)
                    .fold(0.0, (sum, r) => sum + r.amount) -
                updatedRepayments
                    .where((r) => !r.isPartPayment)
                    .fold(0.0, (sum, r) => sum + (r.principalPortion ?? 0)))
            .clamp(0.0, double.infinity)
            .toDouble();

    final remainingEmis = loan.tenureMonths - loan.emiRepayments.length;

    Loan updated;
    if (strategy == PartPaymentStrategy.reduceEmi) {
      // Recalculate EMI with same remaining tenure
      final calculatedEmi =
          newEmi ??
          Loan.calculateNewEmi(
            remainingPrincipal,
            loan.interestRate,
            remainingEmis > 0 ? remainingEmis : 1,
          );
      updated = loan.copyWith(
        repayments: updatedRepayments,
        emiAmount: calculatedEmi,
      );
    } else {
      // Reduce tenure, keep same EMI
      final newTenure =
          loan.paidEmiCount +
          Loan.calculateNewTenure(
            remainingPrincipal,
            loan.interestRate,
            loan.emiAmount,
          );
      updated = loan.copyWith(
        repayments: updatedRepayments,
        tenureMonths: newTenure,
      );
    }

    _repository.update(updated);
    _sync();
  }

  void closeLoan(String loanId) {
    final loan = state.loans.firstWhere((l) => l.id == loanId);
    _repository.update(loan.copyWith(isClosed: true, endDate: DateTime.now()));
    _sync();
  }

  Loan? getLoanById(String id) {
    final matches = state.loans.where((l) => l.id == id);
    return matches.isNotEmpty ? matches.first : null;
  }

  List<Loan> get activeLoans => state.loans.where((l) => !l.isClosed).toList();

  List<Loan> get closedLoans => state.loans.where((l) => l.isClosed).toList();

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

  /// Sum of EMIs still being paid: open borrowed loans with EMIs left. A
  /// fully-paid loan that just hasn't been closed doesn't owe a monthly EMI.
  double get totalMonthlyEmi => activeLoans
      .where((l) => l.direction == LoanDirection.borrowed && l.remainingEmis > 0)
      .fold(0.0, (sum, l) => sum + l.emiAmount);

  double get totalInterestPaidAll => state.loans
      .where((l) => l.direction == LoanDirection.borrowed)
      .fold(0.0, (sum, l) => sum + l.interestPaid);

  double get totalInterestRemainingAll => state.loans
      .where((l) => l.direction == LoanDirection.borrowed && !l.isClosed)
      .fold(0.0, (sum, l) => sum + l.interestRemaining);

  double get totalInterestSavedAll => state.loans
      .where((l) => l.direction == LoanDirection.borrowed)
      .fold(0.0, (sum, l) => sum + l.interestSaved);
}
