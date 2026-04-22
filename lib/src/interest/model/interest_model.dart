import 'package:flutter/material.dart';

enum InterestDirection {
  lent,     // I gave money to someone with interest
  borrowed, // I took money from someone with interest
}

extension InterestDirectionExt on InterestDirection {
  String get label {
    switch (this) {
      case InterestDirection.lent:
        return 'I Lent';
      case InterestDirection.borrowed:
        return 'I Borrowed';
    }
  }

  String get counterpartyLabel {
    switch (this) {
      case InterestDirection.lent:
        return 'Borrower';
      case InterestDirection.borrowed:
        return 'Lender';
    }
  }

  Color get color {
    switch (this) {
      case InterestDirection.lent:
        return Colors.green;
      case InterestDirection.borrowed:
        return Colors.deepOrange;
    }
  }

  IconData get icon {
    switch (this) {
      case InterestDirection.lent:
        return Icons.call_made_rounded;
      case InterestDirection.borrowed:
        return Icons.call_received_rounded;
    }
  }
}

enum RateUnit { perMonth, perYear }

extension RateUnitExt on RateUnit {
  String get label {
    switch (this) {
      case RateUnit.perMonth:
        return '% / month';
      case RateUnit.perYear:
        return '% / year';
    }
  }

  String get short {
    switch (this) {
      case RateUnit.perMonth:
        return 'pm';
      case RateUnit.perYear:
        return 'pa';
    }
  }
}

enum PaymentKind {
  interest,   // payment toward interest only
  principal,  // payment toward principal only
  mixed,      // a mix of both
}

extension PaymentKindExt on PaymentKind {
  String get label {
    switch (this) {
      case PaymentKind.interest:
        return 'Interest';
      case PaymentKind.principal:
        return 'Principal';
      case PaymentKind.mixed:
        return 'Mixed';
    }
  }

  Color get color {
    switch (this) {
      case PaymentKind.interest:
        return Colors.amber;
      case PaymentKind.principal:
        return Colors.blue;
      case PaymentKind.mixed:
        return Colors.purple;
    }
  }
}

/// One payment received (when lent) or made (when borrowed) for an
/// [InterestRecord].
class InterestPayment {
  final String id;
  final double amount;
  final DateTime paidDate;
  final PaymentKind kind;
  final double? principalPart; // optional split for [PaymentKind.mixed]
  final double? interestPart;
  final String? notes;
  final List<String> photoUrls;

  const InterestPayment({
    required this.id,
    required this.amount,
    required this.paidDate,
    this.kind = PaymentKind.interest,
    this.principalPart,
    this.interestPart,
    this.notes,
    this.photoUrls = const [],
  });

  /// How much of this payment reduces the principal owed.
  double get effectivePrincipal {
    switch (kind) {
      case PaymentKind.principal:
        return amount;
      case PaymentKind.interest:
        return 0;
      case PaymentKind.mixed:
        return principalPart ?? 0;
    }
  }

  /// How much of this payment counted as interest.
  double get effectiveInterest {
    switch (kind) {
      case PaymentKind.principal:
        return 0;
      case PaymentKind.interest:
        return amount;
      case PaymentKind.mixed:
        return interestPart ?? (amount - (principalPart ?? 0));
    }
  }

  InterestPayment copyWith({
    String? id,
    double? amount,
    DateTime? paidDate,
    PaymentKind? kind,
    double? principalPart,
    double? interestPart,
    String? notes,
    List<String>? photoUrls,
  }) {
    return InterestPayment(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      paidDate: paidDate ?? this.paidDate,
      kind: kind ?? this.kind,
      principalPart: principalPart ?? this.principalPart,
      interestPart: interestPart ?? this.interestPart,
      notes: notes ?? this.notes,
      photoUrls: photoUrls ?? this.photoUrls,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'paidDate': paidDate.toIso8601String(),
        'kind': kind.index,
        'principalPart': principalPart,
        'interestPart': interestPart,
        'notes': notes,
        'photoUrls': photoUrls,
      };

  factory InterestPayment.fromJson(Map<String, dynamic> json) =>
      InterestPayment(
        id: json['id'] as String,
        amount: (json['amount'] as num).toDouble(),
        paidDate: DateTime.parse(json['paidDate'] as String),
        kind: PaymentKind.values[
            (json['kind'] as int? ?? 0).clamp(0, PaymentKind.values.length - 1)],
        principalPart: (json['principalPart'] as num?)?.toDouble(),
        interestPart: (json['interestPart'] as num?)?.toDouble(),
        notes: json['notes'] as String?,
        photoUrls:
            (json['photoUrls'] as List<dynamic>?)?.cast<String>() ?? const [],
      );
}

/// One interest-bearing arrangement with a single counterparty.
class InterestRecord {
  final String id;
  final InterestDirection direction;
  final String personName;
  final String? personContact;

  final double principal;
  final double interestRate; // e.g. 2.0
  final RateUnit rateUnit;

  final DateTime startDate;
  final DateTime? expectedEndDate;
  final bool isClosed;
  final DateTime? closedDate;

  final String? notes;
  final List<String> agreementPhotoUrls; // initial agreement / loan slip
  final List<InterestPayment> payments;

  final DateTime createdAt;
  final DateTime updatedAt;

  const InterestRecord({
    required this.id,
    required this.direction,
    required this.personName,
    this.personContact,
    required this.principal,
    required this.interestRate,
    this.rateUnit = RateUnit.perMonth,
    required this.startDate,
    this.expectedEndDate,
    this.isClosed = false,
    this.closedDate,
    this.notes,
    this.agreementPhotoUrls = const [],
    this.payments = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  // ── Computed ────────────────────────────────────────────────────────────

  /// Convert the rate to "per month" so subsequent maths is uniform.
  double get monthlyRate {
    switch (rateUnit) {
      case RateUnit.perMonth:
        return interestRate;
      case RateUnit.perYear:
        return interestRate / 12;
    }
  }

  double get monthlyInterestOnPrincipal => principal * monthlyRate / 100;

  /// Months elapsed between [startDate] and [until] (defaults to today,
  /// or to [closedDate] when the record is closed).
  double monthsElapsed({DateTime? until}) {
    final end = until ?? (isClosed ? (closedDate ?? DateTime.now()) : DateTime.now());
    final ms = end.difference(startDate).inMilliseconds;
    if (ms <= 0) return 0;
    final days = ms / Duration.millisecondsPerDay;
    return days / 30.0; // approximate
  }

  /// Total interest accrued so far on the *original* principal. Approximates
  /// reality — does not reduce as principal payments come in. Use
  /// [interestAccruedReducing] for a more accurate estimate.
  double get interestAccruedFlat =>
      monthlyInterestOnPrincipal * monthsElapsed();

  /// More accurate: walk the payment history, reducing the running principal
  /// and accumulating interest between payment events.
  double get interestAccruedReducing {
    final sorted = List<InterestPayment>.from(payments)
      ..sort((a, b) => a.paidDate.compareTo(b.paidDate));
    double balance = principal;
    DateTime cursor = startDate;
    double interest = 0;
    for (final p in sorted) {
      if (p.paidDate.isBefore(cursor)) continue;
      final months =
          p.paidDate.difference(cursor).inMilliseconds / Duration.millisecondsPerDay / 30.0;
      interest += balance * monthlyRate / 100 * months;
      balance -= p.effectivePrincipal;
      if (balance < 0) balance = 0;
      cursor = p.paidDate;
    }
    final endRef =
        isClosed ? (closedDate ?? DateTime.now()) : DateTime.now();
    if (endRef.isAfter(cursor)) {
      final months =
          endRef.difference(cursor).inMilliseconds / Duration.millisecondsPerDay / 30.0;
      interest += balance * monthlyRate / 100 * months;
    }
    return interest < 0 ? 0 : interest;
  }

  double get totalPaid => payments.fold(0.0, (s, p) => s + p.amount);
  double get totalInterestPaid =>
      payments.fold(0.0, (s, p) => s + p.effectiveInterest);
  double get totalPrincipalPaid =>
      payments.fold(0.0, (s, p) => s + p.effectivePrincipal);

  double get outstandingPrincipal {
    final remaining = principal - totalPrincipalPaid;
    return remaining < 0 ? 0 : remaining;
  }

  double get outstandingInterest {
    final remaining = interestAccruedReducing - totalInterestPaid;
    return remaining < 0 ? 0 : remaining;
  }

  double get totalOutstanding => outstandingPrincipal + outstandingInterest;

  // ── copyWith / JSON ─────────────────────────────────────────────────────

  InterestRecord copyWith({
    String? id,
    InterestDirection? direction,
    String? personName,
    String? personContact,
    double? principal,
    double? interestRate,
    RateUnit? rateUnit,
    DateTime? startDate,
    DateTime? expectedEndDate,
    bool? isClosed,
    DateTime? closedDate,
    String? notes,
    List<String>? agreementPhotoUrls,
    List<InterestPayment>? payments,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearExpectedEndDate = false,
    bool clearClosedDate = false,
  }) {
    return InterestRecord(
      id: id ?? this.id,
      direction: direction ?? this.direction,
      personName: personName ?? this.personName,
      personContact: personContact ?? this.personContact,
      principal: principal ?? this.principal,
      interestRate: interestRate ?? this.interestRate,
      rateUnit: rateUnit ?? this.rateUnit,
      startDate: startDate ?? this.startDate,
      expectedEndDate: clearExpectedEndDate
          ? null
          : (expectedEndDate ?? this.expectedEndDate),
      isClosed: isClosed ?? this.isClosed,
      closedDate:
          clearClosedDate ? null : (closedDate ?? this.closedDate),
      notes: notes ?? this.notes,
      agreementPhotoUrls: agreementPhotoUrls ?? this.agreementPhotoUrls,
      payments: payments ?? this.payments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'direction': direction.index,
        'personName': personName,
        'personContact': personContact,
        'principal': principal,
        'interestRate': interestRate,
        'rateUnit': rateUnit.index,
        'startDate': startDate.toIso8601String(),
        'expectedEndDate': expectedEndDate?.toIso8601String(),
        'isClosed': isClosed,
        'closedDate': closedDate?.toIso8601String(),
        'notes': notes,
        'agreementPhotoUrls': agreementPhotoUrls,
        'payments': payments.map((p) => p.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory InterestRecord.fromJson(Map<String, dynamic> json) =>
      InterestRecord(
        id: json['id'] as String,
        direction: InterestDirection.values[
            (json['direction'] as int? ?? 0)
                .clamp(0, InterestDirection.values.length - 1)],
        personName: json['personName'] as String,
        personContact: json['personContact'] as String?,
        principal: (json['principal'] as num).toDouble(),
        interestRate: (json['interestRate'] as num).toDouble(),
        rateUnit: RateUnit.values[
            (json['rateUnit'] as int? ?? 0).clamp(0, RateUnit.values.length - 1)],
        startDate: DateTime.parse(json['startDate'] as String),
        expectedEndDate: json['expectedEndDate'] != null
            ? DateTime.parse(json['expectedEndDate'] as String)
            : null,
        isClosed: json['isClosed'] as bool? ?? false,
        closedDate: json['closedDate'] != null
            ? DateTime.parse(json['closedDate'] as String)
            : null,
        notes: json['notes'] as String?,
        agreementPhotoUrls:
            (json['agreementPhotoUrls'] as List<dynamic>?)?.cast<String>() ??
                const [],
        payments: (json['payments'] as List<dynamic>?)
                ?.cast<Map<String, dynamic>>()
                .map(InterestPayment.fromJson)
                .toList() ??
            const [],
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}
