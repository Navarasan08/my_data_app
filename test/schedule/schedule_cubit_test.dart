import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_data_app/src/core/sync/sync_snapshot.dart';
import 'package:my_data_app/src/schedule/cubit/schedule_cubit.dart';
import 'package:my_data_app/src/schedule/model/schedule_model.dart';
import 'package:my_data_app/src/schedule/repository/schedule_repository.dart';

ScheduleEntry entry(
  String id, {
  String title = 'Task',
  ScheduleCategory category = ScheduleCategory.work,
}) {
  final now = DateTime.now();
  return ScheduleEntry(
    id: id,
    title: title,
    startDate: DateTime(now.year, now.month, now.day),
    category: category,
  );
}

ScheduleCategory category(String id, {String name = 'Custom'}) =>
    ScheduleCategory(
      id: id,
      displayName: name,
      iconIndex: 1,
      colorIndex: 1,
      isCustom: true,
    );

void main() {
  late FakeFirebaseFirestore fs;
  late FirestoreScheduleRepository repo;
  late ScheduleCubit cubit;

  CollectionReference<Map<String, dynamic>> entries() =>
      fs.collection('users').doc('u1').collection('schedules');
  CollectionReference<Map<String, dynamic>> categories() =>
      fs.collection('users').doc('u1').collection('schedule_categories');

  setUp(() {
    fs = FakeFirebaseFirestore();
    repo = FirestoreScheduleRepository(uid: 'u1', firestore: fs)..start();
    cubit = ScheduleCubit(repo);
  });

  tearDown(() async {
    await cubit.close();
    await repo.dispose();
  });

  test('starts in the loading state', () {
    expect(cubit.state.syncStatus, SyncStatus.loading);
    expect(cubit.state.isLive, isFalse);
  });

  test('loads existing entries and categories and reports live', () async {
    await categories().doc('c1').set(category('c1', name: 'Gym').toJson());
    await entries()
        .doc('e1')
        .set(entry('e1', category: category('c1')).toJson());
    await pumpEventQueue();
    expect(cubit.state.isLive, isTrue);
    expect(cubit.state.customCategories.map((c) => c.id), ['c1']);
    expect(cubit.state.entries.map((e) => e.id), ['e1']);
    // Entries are parsed with the custom categories from the other store.
    expect(cubit.state.entries.single.category.displayName, 'Gym');
  });

  test('entry add / update / delete are immediate and persisted', () async {
    await pumpEventQueue();
    cubit.addEntry(entry('e1'));
    expect(cubit.state.entries, hasLength(1));

    cubit.updateEntry(entry('e1', title: 'Renamed'));
    expect(cubit.state.entries.single.title, 'Renamed');

    await pumpEventQueue();
    final stored = await entries().doc('e1').get();
    expect(stored.data()!['title'], 'Renamed');

    cubit.deleteEntry('e1');
    expect(cubit.state.entries, isEmpty);
    await pumpEventQueue();
    expect(cubit.state.entries, isEmpty);
    expect((await entries().doc('e1').get()).exists, isFalse);
  });

  test('category add / update / delete are immediate and persisted', () async {
    await pumpEventQueue();
    cubit.addCustomCategory(category('c1'));
    expect(cubit.state.customCategories, hasLength(1));

    cubit.updateCustomCategory(category('c1', name: 'Fitness'));
    expect(cubit.state.customCategories.single.displayName, 'Fitness');

    await pumpEventQueue();
    final stored = await categories().doc('c1').get();
    expect(stored.data()!['displayName'], 'Fitness');

    cubit.deleteCustomCategory('c1');
    expect(cubit.state.customCategories, isEmpty);
    await pumpEventQueue();
    expect(cubit.state.customCategories, isEmpty);
    expect((await categories().doc('c1').get()).exists, isFalse);
  });

  test('entries show the renamed custom category', () async {
    await pumpEventQueue();
    cubit.addCustomCategory(category('c1', name: 'Gym'));
    cubit.addEntry(entry('e1', category: category('c1', name: 'Gym')));
    await pumpEventQueue();
    expect(cubit.state.entries.single.category.displayName, 'Gym');

    // Renamed locally: reflected synchronously.
    cubit.updateCustomCategory(category('c1', name: 'Fitness'));
    expect(cubit.state.entries.single.category.displayName, 'Fitness');

    // Renamed elsewhere (another device): re-parsed when the categories
    // listener fires, without the entry itself changing.
    await categories().doc('c1').set(category('c1', name: 'Yoga').toJson());
    await pumpEventQueue();
    expect(cubit.state.customCategories.single.displayName, 'Yoga');
    expect(cubit.state.entries.single.category.displayName, 'Yoga');
  });

  test('getAll is memoised until either store changes', () async {
    await pumpEventQueue();
    cubit.addEntry(entry('e1'));
    await pumpEventQueue();
    final first = repo.getAll();
    expect(identical(first, repo.getAll()), isTrue);

    cubit.addCustomCategory(category('c1'));
    expect(identical(first, repo.getAll()), isFalse);
  });

  test('corrupt entry docs are skipped', () async {
    await entries().doc('bad').set({'id': 'bad'});
    await entries().doc('e1').set(entry('e1').toJson());
    await pumpEventQueue();
    expect(cubit.state.entries.map((e) => e.id), ['e1']);
  });

  test(
    'edits from elsewhere (another device) arrive without a refresh',
    () async {
      await pumpEventQueue();
      await entries().doc('remote').set(entry('remote').toJson());
      await categories().doc('rc').set(category('rc').toJson());
      await pumpEventQueue();
      expect(cubit.state.entries.map((e) => e.id), ['remote']);
      expect(cubit.state.customCategories.map((c) => c.id), ['rc']);
    },
  );
}
