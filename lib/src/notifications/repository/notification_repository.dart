import 'package:my_data_app/src/core/sync/single_collection_repository.dart';
import 'package:my_data_app/src/core/sync/sync_node.dart';
import 'package:my_data_app/src/notifications/model/app_notification.dart';

abstract class NotificationRepository implements SyncNode {
  List<AppNotification> getAll();
  void add(AppNotification n);
  void update(AppNotification n);
  void delete(String id);
  void deleteAll();
}

class FirestoreNotificationRepository
    extends SingleCollectionRepository<AppNotification>
    implements NotificationRepository {
  FirestoreNotificationRepository({required super.uid, super.firestore})
    : super(
        collectionName: 'notifications',
        fromDoc: (json, _) => AppNotification.fromJson(json),
        toJson: (n) => n.toJson(),
        idOf: (n) => n.id,
      );

  @override
  void add(AppNotification n) => store.save(n);

  @override
  void update(AppNotification n) => store.save(n);

  @override
  void delete(String id) => store.remove(id);

  @override
  void deleteAll() => store.removeWhere((_) => true);
}
