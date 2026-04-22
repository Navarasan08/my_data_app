import 'dart:async';

import 'package:my_data_app/src/notifications/cubit/notification_cubit.dart';
import 'package:my_data_app/src/notifications/model/app_notification.dart';
import 'package:my_data_app/src/notifications/reminder_source.dart';

/// Generic background sweeper that turns [ReminderSource]s into
/// [AppNotification]s on a fixed cadence.
///
/// Behavior is identical for every source:
///   * 2 days out → info notification
///   * 1 day out  → reminder notification
///   * today      → warning notification
///   * yesterday  → "missed" notification
///   * once an item is no longer pending (completed / deleted / out of window)
///     its notification is auto-dismissed
///
/// To plug in a new module, just implement [ReminderSource] and add an
/// instance to [sources]. No wiring changes required for the sweeper itself.
class ReminderSweeper {
  final List<ReminderSource> sources;
  final NotificationCubit notificationCubit;
  final Duration interval;

  Timer? _timer;
  final List<StreamSubscription<dynamic>> _subs = [];

  ReminderSweeper({
    required this.sources,
    required this.notificationCubit,
    this.interval = const Duration(hours: 8),
  });

  void start() {
    runNow();
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => runNow());
    for (final s in sources) {
      _subs.add(s.changes.listen((_) => runNow()));
    }
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    for (final sub in _subs) {
      sub.cancel();
    }
    _subs.clear();
  }

  /// Run a sweep across all sources right now.
  void runNow() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final twoDaysOut = today.add(const Duration(days: 2));

    // Track which dedupe keys are still active per module so we can clean
    // up notifications whose underlying item went away.
    final activeByModule = <String, Set<String>>{};

    for (final source in sources) {
      activeByModule[source.module] = <String>{};
      final pending = source.pendingIn(yesterday, twoDaysOut);
      for (final item in pending) {
        final due = DateTime(
            item.dueDate.year, item.dueDate.month, item.dueDate.day);
        final diff = due.difference(today).inDays;
        if (diff > 2 || diff < -1) continue;

        final notif = _buildNotification(source.module, item, diff);
        notificationCubit.push(notif);
        activeByModule[source.module]!.add(notif.dedupeKey);
      }
    }

    // Auto-resolve stale notifications for every module we actually swept.
    for (final entry in activeByModule.entries) {
      final stale = notificationCubit.state.items
          .where((n) =>
              n.sourceModule == entry.key &&
              !entry.value.contains(n.dedupeKey))
          .toList();
      for (final n in stale) {
        notificationCubit.dismiss(n.id);
      }
    }
  }

  AppNotification _buildNotification(
      String module, ReminderItem item, int diffDays) {
    String body;
    NotificationSeverity severity;

    switch (diffDays) {
      case 2:
        body = item.body ?? 'Coming up in 2 days';
        severity = NotificationSeverity.info;
        break;
      case 1:
        body = item.body ?? 'Tomorrow';
        severity = NotificationSeverity.reminder;
        break;
      case 0:
        body = item.body ?? 'Due today';
        severity = NotificationSeverity.warning;
        break;
      case -1:
        body = item.body ?? 'Missed yesterday';
        severity = NotificationSeverity.missed;
        break;
      default:
        body = item.body ?? '';
        severity = NotificationSeverity.info;
    }

    return AppNotification(
      id: '${module}_${item.itemId}_${item.dateKey}',
      title: item.title,
      body: body,
      sourceModule: module,
      sourceItemId: item.itemId,
      sourceDate: item.dateKey,
      severity: severity,
      createdAt: DateTime.now(),
      meta: item.meta,
    );
  }
}
