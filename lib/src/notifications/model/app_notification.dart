import 'package:flutter/material.dart';

enum NotificationSeverity { info, reminder, warning, missed }

extension NotificationSeverityExt on NotificationSeverity {
  Color get color {
    switch (this) {
      case NotificationSeverity.info:
        return Colors.blue;
      case NotificationSeverity.reminder:
        return Colors.green;
      case NotificationSeverity.warning:
        return Colors.orange;
      case NotificationSeverity.missed:
        return Colors.red;
    }
  }

  IconData get icon {
    switch (this) {
      case NotificationSeverity.info:
        return Icons.info_outline_rounded;
      case NotificationSeverity.reminder:
        return Icons.notifications_rounded;
      case NotificationSeverity.warning:
        return Icons.warning_amber_rounded;
      case NotificationSeverity.missed:
        return Icons.error_outline_rounded;
    }
  }
}

/// A user-facing notification produced by some module.
///
/// The notifications module owns persistence, in-app display, and tap routing
/// — but it has no knowledge of the contents. Producers (e.g. the schedule
/// reminder service) push instances of this class.
class AppNotification {
  final String id;
  final String title;
  final String body;

  /// Identifies the originating module so we can route the tap, e.g.
  /// `'schedule'`, `'bills'`, `'goals'`.
  final String sourceModule;

  /// Identifies the specific item within that module, e.g. a schedule entry id.
  final String sourceItemId;

  /// Optional ISO date string, used when the source item has occurrences
  /// (recurring schedules etc.) so the same item can yield multiple
  /// notifications without colliding.
  final String? sourceDate;

  final NotificationSeverity severity;
  final DateTime createdAt;
  final bool isRead;
  final bool isDismissed;

  /// Free-form bag for routing extras (e.g. occurrence date object).
  final Map<String, String> meta;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.sourceModule,
    required this.sourceItemId,
    this.sourceDate,
    this.severity = NotificationSeverity.reminder,
    required this.createdAt,
    this.isRead = false,
    this.isDismissed = false,
    this.meta = const {},
  });

  /// Stable key used to dedupe notifications. Two notifications with the same
  /// (sourceModule, sourceItemId, sourceDate) are considered the same event.
  String get dedupeKey =>
      '$sourceModule:$sourceItemId:${sourceDate ?? ""}';

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    String? sourceModule,
    String? sourceItemId,
    String? sourceDate,
    NotificationSeverity? severity,
    DateTime? createdAt,
    bool? isRead,
    bool? isDismissed,
    Map<String, String>? meta,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      sourceModule: sourceModule ?? this.sourceModule,
      sourceItemId: sourceItemId ?? this.sourceItemId,
      sourceDate: sourceDate ?? this.sourceDate,
      severity: severity ?? this.severity,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      isDismissed: isDismissed ?? this.isDismissed,
      meta: meta ?? this.meta,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'sourceModule': sourceModule,
        'sourceItemId': sourceItemId,
        'sourceDate': sourceDate,
        'severity': severity.index,
        'createdAt': createdAt.toIso8601String(),
        'isRead': isRead,
        'isDismissed': isDismissed,
        'meta': meta,
      };

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        sourceModule: json['sourceModule'] as String,
        sourceItemId: json['sourceItemId'] as String,
        sourceDate: json['sourceDate'] as String?,
        severity: NotificationSeverity.values[
            (json['severity'] as int? ?? 1)
                .clamp(0, NotificationSeverity.values.length - 1)],
        createdAt: DateTime.parse(json['createdAt'] as String),
        isRead: json['isRead'] as bool? ?? false,
        isDismissed: json['isDismissed'] as bool? ?? false,
        meta: ((json['meta'] as Map?) ?? const {})
            .map((k, v) => MapEntry(k.toString(), v.toString())),
      );
}
