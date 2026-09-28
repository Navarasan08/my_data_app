import 'package:flutter_test/flutter_test.dart';
import 'package:my_data_app/src/loans/model/loan_model.dart';

Loan loan({
  double principal = 100000,
  double rate = 12,
  int tenure = 12,
  double? emi,
  DateTime? start,
  List<Repayment> repayments = const [],
  bool isClosed = false,
}) {
  return Loan(
    id: 'l1',
    name: 'Test',
    type: LoanType.personal,
    principalAmount: principal,
    interestRate: rate,
    tenureMonths: tenure,
    emiAmount: emi ?? Loan.calculateEmi(principal, rate, tenure),
    startDate: start ?? DateTime(2020, 1, 15),
    repayments: repayments,
    isClosed: isClosed,
  );
}

Repayment emi(int n, {double amount = 8885, double? principalPart}) =>
    Repayment(
      id: 'r$n',
      monthNumber: n,
      amount: amount,
      principalPortion: principalPart,
      interestPortion: principalPart == null ? null : amount - principalPart,
      paidDate: DateTime(2020, 1 + n, 15),
    );

void main() {
  group('calculateEmi', () {
    test('matches the standard amortization formula', () {
      // 1L at 12%/yr over 12 months → the textbook value 8884.88.
      expect(Loan.calculateEmi(100000, 12, 12), closeTo(8884.88, 0.01));
    });

    test('zero rate is straight-line principal', () {
      expect(Loan.calculateEmi(12000, 0, 12), 1000);
    });

    test('zero months yields zero instead of dividing by zero', () {
      expect(Loan.calculateEmi(10000, 10, 0), 0);
    });
  });

  group('calculateNewTenure', () {
    test('matches the closed-form n = -ln(1-Pr/E)/ln(1+r)', () {
      // 50k at 12%/yr with EMI 8884.88 clears in 6 months.
      expect(Loan.calculateNewTenure(50000, 12, 8884.88), 6);
    });

    test('caps at 999 when the EMI cannot cover monthly interest', () {
      // Monthly interest on 1L at 12% is 1000; an EMI of 900 never ends.
      expect(Loan.calculateNewTenure(100000, 12, 900), 999);
    });

    test('zero rate divides principal by EMI', () {
      expect(Loan.calculateNewTenure(10000, 0, 2500), 4);
    });
  });

  group('overdueEmis', () {
    test('a fully-paid loan past its tenure has no overdue EMIs', () {
      // Started years ago, 12-month tenure, all 12 EMIs paid. The old
      // formula counted every elapsed month and reported phantom overdues.
      final l = loan(
        start: DateTime(2020, 1, 15),
        repayments: [for (var n = 1; n <= 12; n++) emi(n)],
      );
      expect(l.overdueEmis, 0);
    });

    test('unpaid EMIs within the tenure are overdue', () {
      final l = loan(
        start: DateTime(2020, 1, 15),
        repayments: [for (var n = 1; n <= 10; n++) emi(n)],
      );
      expect(l.overdueEmis, 2);
    });

    test('never exceeds the tenure even with nothing paid', () {
      final l = loan(start: DateTime(2018, 1, 15));
      expect(l.overdueEmis, 12);
    });
  });

  group('emiDueDate / nextEmiDate', () {
    test('clamps the day for shorter months', () {
      // Started 31 Jan → February's EMI is due on the 29th (2020 is a leap
      // year), not on an invalid 31 Feb that rolls into March.
      final l = loan(start: DateTime(2020, 1, 31));
      expect(l.emiDueDate(1), DateTime(2020, 2, 29));
      expect(l.nextEmiDate, DateTime(2020, 2, 29));
    });

    test('advances with paid EMIs', () {
      final l = loan(
        start: DateTime(2020, 1, 15),
        repayments: [emi(1), emi(2)],
      );
      expect(l.nextEmiDate, DateTime(2020, 4, 15));
    });
  });

  group('balances and interest', () {
    test('outstanding falls by principal portions and part payments', () {
      final l = loan(
        principal: 100000,
        repayments: [
          emi(1, principalPart: 7885),
          Repayment(
            id: 'pp1',
            monthNumber: 0,
            amount: 20000,
            principalPortion: 20000,
            interestPortion: 0,
            paidDate: DateTime(2020, 3, 1),
            isPartPayment: true,
          ),
        ],
      );
      expect(l.outstandingBalance, closeTo(100000 - 7885 - 20000, 0.01));
    });

    test('totalInterestOriginal never goes negative', () {
      // An EMI entered too low would make emi*tenure < principal.
      final l = loan(emi: 1000, tenure: 12, principal: 100000);
      expect(l.totalInterestOriginal, 0);
    });

    test('zero-rate amortization ends at zero, not below', () {
      final l = loan(principal: 10000, rate: 0, tenure: 3, emi: 3500);
      final schedule = l.amortizationSchedule;
      expect(schedule.last.balance, greaterThanOrEqualTo(0));
    });
  });

  test('remainingEmis never goes negative', () {
    final l = loan(
      tenure: 2,
      repayments: [emi(1), emi(2), emi(3)],
    );
    expect(l.remainingEmis, 0);
  });
}
