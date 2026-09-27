import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_data_app/src/core/sync/sync_snapshot.dart';
import 'package:my_data_app/src/periods/cubit/period_cubit.dart';
import 'package:my_data_app/src/periods/model/period_model.dart';
import 'package:my_data_app/src/periods/repository/period_repository.dart';

PeriodEntry entry(String id, {DateTime? start, String? notes}) {
  final s = start ?? DateTime(2025, 1, 1);
  return PeriodEntry(
    id: id,
    startDate: s,
    endDate: s.add(const Duration(days: 4)),
    notes: notes,
  );
}

void main() {
  late FakeFirebaseFirestore fs;
  late FirestorePeriodRepository repo;
  late PeriodCubit cubit;

  setUp(() {
    fs = FakeFirebaseFirestore();
    repo = FirestorePeriodRepository(uid: 'u1', firestore: fs)..start();
    cubit = PeriodCubit(repo);
  });

  tearDown(() async {
    await cubit.close();
    await repo.dispose();
  });

  test('starts in the loading state', () {
    expect(cubit.state.syncStatus, SyncStatus.loading);
    expect(cubit.state.isLive, isFalse);
  });

  test('loads existing entries and reports live', () async {
    await fs
        .collection('users')
        .doc('u1')
        .collection('periods')
        .doc('p1')
        .set(entry('p1').toJson());
    await pumpEventQueue();
    expect(cubit.state.isLive, isTrue);
    expect(cubit.state.entries.map((e) => e.id), ['p1']);
  });

  test('add / update / delete are immediate and persisted', () async {
    await pumpEventQueue();
    cubit.addEntry(entry('p1'));
    expect(cubit.state.entries, hasLength(1));

    cubit.updateEntry(entry('p1', notes: 'heavy'));
    expect(cubit.state.entries.single.notes, 'heavy');

    await pumpEventQueue();
    final stored = await fs
        .collection('users')
        .doc('u1')
        .collection('periods')
        .doc('p1')
        .get();
    expect(stored.data()!['notes'], 'heavy');

    cubit.deleteEntry('p1');
    expect(cubit.state.entries, isEmpty);
    await pumpEventQueue();
    expect(cubit.state.entries, isEmpty);
  });

  test('changeMonth keeps entries and derived stats follow state', () async {
    await pumpEventQueue();
    cubit.addEntry(entry('p1', start: DateTime(2025, 1, 1)));
    cubit.addEntry(entry('p2', start: DateTime(2025, 1, 29)));
    expect(cubit.averageCycleLength, 28);

    final before = cubit.state.selectedMonth;
    cubit.changeMonth(1);
    expect(cubit.state.selectedMonth.month, (before.month % 12) + 1);
    expect(cubit.state.entries, hasLength(2));

    await pumpEventQueue();
    expect(cubit.state.entries, hasLength(2));
    expect(cubit.state.isLive, isTrue);
  });

  test(
    'edits from elsewhere (another device) arrive without a refresh',
    () async {
      await pumpEventQueue();
      await fs
          .collection('users')
          .doc('u1')
          .collection('periods')
          .doc('remote')
          .set(entry('remote').toJson());
      await pumpEventQueue();
      expect(cubit.state.entries.map((e) => e.id), ['remote']);
    },
  );
}
