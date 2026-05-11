import 'package:flutter/material.dart';

/// A logged personal activity — a trip, a certificate application, an
/// achievement, etc. Stores when it happened (single date or range), an
/// optional description and location.
enum ActivityCategory {
  trip,
  certificate,
  achievement,
  family,
  health,
  career,
  education,
  other,
}

extension ActivityCategoryX on ActivityCategory {
  String get label {
    switch (this) {
      case ActivityCategory.trip:
        return 'Trip';
      case ActivityCategory.certificate:
        return 'Certificate';
      case ActivityCategory.achievement:
        return 'Achievement';
      case ActivityCategory.family:
        return 'Family';
      case ActivityCategory.health:
        return 'Health';
      case ActivityCategory.career:
        return 'Career';
      case ActivityCategory.education:
        return 'Education';
      case ActivityCategory.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case ActivityCategory.trip:
        return Icons.flight_rounded;
      case ActivityCategory.certificate:
        return Icons.workspace_premium_rounded;
      case ActivityCategory.achievement:
        return Icons.emoji_events_rounded;
      case ActivityCategory.family:
        return Icons.family_restroom_rounded;
      case ActivityCategory.health:
        return Icons.health_and_safety_rounded;
      case ActivityCategory.career:
        return Icons.work_rounded;
      case ActivityCategory.education:
        return Icons.school_rounded;
      case ActivityCategory.other:
        return Icons.bookmark_rounded;
    }
  }

  Color get color {
    switch (this) {
      case ActivityCategory.trip:
        return Colors.blue;
      case ActivityCategory.certificate:
        return Colors.amber;
      case ActivityCategory.achievement:
        return Colors.deepOrange;
      case ActivityCategory.family:
        return Colors.pink;
      case ActivityCategory.health:
        return Colors.red;
      case ActivityCategory.career:
        return Colors.indigo;
      case ActivityCategory.education:
        return Colors.purple;
      case ActivityCategory.other:
        return Colors.grey;
    }
  }
}

class ActivityRecord {
  final String id;
  final String title;
  final ActivityCategory category;
  final DateTime startDate;

  /// End date for multi-day activities (e.g. trips). `null` means single day.
  final DateTime? endDate;
  final String? description;
  final String? location;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ActivityRecord({
    required this.id,
    required this.title,
    required this.category,
    required this.startDate,
    this.endDate,
    this.description,
    this.location,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isMultiDay => endDate != null && !_sameDay(startDate, endDate!);

  int get durationDays {
    if (endDate == null) return 1;
    return endDate!.difference(startDate).inDays + 1;
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  ActivityRecord copyWith({
    String? title,
    ActivityCategory? category,
    DateTime? startDate,
    DateTime? endDate,
    bool clearEndDate = false,
    String? description,
    bool clearDescription = false,
    String? location,
    bool clearLocation = false,
    DateTime? updatedAt,
  }) {
    return ActivityRecord(
      id: id,
      title: title ?? this.title,
      category: category ?? this.category,
      startDate: startDate ?? this.startDate,
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      description:
          clearDescription ? null : (description ?? this.description),
      location: clearLocation ? null : (location ?? this.location),
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category.index,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'description': description,
        'location': location,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory ActivityRecord.fromJson(Map<String, dynamic> json) {
    final catIdx = (json['category'] as int? ?? 0)
        .clamp(0, ActivityCategory.values.length - 1);
    return ActivityRecord(
      id: json['id'] as String,
      title: json['title'] as String,
      category: ActivityCategory.values[catIdx],
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      description: json['description'] as String?,
      location: json['location'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
