import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_data_app/src/core/sync/sync_snapshot.dart';
import 'package:my_data_app/src/medical/cubit/medical_cubit.dart';
import 'package:my_data_app/src/medical/model/medical_model.dart';
import 'package:my_data_app/src/medical/repository/medical_repository.dart';

FamilyMember member(String id, {String name = 'Member'}) =>
    FamilyMember(id: id, name: name, relation: Relation.self);

MedicalRecord record(String id, {String memberId = 'm1', double? amount}) =>
    MedicalRecord(
      id: id,
      memberId: memberId,
      type: RecordType.consultation,
      title: 'Record $id',
      date: DateTime(2026, 1, 1),
      amount: amount,
    );

void main() {
  late FakeFirebaseFirestore fs;
  late FirestoreMedicalRepository repo;
  late MedicalCubit cubit;

  CollectionReference<Map<String, dynamic>> members() =>
      fs.collection('users').doc('u1').collection('family_members');
  CollectionReference<Map<String, dynamic>> records() =>
      fs.collection('users').doc('u1').collection('medical_records');

  setUp(() {
    fs = FakeFirebaseFirestore();
    repo = FirestoreMedicalRepository(uid: 'u1', firestore: fs)..start();
    cubit = MedicalCubit(repo);
  });

  tearDown(() async {
    await cubit.close();
    await repo.dispose();
  });

  test('starts in the loading state', () {
    expect(cubit.state.syncStatus, SyncStatus.loading);
    expect(cubit.state.isLive, isFalse);
  });

  test('loads existing members and records and reports live', () async {
    await members().doc('m1').set(member('m1').toJson());
    await records().doc('r1').set(record('r1').toJson());
    await pumpEventQueue();
    expect(cubit.state.isLive, isTrue);
    expect(cubit.state.members.map((m) => m.id), ['m1']);
    expect(cubit.state.records.map((r) => r.id), ['r1']);
  });

  test('member add / update / delete are immediate and persisted', () async {
    await pumpEventQueue();
    cubit.addMember(member('m1'));
    expect(cubit.state.members, hasLength(1));

    cubit.updateMember(member('m1', name: 'Renamed'));
    expect(cubit.state.members.single.name, 'Renamed');

    await pumpEventQueue();
    final stored = await members().doc('m1').get();
    expect(stored.data()!['name'], 'Renamed');

    cubit.deleteMember('m1');
    expect(cubit.state.members, isEmpty);
    await pumpEventQueue();
    expect(cubit.state.members, isEmpty);
    expect((await members().doc('m1').get()).exists, isFalse);
  });

  test('record add / update / delete are immediate and persisted', () async {
    await pumpEventQueue();
    cubit.addRecord(record('r1'));
    expect(cubit.state.records, hasLength(1));

    cubit.updateRecord(record('r1', amount: 250));
    expect(cubit.state.records.single.amount, 250);

    await pumpEventQueue();
    final stored = await records().doc('r1').get();
    expect(stored.data()!['amount'], 250);

    cubit.deleteRecord('r1');
    expect(cubit.state.records, isEmpty);
    await pumpEventQueue();
    expect(cubit.state.records, isEmpty);
    expect((await records().doc('r1').get()).exists, isFalse);
  });

  test('deleting a member also deletes their records', () async {
    await pumpEventQueue();
    cubit.addMember(member('m1'));
    cubit.addMember(member('m2'));
    cubit.addRecord(record('r1', memberId: 'm1'));
    cubit.addRecord(record('r2', memberId: 'm2'));

    cubit.deleteMember('m1');
    expect(cubit.state.members.map((m) => m.id), ['m2']);
    expect(cubit.state.records.map((r) => r.id), ['r2']);

    await pumpEventQueue();
    expect(cubit.state.records.map((r) => r.id), ['r2']);
    expect((await records().doc('r1').get()).exists, isFalse);
  });

  test(
    'edits from elsewhere (another device) arrive without a refresh',
    () async {
      await pumpEventQueue();
      await members().doc('remote').set(member('remote').toJson());
      await records().doc('rr').set(record('rr', memberId: 'remote').toJson());
      await pumpEventQueue();
      expect(cubit.state.members.map((m) => m.id), ['remote']);
      expect(cubit.state.records.map((r) => r.id), ['rr']);
    },
  );
}
