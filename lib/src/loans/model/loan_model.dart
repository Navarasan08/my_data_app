import 'dart:math' as math;

import 'package:flutter/material.dart';

enum LoanType { home, car, personal, education, business, gold, credit, other }

extension LoanTypeExt on LoanType {
  String get label {
    switch (this) {
      case LoanType.home:
        return 'Home Loan';
      case LoanType.car:
        return 'Car/Vehicle Loan';
      case LoanType.personal:
        return 'Personal Loan';
      case LoanType.education:
        return 'Education Loan';
      case LoanType.business:
        return 'Business Loan';
      case LoanType.gold:
        return 'Gold Loan';
      case LoanType.credit:
        return 'Credit Card';
      case LoanType.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case LoanType.home:
        return Icons.home_rounded;
      case LoanType.car:
        return Icons.directions_car_rounded;
      case LoanType.personal:
        return Icons.person_rounded;
      case LoanType.education:
        return Icons.school_rounded;
      case LoanType.business:
        return Icons.business_rounded;
      case LoanType.gold:
        return Icons.diamond_rounded;
      case LoanType.credit:
        return Icons.credit_card_rounded;
      case LoanType.other:
        return Icons.account_balance_rounded;
    }
  }

  Color get color {
    switch (this) {
      case LoanType.home:
        return Colors.blue;
      case LoanType.car:
        return Colors.indigo;
      case LoanType.personal:
        return Colors.purple;
      case LoanType.education:
        return Colors.teal;
      case LoanType.business:
        return Colors.brown;
      case LoanType.gold:
        return Colors.amber;
      case LoanType.credit:
        return Colors.red;
      case LoanType.other:
        return Colors.grey;
    }
  }
}

enum LoanDirection { borrowed, lent }

enum PartPaymentStrategy { reduceTenure, reduceEmi }

class Loan {
  final String id;
  final String name;
  final LoanType type;
  final LoanDirection direction; // borrowed or lent
  final double principalAmount;
  final double interestRate; // annual %
  final int tenureMonths;
  final double emiAmount;
  final DateTime startDate;
  final DateTime? endDate;
  final String? lenderOrBorrower; // bank/person name
  final String? accountNumber;
  final String? notes;
  final bool isClosed;
  final List<Repayment> repayments;

  const Loan({
    required this.id,
    required this.name,
    required this.type,
    this.direction = LoanDirection.borrowed,
    required this.principalAmount,
    required this.interestRate,
    required this.tenureMonths,
    required this.emiAmount,
    required this.startDate,
    this.endDate,
    this.lenderOrBorrower,
    this.accountNumber,
    this.notes,
    this.isClosed = false,
    this.repayments = const [],
  });

  // ── Computed ────────────────────────────────────────────────────────────

  List<Repayment> get emiRepayments =>
      repayments.where((r) => !r.isPartPayment).toList();

  List<Repayment> get partPayments =>
      repayments.where((r) => r.isPartPayment).toList();

  double get totalRepaid => repayments.fold(0.0, (sum, r) => sum + r.amount);

  double get totalPartPayments =>
      partPayments.fold(0.0, (sum, r) => sum + r.amount);

  double get totalInterestPaid =>
      repayments.fold(0.0, (sum, r) => sum + (r.interestPortion ?? 0));

  double get totalPrincipalPaid =>
      repayments.fold(0.0, (sum, r) => sum + (r.principalPortion ?? 0));

  /// Principal still owed. Part payments carry their amount in
  /// [Repayment.principalPortion] too, so only EMI portions are summed here —
  /// counting [totalPrincipalPaid] as well would subtract part payments twice.
  double get outstandingBalance {
    final emiPrincipal = emiRepayments.fold(
      0.0,
      (sum, r) => sum + (r.principalPortion ?? 0),
    );
    return (principalAmount - emiPrincipal - totalPartPayments).clamp(
      0,
      double.infinity,
    );
  }

  double get totalPayable => emiAmount * tenureMonths;

  double get totalInterest => totalPayable - principalAmount;

  int get paidEmiCount => emiRepayments.length;

  int get remainingEmis => (tenureMonths - paidEmiCount).clamp(0, tenureMonths);

  double get progressPercent =>
      tenureMonths > 0 ? (paidEmiCount / tenureMonths).clamp(0.0, 1.0) : 0;

  /// Due date of EMI [n] (1-based): [n] months after [startDate], on the
  /// start's day-of-month clamped to the target month's length (a loan
  /// started on the 31st is due on the 28th/29th/30th in shorter months).
  DateTime emiDueDate(int n) {
    final y = startDate.year;
    final m = startDate.month + n;
    final daysInMonth = DateTime(y, m + 1, 0).day;
    return DateTime(y, m, startDate.day.clamp(1, daysInMonth));
  }

  int get elapsedMonths {
    final now = DateTime.now();
    return (now.year - startDate.year) * 12 + now.month - startDate.month;
  }

  /// How many EMIs have fallen due so far: those whose due date is on or
  /// before today, never more than the tenure.
  int get dueEmiCount {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var due = elapsedMonths;
    // The current month's EMI counts only once its day-of-month has passed.
    if (due >= 1 && due <= tenureMonths && emiDueDate(due).isAfter(today)) {
      due -= 1;
    }
    return due.clamp(0, tenureMonths);
  }

  int get overdueEmis => (dueEmiCount - paidEmiCount).clamp(0, tenureMonths);

  DateTime get nextEmiDate => emiDueDate(paidEmiCount + 1);

  String get directionLabel =>
      direction == LoanDirection.borrowed ? 'Borrowed' : 'Lent';

  Loan copyWith({
    String? id,
    String? name,
    LoanType? type,
    LoanDirection? direction,
    double? principalAmount,
    double? interestRate,
    int? tenureMonths,
    double? emiAmount,
    DateTime? startDate,
    DateTime? endDate,
    String? lenderOrBorrower,
    String? accountNumber,
    String? notes,
    bool? isClosed,
    List<Repayment>? repayments,
  }) {
    return Loan(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      direction: direction ?? this.direction,
      principalAmount: principalAmount ?? this.principalAmount,
      interestRate: interestRate ?? this.interestRate,
      tenureMonths: tenureMonths ?? this.tenureMonths,
      emiAmount: emiAmount ?? this.emiAmount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      lenderOrBorrower: lenderOrBorrower ?? this.lenderOrBorrower,
      accountNumber: accountNumber ?? this.accountNumber,
      notes: notes ?? this.notes,
      isClosed: isClosed ?? this.isClosed,
      repayments: repayments ?? this.repayments,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.index,
    'direction': direction.index,
    'principalAmount': principalAmount,
    'interestRate': interestRate,
    'tenureMonths': tenureMonths,
    'emiAmount': emiAmount,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate?.toIso8601String(),
    'lenderOrBorrower': lenderOrBorrower,
    'accountNumber': accountNumber,
    'notes': notes,
    'isClosed': isClosed,
    'repayments': repayments.map((r) => r.toJson()).toList(),
  };

  factory Loan.fromJson(Map<String, dynamic> json) => Loan(
    id: json['id'] as String,
    name: json['name'] as String,
    type: LoanType
        .values[(json['type'] as int).clamp(0, LoanType.values.length - 1)],
    direction: json['direction'] != null
        ? LoanDirection.values[(json['direction'] as int).clamp(0, 1)]
        : LoanDirection.borrowed,
    principalAmount: (json['principalAmount'] as num).toDouble(),
    interestRate: (json['interestRate'] as num).toDouble(),
    tenureMonths: json['tenureMonths'] as int,
    emiAmount: (json['emiAmount'] as num).toDouble(),
    startDate: DateTime.parse(json['startDate'] as String),
    endDate: json['endDate'] != null
        ? DateTime.parse(json['endDate'] as String)
        : null,
    lenderOrBorrower: json['lenderOrBorrower'] as String?,
    accountNumber: json['accountNumber'] as String?,
    notes: json['notes'] as String?,
    isClosed: json['isClosed'] as bool? ?? false,
    repayments:
        (json['repayments'] as List<dynamic>?)
            ?.map((r) => Repayment.fromJson(r as Map<String, dynamic>))
            .toList() ??
        [],
  );

  /// Standard EMI formula: P·r·(1+r)ⁿ / ((1+r)ⁿ − 1), with r the monthly
  /// rate. A zero rate degenerates to straight-line principal.
  static double calculateEmi(double principal, double annualRate, int months) {
    if (months <= 0) return 0;
    if (annualRate == 0) return principal / months;
    final r = annualRate / 12 / 100;
    final factor = math.pow(1 + r, months).toDouble();
    return principal * r * factor / (factor - 1);
  }

  // ── Advanced computed properties ──────────────────────────────────────

  /// Effective outstanding after all part payments applied
  double get effectivePrincipal =>
      (principalAmount - totalPartPayments).clamp(0, double.infinity);

  /// Total interest over full loan life (original schedule). Clamped to
  /// zero so an understated EMI can't produce negative interest.
  double get totalInterestOriginal {
    if (interestRate == 0) return 0;
    return ((emiAmount * tenureMonths) - principalAmount).clamp(
      0,
      double.infinity,
    );
  }

  /// Interest already paid (sum of interest portions from all repayments)
  double get interestPaid =>
      repayments.fold(0.0, (sum, r) => sum + (r.interestPortion ?? 0));

  /// Remaining interest to be paid (estimated from remaining EMIs)
  double get interestRemaining {
    final remainingPrincipal = outstandingBalance;
    if (interestRate == 0 || remainingEmis <= 0) return 0;
    // Approximate: remaining EMIs * emiAmount - remaining principal
    return (emiAmount * remainingEmis - remainingPrincipal).clamp(
      0,
      double.infinity,
    );
  }

  /// Total interest (paid + remaining)
  double get totalInterestActual => interestPaid + interestRemaining;

  /// Interest saved from part payments
  double get interestSaved => totalInterestOriginal > totalInterestActual
      ? totalInterestOriginal - totalInterestActual
      : 0;

  // ── Amortization ─────────────────────────────────────────────────────

  /// Generate month-by-month amortization schedule
  List<AmortizationEntry> get amortizationSchedule {
    if (interestRate == 0) {
      return List.generate(tenureMonths, (i) {
        final principal = emiAmount;
        return AmortizationEntry(
          month: i + 1,
          emi: emiAmount,
          principal: principal,
          interest: 0,
          balance: (principalAmount - (principal * (i + 1))).clamp(
            0,
            double.infinity,
          ),
        );
      });
    }
    final monthlyRate = interestRate / 12 / 100;
    double balance = principalAmount;
    final schedule = <AmortizationEntry>[];
    for (int i = 0; i < tenureMonths && balance > 0; i++) {
      final interest = balance * monthlyRate;
      final principal = (emiAmount - interest).clamp(0.0, balance);
      balance -= principal;
      // Apply any part payments at this month. Payments dated before the
      // first EMI land on month 1 rather than dropping off the schedule.
      for (final pp in partPayments) {
        final ppMonth =
            ((pp.paidDate.year - startDate.year) * 12 +
                    pp.paidDate.month -
                    startDate.month)
                .clamp(1, tenureMonths);
        if (ppMonth == i + 1) {
          balance = (balance - pp.amount).clamp(0, double.infinity);
        }
      }
      schedule.add(
        AmortizationEntry(
          month: i + 1,
          emi: emiAmount,
          principal: principal,
          interest: interest,
          balance: balance < 0.01 ? 0 : balance,
        ),
      );
      if (balance <= 0) break;
    }
    return schedule;
  }

  /// Calculate new EMI after part payment with reduced principal
  static double calculateNewEmi(
    double remainingPrincipal,
    double annualRate,
    int remainingMonths,
  ) {
    return calculateEmi(remainingPrincipal, annualRate, remainingMonths);
  }

  /// Months needed to clear [remainingPrincipal] at the same [emi]:
  /// n = −ln(1 − P·r/E) / ln(1+r). Returns 999 when the EMI doesn't even
  /// cover the monthly interest (the balance would never shrink).
  static int calculateNewTenure(
    double remainingPrincipal,
    double annualRate,
    double emi,
  ) {
    if (emi <= 0) return 999;
    if (annualRate == 0) return (remainingPrincipal / emi).ceil();
    final r = annualRate / 12 / 100;
    if (emi <= remainingPrincipal * r) return 999; // EMI too low
    final n = -math.log(1 - (remainingPrincipal * r / emi)) / math.log(1 + r);
    return n.ceil();
  }
}

class Repayment {
  final String id;
  final int monthNumber; // 0 for part payments
  final double amount;
  final double? principalPortion;
  final double? interestPortion;
  final DateTime paidDate;
  final String? notes;
  final bool isPartPayment;
  final PartPaymentStrategy? strategy; // only used for part payments

  const Repayment({
    required this.id,
    required this.monthNumber,
    required this.amount,
    this.principalPortion,
    this.interestPortion,
    required this.paidDate,
    this.notes,
    this.isPartPayment = false,
    this.strategy,
  });

  Repayment copyWith({
    String? id,
    int? monthNumber,
    double? amount,
    double? principalPortion,
    double? interestPortion,
    DateTime? paidDate,
    String? notes,
    bool? isPartPayment,
    PartPaymentStrategy? strategy,
  }) => Repayment(
    id: id ?? this.id,
    monthNumber: monthNumber ?? this.monthNumber,
    amount: amount ?? this.amount,
    principalPortion: principalPortion ?? this.principalPortion,
    interestPortion: interestPortion ?? this.interestPortion,
    paidDate: paidDate ?? this.paidDate,
    notes: notes ?? this.notes,
    isPartPayment: isPartPayment ?? this.isPartPayment,
    strategy: strategy ?? this.strategy,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'monthNumber': monthNumber,
    'amount': amount,
    'principalPortion': principalPortion,
    'interestPortion': interestPortion,
    'paidDate': paidDate.toIso8601String(),
    'notes': notes,
    'isPartPayment': isPartPayment,
    'strategy': strategy?.index,
  };

  factory Repayment.fromJson(Map<String, dynamic> json) => Repayment(
    id: json['id'] as String,
    monthNumber: json['monthNumber'] as int,
    amount: (json['amount'] as num).toDouble(),
    principalPortion: (json['principalPortion'] as num?)?.toDouble(),
    interestPortion: (json['interestPortion'] as num?)?.toDouble(),
    paidDate: DateTime.parse(json['paidDate'] as String),
    notes: json['notes'] as String?,
    isPartPayment: json['isPartPayment'] as bool? ?? false,
    strategy: json['strategy'] != null
        ? PartPaymentStrategy.values[(json['strategy'] as int).clamp(
            0,
            PartPaymentStrategy.values.length - 1,
          )]
        : null,
  );
}

class AmortizationEntry {
  final int month;
  final double emi;
  final double principal;
  final double interest;
  final double balance;

  const AmortizationEntry({
    required this.month,
    required this.emi,
    required this.principal,
    required this.interest,
    required this.balance,
  });
}
