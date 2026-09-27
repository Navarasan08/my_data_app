import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_data_app/src/core/sync/sync_snapshot.dart';
import 'package:my_data_app/src/interest/cubit/interest_cubit.dart';
import 'package:my_data_app/src/interest/model/interest_model.dart';
import 'package:my_data_app/src/interest/repository/interest_repository.dart';

InterestRecord record(String id, {double principal = 10000}) {
  final now = DateTime.now();
  return InterestRecord(
    id: id,
    direction: InterestDirection.lent,
    personName: 'Person $id',
    principal: principal,
    interestRate: 2,
    startDate: now,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late FakeFirebaseFirestore fs;
  late FirestoreInterestRepository repo;
  late InterestCubit cubit;

  setUp(() {
    fs = FakeFirebaseFirestore();
    repo = FirestoreInterestRepository(uid: 'u1', firestore: fs)..start();
    cubit = InterestCubit(repo);
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
        .collection('interest_records')
        .doc('i1')
        .set(record('i1').toJson());
    await pumpEventQueue();
    expect(cubit.state.isLive, isTrue);
    expect(cubit.state.records.map((r) => r.id), ['i1']);
  });

  test('add / update / delete are immediate and persisted', () async {
    await pumpEventQueue();
    cubit.addRecord(record('i1'));
    expect(cubit.state.records, hasLength(1));

    cubit.updateRecord(record('i1', principal: 15000));
    expect(cubit.state.records.single.principal, 15000);

    await pumpEventQueue();
    final stored = await fs
        .collection('users')
        .doc('u1')
        .collection('interest_records')
        .doc('i1')
        .get();
    expect(stored.data()!['principal'], 15000);

    cubit.deleteRecord('i1');
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
          .collection('interest_records')
          .doc('remote')
          .set(record('remote').toJson());
      await pumpEventQueue();
      expect(cubit.state.records.map((r) => r.id), ['remote']);
    },
  );
}
