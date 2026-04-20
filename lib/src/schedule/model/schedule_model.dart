import 'package:flutter/material.dart';

class ScheduleCategory {
  final String id;
  final String displayName;
  final int iconIndex;
  final int colorIndex;
  final bool isCustom;

  const ScheduleCategory({
    required this.id,
    required this.displayName,
    required this.iconIndex,
    required this.colorIndex,
    this.isCustom = false,
  });

  IconData get icon =>
      availableIcons[iconIndex.clamp(0, availableIcons.length - 1)];
  Color get color =>
      availableColors[colorIndex.clamp(0, availableColors.length - 1)];

  // Keep 'label' as an alias so existing UI code using cat.label keeps working
  String get label => displayName;

  static final List<IconData> availableIcons = [
    Icons.work_rounded,              // 0 - work
    Icons.person_rounded,            // 1 - personal
    Icons.favorite_rounded,          // 2 - health
    Icons.school_rounded,            // 3 - education
    Icons.flight_rounded,            // 4 - travel
    Icons.event_rounded,             // 5 - other / general
    Icons.fitness_center_rounded,    // 6 - fitness
    Icons.medical_services_rounded,  // 7 - medical
    Icons.restaurant_rounded,        // 8 - food
    Icons.shopping_cart_rounded,     // 9 - shopping
    Icons.home_rounded,              // 10 - home
    Icons.celebration_rounded,       // 11 - celebration
    Icons.sports_esports_rounded,    // 12 - hobby / gaming
    Icons.music_note_rounded,        // 13 - music
    Icons.movie_rounded,             // 14 - movie
    Icons.people_rounded,            // 15 - meeting
    Icons.phone_rounded,             // 16 - call
    Icons.video_call_rounded,        // 17 - video call
    Icons.flag_rounded,              // 18 - milestone
    Icons.cake_rounded,              // 19 - birthday
    Icons.card_giftcard_rounded,     // 20 - gift / anniversary
    Icons.self_improvement_rounded,  // 21 - meditation
    Icons.auto_stories_rounded,      // 22 - reading / study
    Icons.directions_car_rounded,    // 23 - vehicle / trip
    Icons.spa_rounded,               // 24 - beauty / wellness
  ];

  static final List<Color> availableColors = [
    Colors.blue,       // 0
    Colors.purple,     // 1
    Colors.red,        // 2
    Colors.teal,       // 3
    Colors.orange,     // 4
    Colors.grey,       // 5
    Colors.green,      // 6
    Colors.indigo,     // 7
    Colors.pink,       // 8
    Colors.cyan,       // 9
    Colors.amber,      // 10
    Colors.brown,      // 11
    Colors.deepPurple, // 12
    Colors.deepOrange, // 13
    Colors.lightBlue,  // 14
  ];

  // Default categories
  static const work = ScheduleCategory(
      id: 'work', displayName: 'Work', iconIndex: 0, colorIndex: 0);
  static const personal = ScheduleCategory(
      id: 'personal', displayName: 'Personal', iconIndex: 1, colorIndex: 1);
  static const health = ScheduleCategory(
      id: 'health', displayName: 'Health', iconIndex: 2, colorIndex: 2);
  static const education = ScheduleCategory(
      id: 'education', displayName: 'Education', iconIndex: 3, colorIndex: 3);
  static const travel = ScheduleCategory(
      id: 'travel', displayName: 'Travel', iconIndex: 4, colorIndex: 4);
  static const other = ScheduleCategory(
      id: 'other', displayName: 'Other', iconIndex: 5, colorIndex: 5);

  static final List<ScheduleCategory> defaults = [
    work,
    personal,
    health,
    education,
    travel,
    other,
  ];

  static ScheduleCategory findById(
      String id, List<ScheduleCategory> customCategories) {
    for (final c in defaults) {
      if (c.id == id) return c;
    }
    for (final c in customCategories) {
      if (c.id == id) return c;
    }
    // Fallback: preserve id so record can be remapped later
    return ScheduleCategory(
      id: id,
      displayName: id,
      iconIndex: 5,
      colorIndex: 5,
      isCustom: true,
    );
  }

  /// Legacy integer index support for records saved before categories became custom.
  static ScheduleCategory fromLegacyIndex(int index) {
    if (index >= 0 && index < defaults.length) return defaults[index];
    return other;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        'iconIndex': iconIndex,
        'colorIndex': colorIndex,
        'isCustom': isCustom,
      };

  factory ScheduleCategory.fromJson(Map<String, dynamic> json) =>
      ScheduleCategory(
        id: json['id'] as String,
        displayName: json['displayName'] as String,
        iconIndex: json['iconIndex'] as int,
        colorIndex: json['colorIndex'] as int,
        isCustom: json['isCustom'] as bool? ?? false,
      );

  @override
  bool operator ==(Object other) =>
      other is ScheduleCategory && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

enum RepeatMode {
  none,              // one-time
  weeklyOnDays,      // repeat on selected weekdays each week (customDays = 1..7)
  monthlyOnDays,     // repeat on selected days of month (customDays = 1..31)
  everyNDays,        // every N days
  everyNWeeks,       // every N weeks
  everyNMonths,      // every N months
}

extension RepeatModeExt on RepeatMode {
  String get label {
    switch (this) {
      case RepeatMode.none: return 'One-time';
      case RepeatMode.weeklyOnDays: return 'Weekly on days';
      case RepeatMode.monthlyOnDays: return 'Monthly on days';
      case RepeatMode.everyNDays: return 'Every N days';
      case RepeatMode.everyNWeeks: return 'Every N weeks';
      case RepeatMode.everyNMonths: return 'Every N months';
    }
  }

  String get shortLabel {
    switch (this) {
      case RepeatMode.none: return 'Once';
      case RepeatMode.weeklyOnDays: return 'Weekly';
      case RepeatMode.monthlyOnDays: return 'Monthly';
      case RepeatMode.everyNDays: return 'Days';
      case RepeatMode.everyNWeeks: return 'Weeks';
      case RepeatMode.everyNMonths: return 'Months';
    }
  }
}

class ScheduleEntry {
  final String id;
  final String title;
  final String? description;
  final DateTime startDate;        // date only
  final DateTime? endDate;         // optional; null = ongoing
  final ScheduleCategory category;
  final bool isCompleted;

  // Recurrence
  final RepeatMode repeatMode;
  final List<int>? customDays;     // weekly: 1..7; monthly: 1..31
  final int? interval;             // for everyN modes

  const ScheduleEntry({
    required this.id,
    required this.title,
    this.description,
    required this.startDate,
    this.endDate,
    required this.category,
    this.isCompleted = false,
    this.repeatMode = RepeatMode.none,
    this.customDays,
    this.interval,
  });

  bool get isRecurring => repeatMode != RepeatMode.none;

  List<DateTime> occurrencesInRange(DateTime rangeStart, DateTime rangeEnd) {
    final result = <DateTime>[];
    final start = _dateOnly(startDate);
    final rangeStartD = _dateOnly(rangeStart);
    final rangeEndD = _dateOnly(rangeEnd);

    if (repeatMode == RepeatMode.none) {
      if (!start.isBefore(rangeStartD) && !start.isAfter(rangeEndD)) {
        result.add(start);
      }
      return result;
    }

    DateTime searchEnd = rangeEndD;
    if (endDate != null) {
      final ed = _dateOnly(endDate!);
      if (ed.isBefore(searchEnd)) searchEnd = ed;
    }

    if (searchEnd.isBefore(start)) return result;

    int guard = 0;
    switch (repeatMode) {
      case RepeatMode.none:
        break;
      case RepeatMode.weeklyOnDays:
        {
          if (customDays == null || customDays!.isEmpty) return result;
          DateTime cursor = start;
          while (!cursor.isAfter(searchEnd) && guard < 20000) {
            guard++;
            if (customDays!.contains(cursor.weekday) &&
                !cursor.isBefore(rangeStartD)) {
              result.add(cursor);
            }
            cursor = cursor.add(const Duration(days: 1));
          }
        }
        break;
      case RepeatMode.monthlyOnDays:
        {
          if (customDays == null || customDays!.isEmpty) return result;
          DateTime cursor = start;
          while (!cursor.isAfter(searchEnd) && guard < 20000) {
            guard++;
            if (customDays!.contains(cursor.day) &&
                !cursor.isBefore(rangeStartD)) {
              result.add(cursor);
            }
            cursor = cursor.add(const Duration(days: 1));
          }
        }
        break;
      case RepeatMode.everyNDays:
        {
          final n = (interval ?? 1).clamp(1, 3650);
          DateTime cursor = start;
          while (!cursor.isAfter(searchEnd) && guard < 20000) {
            guard++;
            if (!cursor.isBefore(rangeStartD)) result.add(cursor);
            cursor = cursor.add(Duration(days: n));
          }
        }
        break;
      case RepeatMode.everyNWeeks:
        {
          final n = (interval ?? 1).clamp(1, 520);
          DateTime cursor = start;
          while (!cursor.isAfter(searchEnd) && guard < 20000) {
            guard++;
            if (!cursor.isBefore(rangeStartD)) result.add(cursor);
            cursor = cursor.add(Duration(days: 7 * n));
          }
        }
        break;
      case RepeatMode.everyNMonths:
        {
          final n = (interval ?? 1).clamp(1, 120);
          DateTime cursor = start;
          while (!cursor.isAfter(searchEnd) && guard < 20000) {
            guard++;
            if (!cursor.isBefore(rangeStartD)) result.add(cursor);
            cursor = DateTime(cursor.year, cursor.month + n, cursor.day);
          }
        }
        break;
    }

    return result;
  }

  String repeatLabel() {
    switch (repeatMode) {
      case RepeatMode.none:
        return '';
      case RepeatMode.weeklyOnDays:
        {
          if (customDays == null || customDays!.isEmpty) return 'Weekly';
          const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
          final sorted = List<int>.from(customDays!)..sort();
          final parts = sorted.map((d) => names[(d - 1).clamp(0, 6)]).toList();
          return 'Weekly • ${parts.join(", ")}';
        }
      case RepeatMode.monthlyOnDays:
        {
          if (customDays == null || customDays!.isEmpty) return 'Monthly';
          final sorted = List<int>.from(customDays!)..sort();
          return 'Monthly • ${sorted.join(", ")}';
        }
      case RepeatMode.everyNDays:
        {
          final n = interval ?? 1;
          return n == 1 ? 'Daily' : 'Every $n days';
        }
      case RepeatMode.everyNWeeks:
        {
          final n = interval ?? 1;
          return n == 1 ? 'Weekly' : 'Every $n weeks';
        }
      case RepeatMode.everyNMonths:
        {
          final n = interval ?? 1;
          return n == 1 ? 'Monthly' : 'Every $n months';
        }
    }
  }

  String endLabel() {
    if (endDate == null) return isRecurring ? ' • ongoing' : '';
    final e = endDate!;
    return ' • until ${e.day}/${e.month}/${e.year}';
  }

  ScheduleEntry copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    ScheduleCategory? category,
    bool? isCompleted,
    RepeatMode? repeatMode,
    List<int>? customDays,
    int? interval,
    bool clearEndDate = false,
    bool clearCustomDays = false,
    bool clearInterval = false,
  }) {
    return ScheduleEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
      repeatMode: repeatMode ?? this.repeatMode,
      customDays: clearCustomDays ? null : (customDays ?? this.customDays),
      interval: clearInterval ? null : (interval ?? this.interval),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        // Persist category by id so custom categories round-trip correctly
        'category': category.id,
        'isCompleted': isCompleted,
        'repeatMode': repeatMode.index,
        'customDays': customDays,
        'interval': interval,
      };

  factory ScheduleEntry.fromJson(
    Map<String, dynamic> json, {
    List<ScheduleCategory> customCategories = const [],
  }) {
    final startRaw =
        (json['startDate'] ?? json['dateTime']) as String?;
    final endRaw = (json['endDate'] ?? json['endTime']) as String?;

    RepeatMode mode = RepeatMode.none;
    if (json['repeatMode'] != null) {
      mode = RepeatMode.values[(json['repeatMode'] as int)
          .clamp(0, RepeatMode.values.length - 1)];
    } else if (json['repeatType'] != null) {
      final oldIdx = json['repeatType'] as int;
      switch (oldIdx) {
        case 1: mode = RepeatMode.everyNDays; break;
        case 2: mode = RepeatMode.weeklyOnDays; break;
        case 3: mode = RepeatMode.monthlyOnDays; break;
        case 4: mode = RepeatMode.monthlyOnDays; break;
        default: mode = RepeatMode.none;
      }
    }

    // Category: new format = string id, legacy = int index
    final catRaw = json['category'];
    ScheduleCategory category;
    if (catRaw is int) {
      category = ScheduleCategory.fromLegacyIndex(catRaw);
    } else if (catRaw is String) {
      category = ScheduleCategory.findById(catRaw, customCategories);
    } else {
      category = ScheduleCategory.other;
    }

    return ScheduleEntry(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      startDate: startRaw != null ? DateTime.parse(startRaw) : DateTime.now(),
      endDate: endRaw != null ? DateTime.parse(endRaw) : null,
      category: category,
      isCompleted: json['isCompleted'] as bool? ?? false,
      repeatMode: mode,
      customDays: (json['customDays'] as List<dynamic>?)?.cast<int>(),
      interval: json['interval'] as int?,
    );
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
