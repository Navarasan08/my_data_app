import 'package:flutter/material.dart';

enum MealType { breakfast, lunch, snack, dinner, custom }

extension MealTypeExt on MealType {
  String get label {
    switch (this) {
      case MealType.breakfast: return 'Breakfast';
      case MealType.lunch: return 'Lunch';
      case MealType.snack: return 'Snack';
      case MealType.dinner: return 'Dinner';
      case MealType.custom: return 'Custom';
    }
  }

  IconData get icon {
    switch (this) {
      case MealType.breakfast: return Icons.free_breakfast_rounded;
      case MealType.lunch: return Icons.lunch_dining_rounded;
      case MealType.snack: return Icons.cookie_rounded;
      case MealType.dinner: return Icons.dinner_dining_rounded;
      case MealType.custom: return Icons.add_circle_outline_rounded;
    }
  }

  Color get color {
    switch (this) {
      case MealType.breakfast: return Colors.orange;
      case MealType.lunch: return Colors.green;
      case MealType.snack: return Colors.purple;
      case MealType.dinner: return Colors.indigo;
      case MealType.custom: return Colors.teal;
    }
  }

  String get timeHint {
    switch (this) {
      case MealType.breakfast: return '7 – 9 AM';
      case MealType.lunch: return '12 – 2 PM';
      case MealType.snack: return '4 – 5 PM';
      case MealType.dinner: return '7 – 9 PM';
      case MealType.custom: return 'Any time';
    }
  }

  String get emoji {
    switch (this) {
      case MealType.breakfast: return '🍳';
      case MealType.lunch: return '🍛';
      case MealType.snack: return '🍪';
      case MealType.dinner: return '🍽️';
      case MealType.custom: return '⏰';
    }
  }

  /// Fixed meal types shown as slots on the page
  static List<MealType> get fixedTypes =>
      [MealType.breakfast, MealType.lunch, MealType.snack, MealType.dinner];
}

class MealEntry {
  final String id;
  final int weekday; // 1=Mon .. 7=Sun
  final MealType mealType;
  final String items; // comma-separated or free text
  final String? notes;
  final String? customLabel; // e.g. "Pre-workout", "Evening Juice"
  final int? timeHour; // 0-23, for custom entries
  final int? timeMinute; // 0-59

  const MealEntry({
    required this.id,
    required this.weekday,
    required this.mealType,
    required this.items,
    this.notes,
    this.customLabel,
    this.timeHour,
    this.timeMinute,
  });

  String get displayLabel =>
      customLabel != null && customLabel!.isNotEmpty
          ? customLabel!
          : mealType.label;

  String? get formattedTime {
    if (timeHour == null) return null;
    final h = timeHour! % 12 == 0 ? 12 : timeHour! % 12;
    final m = (timeMinute ?? 0).toString().padLeft(2, '0');
    final period = timeHour! < 12 ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  MealEntry copyWith({
    String? id,
    int? weekday,
    MealType? mealType,
    String? items,
    String? notes,
    String? customLabel,
    int? timeHour,
    int? timeMinute,
  }) {
    return MealEntry(
      id: id ?? this.id,
      weekday: weekday ?? this.weekday,
      mealType: mealType ?? this.mealType,
      items: items ?? this.items,
      notes: notes ?? this.notes,
      customLabel: customLabel ?? this.customLabel,
      timeHour: timeHour ?? this.timeHour,
      timeMinute: timeMinute ?? this.timeMinute,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'weekday': weekday,
        'mealType': mealType.index,
        'items': items,
        'notes': notes,
        'customLabel': customLabel,
        'timeHour': timeHour,
        'timeMinute': timeMinute,
      };

  factory MealEntry.fromJson(Map<String, dynamic> json) => MealEntry(
        id: json['id'] as String,
        weekday: json['weekday'] as int,
        mealType: MealType.values[(json['mealType'] as int)
            .clamp(0, MealType.values.length - 1)],
        items: json['items'] as String,
        notes: json['notes'] as String?,
        customLabel: json['customLabel'] as String?,
        timeHour: json['timeHour'] as int?,
        timeMinute: json['timeMinute'] as int?,
      );

  static String weekdayName(int weekday) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[(weekday - 1).clamp(0, 6)];
  }

  static String weekdayFullName(int weekday) {
    const names = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'
    ];
    return names[(weekday - 1).clamp(0, 6)];
  }
}
