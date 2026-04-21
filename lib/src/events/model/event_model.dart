import 'package:flutter/material.dart';

/// A user-defined "event fund" — e.g., a marriage, a trip, a junk project.
/// Each event owns a list of expenses (see [EventExpense]).
class EventFund {
  final String id;
  final String name;
  final String? description;
  final int iconIndex;
  final int colorIndex;
  final double? budget;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? eventDate;
  final bool isArchived;

  const EventFund({
    required this.id,
    required this.name,
    this.description,
    this.iconIndex = 0,
    this.colorIndex = 0,
    this.budget,
    required this.createdAt,
    required this.updatedAt,
    this.eventDate,
    this.isArchived = false,
  });

  IconData get icon =>
      availableIcons[iconIndex.clamp(0, availableIcons.length - 1)];
  Color get color =>
      availableColors[colorIndex.clamp(0, availableColors.length - 1)];

  static final List<IconData> availableIcons = [
    Icons.celebration_rounded,      // 0 - marriage / celebration
    Icons.flight_rounded,           // 1 - trip
    Icons.home_repair_service_rounded, // 2 - renovation
    Icons.construction_rounded,     // 3 - construction / junk
    Icons.school_rounded,           // 4 - education
    Icons.cake_rounded,             // 5 - birthday
    Icons.health_and_safety_rounded,// 6 - medical
    Icons.shopping_bag_rounded,     // 7 - shopping
    Icons.baby_changing_station_rounded, // 8 - baby
    Icons.business_center_rounded,  // 9 - business
    Icons.house_rounded,            // 10 - housewarming
    Icons.directions_car_rounded,   // 11 - vehicle purchase
    Icons.movie_rounded,            // 12 - entertainment
    Icons.card_giftcard_rounded,    // 13 - gifts
    Icons.restaurant_rounded,       // 14 - feast
    Icons.temple_hindu_rounded,     // 15 - pooja / religious
    Icons.event_rounded,            // 16 - generic event
    Icons.favorite_rounded,         // 17 - anniversary
    Icons.groups_rounded,           // 18 - group / family
    Icons.beach_access_rounded,     // 19 - vacation
  ];

  static final List<Color> availableColors = [
    Colors.deepPurple,
    Colors.pink,
    Colors.orange,
    Colors.brown,
    Colors.teal,
    Colors.amber,
    Colors.red,
    Colors.blue,
    Colors.cyan,
    Colors.indigo,
    Colors.green,
    Colors.deepOrange,
    Colors.purple,
    Colors.lightBlue,
  ];

  EventFund copyWith({
    String? id,
    String? name,
    String? description,
    int? iconIndex,
    int? colorIndex,
    double? budget,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? eventDate,
    bool? isArchived,
    bool clearBudget = false,
    bool clearEventDate = false,
  }) {
    return EventFund(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconIndex: iconIndex ?? this.iconIndex,
      colorIndex: colorIndex ?? this.colorIndex,
      budget: clearBudget ? null : (budget ?? this.budget),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      eventDate: clearEventDate ? null : (eventDate ?? this.eventDate),
      isArchived: isArchived ?? this.isArchived,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'iconIndex': iconIndex,
        'colorIndex': colorIndex,
        'budget': budget,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'eventDate': eventDate?.toIso8601String(),
        'isArchived': isArchived,
      };

  factory EventFund.fromJson(Map<String, dynamic> json) => EventFund(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        iconIndex: json['iconIndex'] as int? ?? 0,
        colorIndex: json['colorIndex'] as int? ?? 0,
        budget: (json['budget'] as num?)?.toDouble(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        eventDate: json['eventDate'] != null
            ? DateTime.parse(json['eventDate'] as String)
            : null,
        isArchived: json['isArchived'] as bool? ?? false,
      );
}

/// An expense entry belonging to a specific [EventFund].
class EventExpense {
  final String id;
  final String eventId;
  final String title;
  final double amount;
  final DateTime date;
  final String? category;     // free-text tag, user-defined per event
  final String? paidTo;       // vendor / person
  final String? paymentMode;  // cash / upi / card / bank transfer
  final String? notes;

  const EventExpense({
    required this.id,
    required this.eventId,
    required this.title,
    required this.amount,
    required this.date,
    this.category,
    this.paidTo,
    this.paymentMode,
    this.notes,
  });

  EventExpense copyWith({
    String? id,
    String? eventId,
    String? title,
    double? amount,
    DateTime? date,
    String? category,
    String? paidTo,
    String? paymentMode,
    String? notes,
  }) {
    return EventExpense(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      paidTo: paidTo ?? this.paidTo,
      paymentMode: paymentMode ?? this.paymentMode,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'eventId': eventId,
        'title': title,
        'amount': amount,
        'date': date.toIso8601String(),
        'category': category,
        'paidTo': paidTo,
        'paymentMode': paymentMode,
        'notes': notes,
      };

  factory EventExpense.fromJson(Map<String, dynamic> json) => EventExpense(
        id: json['id'] as String,
        eventId: json['eventId'] as String,
        title: json['title'] as String,
        amount: (json['amount'] as num).toDouble(),
        date: DateTime.parse(json['date'] as String),
        category: json['category'] as String?,
        paidTo: json['paidTo'] as String?,
        paymentMode: json['paymentMode'] as String?,
        notes: json['notes'] as String?,
      );
}

/// Common payment modes shown as suggestion chips.
const kPaymentModes = ['Cash', 'UPI', 'Debit Card', 'Credit Card', 'Bank Transfer', 'Cheque', 'Other'];
