import 'package:my_data_app/src/core/sync/sync_snapshot.dart';
import 'package:my_data_app/src/notifications/model/app_notification.dart';

class NotificationState {
  final List<AppNotification> items;

  /// Where [items] came from: `loading` before the first snapshot, `cached`
  /// until the server confirms, `live` after.
  final SyncStatus syncStatus;

  const NotificationState({
    required this.items,
    this.syncStatus = SyncStatus.loading,
  });

  bool get isLive => syncStatus.isLive;

  NotificationState copyWith({
    List<AppNotification>? items,
    SyncStatus? syncStatus,
  }) => NotificationState(
    items: items ?? this.items,
    syncStatus: syncStatus ?? this.syncStatus,
  );
}
