import 'package:flutter/material.dart';

enum LoanType { home, car, personal, education, business, gold, credit, other }

extension LoanTypeExt on LoanType {
  String get label {
    switch (this) {
      case LoanType.home: return 'Home Loan';
      case LoanType.car: return 'Car/Vehicle Loan';
      case LoanType.personal: return 'Personal Loan';
      case LoanType.education: return 'Education Loan';
      case LoanType.business: return 'Business Loan';
      case LoanType.gold: return 'Gold Loan';
      case LoanType.credit: return 'Credit Card';
      case LoanType.other: return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case LoanType.home: return Icons.home_rounded;
      case LoanType.car: return Icons.directions_car_rounded;
      case LoanType.personal: return Icons.person_rounded;
      case LoanType.education: return Icons.school_rounded;
      case LoanType.business: return Icons.business_rounded;
      case LoanType.gold: return Icons.diamond_rounded;
      case LoanType.credit: return Icons.credit_card_rounded;
      case LoanType.other: return Icons.account_balance_rounded;
    }
  }

  Color get color {
    switch (this) {
      case LoanType.home: return Colors.blue;
      case LoanType.car: return Colors.indigo;
      case LoanType.personal: return Colors.purple;
      case LoanType.education: return Colors.teal;
      case LoanType.business: return Colors.brown;
      case LoanType.gold: return Colors.amber;
      case LoanType.credit: return Colors.red;
      case LoanType.other: return Colors.grey;
    }
  }
}

enum LoanDirection { borrowed, lent }

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

  double get totalRepaid =>
      repayments.fold(0.0, (sum, r) => sum + r.amount);

  double get totalPartPayments =>
      partPayments.fold(0.0, (sum, r) => sum + r.amount);

  double get totalInterestPaid =>
      repayments.fold(0.0, (sum, r) => sum + (r.interestPortion ?? 0));

  double get totalPrincipalPaid =>
      repayments.fold(0.0, (sum, r) => sum + (r.principalPortion ?? 0));

  double get outstandingBalance =>
      (principalAmount - totalPrincipalPaid - totalPartPayments)
          .clamp(0, double.infinity);

  double get totalPayable => emiAmount * tenureMonths;

  double get totalInterest => totalPayable - principalAmount;

  int get paidEmiCount => emiRepayments.length;

  int get remainingEmis => tenureMonths - paidEmiCount;

  double get progressPercent =>
      tenureMonths > 0 ? (paidEmiCount / tenureMonths).clamp(0.0, 1.0) : 0;

  int get elapsedMonths {
    final now = DateTime.now();
    return (now.year - startDate.year) * 12 + now.month - startDate.month;
  }

  int get overdueEmis {
    final due = elapsedMonths;
    final paid = paidEmiCount;
    return (due - paid).clamp(0, tenureMonths);
  }

  DateTime get nextEmiDate {
    return DateTime(
        startDate.year, startDate.month + paidEmiCount + 1, startDate.day);
  }

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
        type: LoanType.values[(json['type'] as int).clamp(0, LoanType.values.length - 1)],
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
        repayments: (json['repayments'] as List<dynamic>?)
                ?.map((r) => Repayment.fromJson(r as Map<String, dynamic>))
                .toList() ??
            [],
      );

  /// Calculate EMI from principal, rate, tenure
  static double calculateEmi(
      double principal, double annualRate, int months) {
    if (annualRate == 0) return principal / months;
    final r = annualRate / 12 / 100;
    final emi = principal * r * _pow(1 + r, months) / (_pow(1 + r, months) - 1);
    return emi;
  }

  static double _pow(double base, int exp) {
    double result = 1;
    for (int i = 0; i < exp; i++) {
      result *= base;
    }
    return result;
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

  const Repayment({
    required this.id,
    required this.monthNumber,
    required this.amount,
    this.principalPortion,
    this.interestPortion,
    required this.paidDate,
    this.notes,
    this.isPartPayment = false,
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
  }) => Repayment(
        id: id ?? this.id,
        monthNumber: monthNumber ?? this.monthNumber,
        amount: amount ?? this.amount,
        principalPortion: principalPortion ?? this.principalPortion,
        interestPortion: interestPortion ?? this.interestPortion,
        paidDate: paidDate ?? this.paidDate,
        notes: notes ?? this.notes,
        isPartPayment: isPartPayment ?? this.isPartPayment,
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
      );
}
