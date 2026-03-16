import 'package:flutter/material.dart';

enum ScheduleCategory { work, personal, health, education, travel, other }

extension ScheduleCategoryExt on ScheduleCategory {
  String get label {
    switch (this) {
      case ScheduleCategory.work: return 'Work';
      case ScheduleCategory.personal: return 'Personal';
      case ScheduleCategory.health: return 'Health';
      case ScheduleCategory.education: return 'Education';
      case ScheduleCategory.travel: return 'Travel';
      case ScheduleCategory.other: return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case ScheduleCategory.work: return Icons.work_rounded;
      case ScheduleCategory.personal: return Icons.person_rounded;
      case ScheduleCategory.health: return Icons.favorite_rounded;
      case ScheduleCategory.education: return Icons.school_rounded;
      case ScheduleCategory.travel: return Icons.flight_rounded;
      case ScheduleCategory.other: return Icons.event_rounded;
    }
  }

  Color get color {
    switch (this) {
      case ScheduleCategory.work: return Colors.blue;
      case ScheduleCategory.personal: return Colors.purple;
      case ScheduleCategory.health: return Colors.red;
      case ScheduleCategory.education: return Colors.teal;
      case ScheduleCategory.travel: return Colors.orange;
      case ScheduleCategory.other: return Colors.grey;
    }
  }
}

class ScheduleEntry {
  final String id;
  final String title;
  final String? description;
  final DateTime dateTime;
  final DateTime? endTime;
  final ScheduleCategory category;
  final bool isCompleted;

  const ScheduleEntry({
    required this.id,
    required this.title,
    this.description,
    required this.dateTime,
    this.endTime,
    required this.category,
    this.isCompleted = false,
  });

  ScheduleEntry copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dateTime,
    DateTime? endTime,
    ScheduleCategory? category,
    bool? isCompleted,
  }) {
    return ScheduleEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dateTime: dateTime ?? this.dateTime,
      endTime: endTime ?? this.endTime,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'dateTime': dateTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'category': category.index,
        'isCompleted': isCompleted,
      };

  factory ScheduleEntry.fromJson(Map<String, dynamic> json) => ScheduleEntry(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        dateTime: DateTime.parse(json['dateTime'] as String),
        endTime: json['endTime'] != null
            ? DateTime.parse(json['endTime'] as String)
            : null,
        category: ScheduleCategory.values[json['category'] as int],
        isCompleted: json['isCompleted'] as bool? ?? false,
      );
}
