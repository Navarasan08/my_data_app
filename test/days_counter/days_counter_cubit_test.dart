import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_data_app/src/core/sync/sync_snapshot.dart';
import 'package:my_data_app/src/days_counter/cubit/days_counter_cubit.dart';
import 'package:my_data_app/src/days_counter/model/days_counter_model.dart';
import 'package:my_data_app/src/days_counter/repository/days_counter_repository.dart';

DaysCounterEventType type(String id) => DaysCounterEventType(
  id: id,
  displayName: 'Type $id',
  iconIndex: 0,
  colorIndex: 0,
);

DaysCounterEvent event(String id, {String title = 'Event'}) {
  final now = DateTime.now();
  return DaysCounterEvent(
    id: id,
    title: '$title $id',
    eventType: type('t1'),
    date: DateTime(now.year + 1, 1, 1),
    recurrence: DaysCounterRecurrence.yearly,
    createdAt: now,
    updatedAt: now,
  );
}

const seedIds = [
  'birthday',
  'death_anniversary',
  'festival',
  'wedding_anniversary',
];

void main() {
  late FakeFirebaseFirestore fs;
  late FirestoreDaysCounterRepository repo;
  late DaysCounterCubit cubit;

  setUp(() {
    fs = FakeFirebaseFirestore();
    repo = FirestoreDaysCounterRepository(uid: 'u1', firestore: fs)..start();
    cubit = DaysCounterCubit(repo);
  });

  tearDown(() async {
    await cubit.close();
    await repo.dispose();
  });

  Future<List<String>> storedTypeIds() async {
    final snap = await fs
        .collection('users')
        .doc('u1')
        .collection('days_counter_event_types')
        .get();
    return snap.docs.map((d) => d.id).toList()..sort();
  }

  Future<bool> seededFlag() async {
    final snap = await fs
        .collection('users')
        .doc('u1')
        .collection('days_counter_settings')
        .doc('prefs')
        .get();
    return (snap.data()?['typesSeeded'] as bool?) ?? false;
  }

  test('starts in the loading state', () {
    expect(cubit.state.syncStatus, SyncStatus.loading);
    expect(cubit.state.isLive, isFalse);
  });

  test('loads existing events and reports live', () async {
    await fs
        .collection('users')
        .doc('u1')
        .collection('days_counter_events')
        .doc('e1')
        .set(event('e1').toJson());
    await pumpEventQueue();
    expect(cubit.state.isLive, isTrue);
    expect(cubit.state.events.map((e) => e.id), ['e1']);
  });

  test('seeds default event types once on a fresh account', () async {
    await pumpEventQueue();
    expect(cubit.state.eventTypes.map((t) => t.id).toList()..sort(), seedIds);
    expect(await storedTypeIds(), seedIds);
    expect(await seededFlag(), isTrue);

    // Deleting a seeded type must not bring it back.
    cubit.deleteEventType('festival');
    await pumpEventQueue();
    expect(cubit.state.eventTypes, hasLength(3));
    expect(await storedTypeIds(), isNot(contains('festival')));
  });

  test('does not seed when the flag is already set', () async {
    final other = FakeFirebaseFirestore();
    await other
        .collection('users')
        .doc('u2')
        .collection('days_counter_settings')
        .doc('prefs')
        .set({'typesSeeded': true});
    final repo2 = FirestoreDaysCounterRepository(uid: 'u2', firestore: other)
      ..start();
    final cubit2 = DaysCounterCubit(repo2);
    addTearDown(() async {
      await cubit2.close();
      await repo2.dispose();
    });

    await pumpEventQueue();
    expect(cubit2.state.isLive, isTrue);
    expect(cubit2.state.eventTypes, isEmpty);
    final snap = await other
        .collection('users')
        .doc('u2')
        .collection('days_counter_event_types')
        .get();
    expect(snap.docs, isEmpty);
  });

  test('add / update / delete events are immediate and persisted', () async {
    await pumpEventQueue();
    cubit.addEvent(event('e1'));
    expect(cubit.state.events, hasLength(1));

    cubit.updateEvent(event('e1', title: 'Renamed'));
    expect(cubit.state.events.single.title, 'Renamed e1');

    await pumpEventQueue();
    final stored = await fs
        .collection('users')
        .doc('u1')
        .collection('days_counter_events')
        .doc('e1')
        .get();
    expect(stored.data()!['title'], 'Renamed e1');

    cubit.deleteEvent('e1');
    expect(cubit.state.events, isEmpty);
    await pumpEventQueue();
    expect(cubit.state.events, isEmpty);
  });

  test('updating a type rewrites the snapshot embedded in events', () async {
    await pumpEventQueue();
    cubit.addEventType(type('t1'));
    cubit.addEvent(event('e1'));
    cubit.updateEventType(type('t1').copyWith(displayName: 'Renamed'));
    expect(cubit.state.events.single.eventType.displayName, 'Renamed');
    await pumpEventQueue();
    expect(cubit.state.events.single.eventType.displayName, 'Renamed');
  });

  test(
    'edits from elsewhere (another device) arrive without a refresh',
    () async {
      await pumpEventQueue();
      await fs
          .collection('users')
          .doc('u1')
          .collection('days_counter_events')
          .doc('remote')
          .set(event('remote').toJson());
      await pumpEventQueue();
      expect(cubit.state.events.map((e) => e.id), ['remote']);
    },
  );
}
