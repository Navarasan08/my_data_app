import 'package:flutter/material.dart';

enum DebtDirection { lent, borrowed }

extension DebtDirectionExt on DebtDirection {
  String get label => this == DebtDirection.lent ? 'Lent' : 'Borrowed';
  String get verb => this == DebtDirection.lent ? 'gave to' : 'took from';
  Color get color => this == DebtDirection.lent ? Colors.green : Colors.red;
  IconData get icon => this == DebtDirection.lent
      ? Icons.arrow_upward_rounded
      : Icons.arrow_downward_rounded;
}

class DebtSettlement {
  final String id;
  final double amount;
  final DateTime date;
  final String? note;

  const DebtSettlement({
    required this.id,
    required this.amount,
    required this.date,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'date': date.toIso8601String(),
        'note': note,
      };

  factory DebtSettlement.fromJson(Map<String, dynamic> json) => DebtSettlement(
        id: json['id'] as String,
        amount: (json['amount'] as num).toDouble(),
        date: DateTime.parse(json['date'] as String),
        note: json['note'] as String?,
      );
}

class DebtEntry {
  final String id;
  final String personName;
  final String? phone;
  final DebtDirection direction;
  final double amount;
  final String? reason;
  final DateTime date;
  final DateTime? dueDate;
  final bool isSettled;
  final List<DebtSettlement> settlements;

  const DebtEntry({
    required this.id,
    required this.personName,
    this.phone,
    required this.direction,
    required this.amount,
    this.reason,
    required this.date,
    this.dueDate,
    this.isSettled = false,
    this.settlements = const [],
  });

  double get totalSettled =>
      settlements.fold(0.0, (sum, s) => sum + s.amount);

  double get pendingAmount => (amount - totalSettled).clamp(0, double.infinity);

  double get settledPercent =>
      amount > 0 ? (totalSettled / amount).clamp(0.0, 1.0) : 0;

  bool get isFullySettled => pendingAmount <= 0;

  int? get daysLeft {
    if (dueDate == null) return null;
    return dueDate!.difference(DateTime.now()).inDays;
  }

  bool get isOverdue => dueDate != null && dueDate!.isBefore(DateTime.now()) && !isFullySettled;

  DebtEntry copyWith({
    String? id,
    String? personName,
    String? phone,
    DebtDirection? direction,
    double? amount,
    String? reason,
    DateTime? date,
    DateTime? dueDate,
    bool? isSettled,
    List<DebtSettlement>? settlements,
  }) => DebtEntry(
        id: id ?? this.id,
        personName: personName ?? this.personName,
        phone: phone ?? this.phone,
        direction: direction ?? this.direction,
        amount: amount ?? this.amount,
        reason: reason ?? this.reason,
        date: date ?? this.date,
        dueDate: dueDate ?? this.dueDate,
        isSettled: isSettled ?? this.isSettled,
        settlements: settlements ?? this.settlements,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'personName': personName,
        'phone': phone,
        'direction': direction.index,
        'amount': amount,
        'reason': reason,
        'date': date.toIso8601String(),
        'dueDate': dueDate?.toIso8601String(),
        'isSettled': isSettled,
        'settlements': settlements.map((s) => s.toJson()).toList(),
      };

  factory DebtEntry.fromJson(Map<String, dynamic> json) => DebtEntry(
        id: json['id'] as String,
        personName: json['personName'] as String,
        phone: json['phone'] as String?,
        direction: DebtDirection.values[(json['direction'] as int).clamp(0, 1)],
        amount: (json['amount'] as num).toDouble(),
        reason: json['reason'] as String?,
        date: DateTime.parse(json['date'] as String),
        dueDate: json['dueDate'] != null
            ? DateTime.parse(json['dueDate'] as String)
            : null,
        isSettled: json['isSettled'] as bool? ?? false,
        settlements: (json['settlements'] as List<dynamic>?)
                ?.map((s) => DebtSettlement.fromJson(s as Map<String, dynamic>))
                .toList() ??
            [],
      );
}
