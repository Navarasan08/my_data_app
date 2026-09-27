import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_data_app/src/core/sync/sync_snapshot.dart';
import 'package:my_data_app/src/land/cubit/land_cubit.dart';
import 'package:my_data_app/src/land/model/land_model.dart';
import 'package:my_data_app/src/land/repository/land_repository.dart';

LandRecord record(String id, {String? name}) {
  final now = DateTime.now();
  return LandRecord(
    id: id,
    name: name ?? 'Land $id',
    type: LandType.residentialPlot,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late FakeFirebaseFirestore fs;
  late FirestoreLandRepository repo;
  late LandCubit cubit;

  setUp(() {
    fs = FakeFirebaseFirestore();
    repo = FirestoreLandRepository(uid: 'u1', firestore: fs)..start();
    cubit = LandCubit(repo);
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
        .collection('lands')
        .doc('r1')
        .set(record('r1').toJson());
    await pumpEventQueue();
    expect(cubit.state.isLive, isTrue);
    expect(cubit.state.records.map((r) => r.id), ['r1']);
  });

  test('add / update / delete are immediate and persisted', () async {
    await pumpEventQueue();
    cubit.addRecord(record('r1'));
    expect(cubit.state.records, hasLength(1));

    cubit.updateRecord(record('r1', name: 'Renamed'));
    expect(cubit.state.records.single.name, 'Renamed');

    await pumpEventQueue();
    final stored = await fs
        .collection('users')
        .doc('u1')
        .collection('lands')
        .doc('r1')
        .get();
    expect(stored.data()!['name'], 'Renamed');

    cubit.deleteRecord('r1');
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
          .collection('lands')
          .doc('remote')
          .set(record('remote').toJson());
      await pumpEventQueue();
      expect(cubit.state.records.map((r) => r.id), ['remote']);
    },
  );
}
