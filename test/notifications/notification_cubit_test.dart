import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_data_app/src/core/sync/sync_snapshot.dart';
import 'package:my_data_app/src/notifications/cubit/notification_cubit.dart';
import 'package:my_data_app/src/notifications/model/app_notification.dart';
import 'package:my_data_app/src/notifications/notification_service.dart';
import 'package:my_data_app/src/notifications/repository/notification_repository.dart';

AppNotification note(String id, {bool isRead = false}) => AppNotification(
  id: id,
  title: 'Note $id',
  body: 'Body $id',
  sourceModule: 'bills',
  sourceItemId: id,
  createdAt: DateTime.now(),
  isRead: isRead,
);

void main() {
  late FakeFirebaseFirestore fs;
  late FirestoreNotificationRepository repo;
  late NotificationCubit cubit;

  setUp(() {
    fs = FakeFirebaseFirestore();
    repo = FirestoreNotificationRepository(uid: 'u1', firestore: fs)..start();
    cubit = NotificationCubit(repo, LocalNotificationService());
  });

  tearDown(() async {
    await cubit.close();
    await repo.dispose();
  });

  Future<List<String>> storedIds() async {
    final snap = await fs
        .collection('users')
        .doc('u1')
        .collection('notifications')
        .get();
    return snap.docs.map((d) => d.id).toList()..sort();
  }

  test('starts in the loading state', () {
    expect(cubit.state.syncStatus, SyncStatus.loading);
    expect(cubit.state.isLive, isFalse);
  });

  test('loads existing notifications and reports live', () async {
    await fs
        .collection('users')
        .doc('u1')
        .collection('notifications')
        .doc('n1')
        .set(note('n1').toJson());
    await pumpEventQueue();
    expect(cubit.state.isLive, isTrue);
    expect(cubit.state.items.map((n) => n.id), ['n1']);
    expect(cubit.unreadCount, 1);
  });

  test('push / markRead / dismiss are immediate and persisted', () async {
    await pumpEventQueue();
    cubit.push(note('n1'));
    expect(cubit.state.items, hasLength(1));
    expect(cubit.unreadCount, 1);

    cubit.markRead('n1');
    expect(cubit.state.items.single.isRead, isTrue);
    expect(cubit.unreadCount, 0);

    await pumpEventQueue();
    final stored = await fs
        .collection('users')
        .doc('u1')
        .collection('notifications')
        .doc('n1')
        .get();
    expect(stored.data()!['isRead'], isTrue);

    cubit.dismiss('n1');
    expect(cubit.state.items, isEmpty);
    await pumpEventQueue();
    expect(cubit.state.items, isEmpty);
    expect(await storedIds(), isEmpty);
  });

  test('push dedupes on dedupeKey and keeps the original id', () async {
    await pumpEventQueue();
    cubit.push(note('n1'));
    cubit.push(note('n1').copyWith(id: 'other', body: 'updated'));
    await pumpEventQueue();
    expect(cubit.state.items, hasLength(1));
    expect(cubit.state.items.single.id, 'n1');
    expect(cubit.state.items.single.body, 'updated');
  });

  test('clearAll empties state and the store', () async {
    await pumpEventQueue();
    cubit.push(note('n1'));
    cubit.push(note('n2'));
    cubit.push(note('n3'));
    await pumpEventQueue();
    expect(await storedIds(), ['n1', 'n2', 'n3']);

    cubit.clearAll();
    expect(cubit.state.items, isEmpty);
    await pumpEventQueue();
    expect(cubit.state.items, isEmpty);
    expect(await storedIds(), isEmpty);
  });

  test(
    'edits from elsewhere (another device) arrive without a refresh',
    () async {
      await pumpEventQueue();
      await fs
          .collection('users')
          .doc('u1')
          .collection('notifications')
          .doc('remote')
          .set(note('remote').toJson());
      await pumpEventQueue();
      expect(cubit.state.items.map((n) => n.id), ['remote']);
    },
  );
}
