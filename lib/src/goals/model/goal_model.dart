import 'package:flutter/material.dart';

enum GoalFrequency { daily, weekly, monthly, custom }

extension GoalFrequencyExt on GoalFrequency {
  String get label {
    switch (this) {
      case GoalFrequency.daily: return 'Daily';
      case GoalFrequency.weekly: return 'Weekly';
      case GoalFrequency.monthly: return 'Monthly';
      case GoalFrequency.custom: return 'Custom';
    }
  }

  IconData get icon {
    switch (this) {
      case GoalFrequency.daily: return Icons.today_rounded;
      case GoalFrequency.weekly: return Icons.view_week_rounded;
      case GoalFrequency.monthly: return Icons.calendar_month_rounded;
      case GoalFrequency.custom: return Icons.tune_rounded;
    }
  }
}

enum GoalCategory { health, fitness, learning, finance, productivity, habit, other }

extension GoalCategoryExt on GoalCategory {
  String get label {
    switch (this) {
      case GoalCategory.health: return 'Health';
      case GoalCategory.fitness: return 'Fitness';
      case GoalCategory.learning: return 'Learning';
      case GoalCategory.finance: return 'Finance';
      case GoalCategory.productivity: return 'Productivity';
      case GoalCategory.habit: return 'Habit';
      case GoalCategory.other: return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case GoalCategory.health: return Icons.favorite_rounded;
      case GoalCategory.fitness: return Icons.fitness_center_rounded;
      case GoalCategory.learning: return Icons.menu_book_rounded;
      case GoalCategory.finance: return Icons.savings_rounded;
      case GoalCategory.productivity: return Icons.rocket_launch_rounded;
      case GoalCategory.habit: return Icons.loop_rounded;
      case GoalCategory.other: return Icons.flag_rounded;
    }
  }

  Color get color {
    switch (this) {
      case GoalCategory.health: return Colors.red;
      case GoalCategory.fitness: return Colors.orange;
      case GoalCategory.learning: return Colors.blue;
      case GoalCategory.finance: return Colors.green;
      case GoalCategory.productivity: return Colors.purple;
      case GoalCategory.habit: return Colors.teal;
      case GoalCategory.other: return Colors.grey;
    }
  }
}

/// Status for a single tracked date
enum GoalDayStatus { success, failure, skip }

class GoalLog {
  final String date; // yyyy-MM-dd
  final GoalDayStatus status;
  final String? note;

  const GoalLog({required this.date, required this.status, this.note});

  Map<String, dynamic> toJson() => {
        'date': date,
        'status': status.index,
        'note': note,
      };

  factory GoalLog.fromJson(Map<String, dynamic> json) => GoalLog(
        date: json['date'] as String,
        status: GoalDayStatus.values[(json['status'] as int).clamp(0, 2)],
        note: json['note'] as String?,
      );
}

class Goal {
  final String id;
  final String title;
  final String? description;
  final GoalCategory category;
  final GoalFrequency frequency;
  final List<int>? customDays; // 1=Mon..7=Sun for custom
  final DateTime startDate;
  final DateTime? deadline;
  final bool isArchived;
  final List<GoalLog> logs;

  const Goal({
    required this.id,
    required this.title,
    this.description,
    required this.category,
    required this.frequency,
    this.customDays,
    required this.startDate,
    this.deadline,
    this.isArchived = false,
    this.logs = const [],
  });

  // ── Computed ────────────────────────────────────────────────────────────

  int get successCount =>
      logs.where((l) => l.status == GoalDayStatus.success).length;

  int get failureCount =>
      logs.where((l) => l.status == GoalDayStatus.failure).length;

  int get skipCount =>
      logs.where((l) => l.status == GoalDayStatus.skip).length;

  int get totalTracked => logs.length;

  double get successRate =>
      totalTracked > 0 ? successCount / totalTracked : 0;

  int get currentStreak {
    if (logs.isEmpty) return 0;
    final sorted = List<GoalLog>.from(logs)
      ..sort((a, b) => b.date.compareTo(a.date));
    int streak = 0;
    for (final log in sorted) {
      if (log.status == GoalDayStatus.success) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  int get longestStreak {
    if (logs.isEmpty) return 0;
    final sorted = List<GoalLog>.from(logs)
      ..sort((a, b) => a.date.compareTo(b.date));
    int longest = 0;
    int current = 0;
    for (final log in sorted) {
      if (log.status == GoalDayStatus.success) {
        current++;
        if (current > longest) longest = current;
      } else {
        current = 0;
      }
    }
    return longest;
  }

  GoalDayStatus? statusForDate(DateTime date) {
    final key = dateKey(date);
    final matches = logs.where((l) => l.date == key);
    return matches.isNotEmpty ? matches.first.status : null;
  }

  bool isDueForDate(DateTime date) {
    if (date.isBefore(DateTime(startDate.year, startDate.month, startDate.day))) {
      return false;
    }
    if (deadline != null && date.isAfter(deadline!)) return false;
    switch (frequency) {
      case GoalFrequency.daily:
        return true;
      case GoalFrequency.weekly:
        return date.weekday == startDate.weekday;
      case GoalFrequency.monthly:
        return date.day == startDate.day;
      case GoalFrequency.custom:
        return customDays?.contains(date.weekday) ?? false;
    }
  }

  int get daysLeft {
    if (deadline == null) return -1;
    return deadline!.difference(DateTime.now()).inDays;
  }

  static String dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Goal copyWith({
    String? id,
    String? title,
    String? description,
    GoalCategory? category,
    GoalFrequency? frequency,
    List<int>? customDays,
    DateTime? startDate,
    DateTime? deadline,
    bool? isArchived,
    List<GoalLog>? logs,
  }) => Goal(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        category: category ?? this.category,
        frequency: frequency ?? this.frequency,
        customDays: customDays ?? this.customDays,
        startDate: startDate ?? this.startDate,
        deadline: deadline ?? this.deadline,
        isArchived: isArchived ?? this.isArchived,
        logs: logs ?? this.logs,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category.index,
        'frequency': frequency.index,
        'customDays': customDays,
        'startDate': startDate.toIso8601String(),
        'deadline': deadline?.toIso8601String(),
        'isArchived': isArchived,
        'logs': logs.map((l) => l.toJson()).toList(),
      };

  factory Goal.fromJson(Map<String, dynamic> json) => Goal(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        category: GoalCategory.values[
            (json['category'] as int).clamp(0, GoalCategory.values.length - 1)],
        frequency: GoalFrequency.values[
            (json['frequency'] as int).clamp(0, GoalFrequency.values.length - 1)],
        customDays: (json['customDays'] as List<dynamic>?)?.cast<int>(),
        startDate: DateTime.parse(json['startDate'] as String),
        deadline: json['deadline'] != null
            ? DateTime.parse(json['deadline'] as String)
            : null,
        isArchived: json['isArchived'] as bool? ?? false,
        logs: (json['logs'] as List<dynamic>?)
                ?.map((l) => GoalLog.fromJson(l as Map<String, dynamic>))
                .toList() ??
            [],
      );
}
