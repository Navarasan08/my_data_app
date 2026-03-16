import 'package:my_data_app/src/loans/model/loan_model.dart';

class LoanState {
  final List<Loan> loans;

  const LoanState({required this.loans});

  LoanState copyWith({List<Loan>? loans}) =>
      LoanState(loans: loans ?? this.loans);
}
