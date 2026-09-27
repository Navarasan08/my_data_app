import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_data_app/src/core/sync/sync_snapshot.dart';
import 'package:my_data_app/src/goals/cubit/goal_cubit.dart';
import 'package:my_data_app/src/goals/model/goal_model.dart';
import 'package:my_data_app/src/goals/repository/goal_repository.dart';

Goal goal(String id, {String? title, bool autoMark = false, int daysAgo = 0}) {
  final now = DateTime.now();
  return Goal(
    id: id,
    title: title ?? 'Goal $id',
    category: GoalCategory.habit,
    frequency: GoalFrequency.daily,
    startDate: DateTime(now.year, now.month, now.day - daysAgo),
    autoMarkFailures: autoMark,
  );
}

void main() {
  late FakeFirebaseFirestore fs;
  late FirestoreGoalRepository repo;
  late GoalCubit cubit;

  setUp(() {
    fs = FakeFirebaseFirestore();
    repo = FirestoreGoalRepository(uid: 'u1', firestore: fs)..start();
    cubit = GoalCubit(repo);
  });

  tearDown(() async {
    await cubit.close();
    await repo.dispose();
  });

  test('starts in the loading state', () {
    expect(cubit.state.syncStatus, SyncStatus.loading);
    expect(cubit.state.isLive, isFalse);
  });

  test('loads existing goals and reports live', () async {
    await fs
        .collection('users')
        .doc('u1')
        .collection('goals')
        .doc('g1')
        .set(goal('g1').toJson());
    await pumpEventQueue();
    expect(cubit.state.isLive, isTrue);
    expect(cubit.state.goals.map((g) => g.id), ['g1']);
  });

  test('add / update / delete are immediate and persisted', () async {
    await pumpEventQueue();
    cubit.addGoal(goal('g1'));
    expect(cubit.state.goals, hasLength(1));

    cubit.updateGoal(goal('g1', title: 'Renamed'));
    expect(cubit.state.goals.single.title, 'Renamed');

    await pumpEventQueue();
    final stored = await fs
        .collection('users')
        .doc('u1')
        .collection('goals')
        .doc('g1')
        .get();
    expect(stored.data()!['title'], 'Renamed');

    cubit.deleteGoal('g1');
    expect(cubit.state.goals, isEmpty);
    await pumpEventQueue();
    expect(cubit.state.goals, isEmpty);
  });

  test(
    'edits from elsewhere (another device) arrive without a refresh',
    () async {
      await pumpEventQueue();
      await fs
          .collection('users')
          .doc('u1')
          .collection('goals')
          .doc('remote')
          .set(goal('remote').toJson());
      await pumpEventQueue();
      expect(cubit.state.goals.map((g) => g.id), ['remote']);
    },
  );

  test('autoMarkMissedFailures runs once data is live', () async {
    // Seed before the cubit exists so its first live snapshot already
    // contains a goal with three missed days.
    final fs2 = FakeFirebaseFirestore();
    final goals = fs2.collection('users').doc('u1').collection('goals');
    await goals.doc('g1').set(goal('g1', autoMark: true, daysAgo: 3).toJson());

    final repo2 = FirestoreGoalRepository(uid: 'u1', firestore: fs2)..start();
    final cubit2 = GoalCubit(repo2);
    addTearDown(() async {
      await cubit2.close();
      await repo2.dispose();
    });

    // Nothing to backfill while still loading.
    expect(cubit2.state.goals, isEmpty);

    await pumpEventQueue();
    expect(cubit2.state.isLive, isTrue);
    final marked = cubit2.state.goals.single;
    expect(marked.logs, hasLength(3));
    expect(marked.logs.every((l) => l.status == GoalDayStatus.failure), isTrue);
    final stored = await goals.doc('g1').get();
    expect(stored.data()!['logs'], hasLength(3));

    // The live-triggered pass runs only once per session: a goal arriving
    // later from another device is not backfilled by the listener alone.
    await goals.doc('g2').set(goal('g2', autoMark: true, daysAgo: 2).toJson());
    await pumpEventQueue();
    expect(cubit2.getGoalById('g2')!.logs, isEmpty);
  });
}
