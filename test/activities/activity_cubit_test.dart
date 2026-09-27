import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_data_app/src/activities/cubit/activity_cubit.dart';
import 'package:my_data_app/src/activities/model/activity_model.dart';
import 'package:my_data_app/src/activities/repository/activity_repository.dart';
import 'package:my_data_app/src/core/sync/sync_snapshot.dart';

ActivityRecord record(String id, {String? title}) {
  final now = DateTime.now();
  return ActivityRecord(
    id: id,
    title: title ?? 'Activity $id',
    category: ActivityCategory.trip,
    startDate: now,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late FakeFirebaseFirestore fs;
  late FirestoreActivityRepository repo;
  late ActivityCubit cubit;

  setUp(() {
    fs = FakeFirebaseFirestore();
    repo = FirestoreActivityRepository(uid: 'u1', firestore: fs)..start();
    cubit = ActivityCubit(repo);
  });

  tearDown(() async {
    await cubit.close();
    await repo.dispose();
  });

  test('starts in the loading state', () {
    expect(cubit.state.syncStatus, SyncStatus.loading);
    expect(cubit.state.isLive, isFalse);
  });

  test('loads existing records and reports live', () async {
    await fs
        .collection('users')
        .doc('u1')
        .collection('activities')
        .doc('a1')
        .set(record('a1').toJson());
    await pumpEventQueue();
    expect(cubit.state.isLive, isTrue);
    expect(cubit.state.records.map((r) => r.id), ['a1']);
  });

  test('add / update / delete are immediate and persisted', () async {
    await pumpEventQueue();
    cubit.addRecord(record('a1'));
    expect(cubit.state.records, hasLength(1));

    cubit.updateRecord(record('a1', title: 'Renamed'));
    expect(cubit.state.records.single.title, 'Renamed');

    await pumpEventQueue();
    final stored = await fs
        .collection('users')
        .doc('u1')
        .collection('activities')
        .doc('a1')
        .get();
    expect(stored.data()!['title'], 'Renamed');

    cubit.deleteRecord('a1');
    expect(cubit.state.records, isEmpty);
    await pumpEventQueue();
    expect(cubit.state.records, isEmpty);
  });

  test(
    'edits from elsewhere (another device) arrive without a refresh',
    () async {
      await pumpEventQueue();
      await fs
          .collection('users')
          .doc('u1')
          .collection('activities')
          .doc('remote')
          .set(record('remote').toJson());
      await pumpEventQueue();
      expect(cubit.state.records.map((r) => r.id), ['remote']);
    },
  );
}
