import 'package:my_data_app/src/notifications/model/app_notification.dart';

class NotificationState {
  final List<AppNotification> items;

  const NotificationState({required this.items});

  NotificationState copyWith({List<AppNotification>? items}) =>
      NotificationState(items: items ?? this.items);
}
