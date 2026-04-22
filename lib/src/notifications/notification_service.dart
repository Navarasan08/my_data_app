import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:my_data_app/src/notifications/model/app_notification.dart';

/// Wrapper around `flutter_local_notifications` so the rest of the app
/// doesn't depend on plugin specifics.
///
/// Notification taps are routed through [onTap] (set by the app shell) — the
/// payload string passed back is `<sourceModule>|<sourceItemId>|<sourceDate?>`.
class LocalNotificationService {
  static const _androidChannelId = 'my_data_app_channel';
  static const _androidChannelName = 'My Data App';
  static const _androidChannelDesc = 'Reminders and alerts';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Set by [MainShell] to handle taps on local notifications.
  void Function(String payload)? onTap;

  bool _initialized = false;
  bool get supported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Future<void> init() async {
    if (_initialized || !supported) return;
    const androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (resp) {
        final payload = resp.payload;
        if (payload != null && onTap != null) onTap!(payload);
      },
    );

    // Android 13+ requires runtime permission; iOS always.
    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
    } else if (Platform.isIOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }

    _initialized = true;
  }

  /// Show (or refresh) an OS-level notification for [n].
  Future<void> show(AppNotification n) async {
    if (!supported) return;
    if (!_initialized) await init();

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _androidChannelId,
        _androidChannelName,
        channelDescription: _androidChannelDesc,
        importance: _importanceFor(n.severity),
        priority: _priorityFor(n.severity),
        color: n.severity.color,
      ),
      iOS: const DarwinNotificationDetails(),
    );

    final id = _stableInt(n.id);
    final payload = '${n.sourceModule}|${n.sourceItemId}|${n.sourceDate ?? ""}';

    try {
      await _plugin.show(
        id: id,
        title: n.title,
        body: n.body,
        notificationDetails: details,
        payload: payload,
      );
    } catch (_) {
      // swallow — notifications are best-effort
    }
  }

  Future<void> cancel(String notificationId) async {
    if (!supported) return;
    try {
      await _plugin.cancel(id: _stableInt(notificationId));
    } catch (_) {}
  }

  Future<void> cancelAll() async {
    if (!supported) return;
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }

  /// Map our string id → 32-bit int the plugin needs. Uses a stable hash so
  /// the same id always maps to the same int (so cancel() works).
  int _stableInt(String s) {
    final h = s.hashCode;
    return h.abs() & 0x7fffffff; // positive 31-bit int
  }

  Importance _importanceFor(NotificationSeverity s) {
    switch (s) {
      case NotificationSeverity.info:
        return Importance.low;
      case NotificationSeverity.reminder:
        return Importance.defaultImportance;
      case NotificationSeverity.warning:
        return Importance.high;
      case NotificationSeverity.missed:
        return Importance.max;
    }
  }

  Priority _priorityFor(NotificationSeverity s) {
    switch (s) {
      case NotificationSeverity.info:
        return Priority.low;
      case NotificationSeverity.reminder:
        return Priority.defaultPriority;
      case NotificationSeverity.warning:
        return Priority.high;
      case NotificationSeverity.missed:
        return Priority.max;
    }
  }
}
