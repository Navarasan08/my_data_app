import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_data_app/src/chits/cubit/chit_cubit.dart';
import 'package:my_data_app/src/chits/model/chit_model.dart';
import 'package:my_data_app/src/chits/repository/chit_repository.dart';
import 'package:my_data_app/src/core/sync/sync_snapshot.dart';

ChitFund chit(String id, {String name = 'Chit', List<Member>? members}) {
  return ChitFund(
    id: id,
    name: name,
    totalAmount: 100000,
    totalMembers: 20,
    durationMonths: 20,
    monthlyContribution: 5000,
    startDate: DateTime(2024, 1, 1),
    status: ChitStatus.active,
    members: members ?? const [],
  );
}

Member member(String id, {List<Payment>? payments}) {
  return Member(
    id: id,
    name: 'Member $id',
    joinedDate: DateTime(2024, 1, 1),
    payments: payments ?? const [],
  );
}

Payment payment(String id, {bool isPaid = false}) {
  return Payment(
    id: id,
    memberId: 'm1',
    monthNumber: 1,
    amount: 5000,
    dueDate: DateTime(2024, 1, 5),
    isPaid: isPaid,
  );
}

void main() {
  late FakeFirebaseFirestore fs;
  late FirestoreChitRepository repo;
  late ChitCubit cubit;

  setUp(() {
    fs = FakeFirebaseFirestore();
    repo = FirestoreChitRepository(uid: 'u1', firestore: fs)..start();
    cubit = ChitCubit(repo);
  });

  tearDown(() async {
    await cubit.close();
    await repo.dispose();
  });

  test('starts in the loading state', () {
    expect(cubit.state.syncStatus, SyncStatus.loading);
    expect(cubit.state.isLive, isFalse);
  });

  test('loads existing chit funds and reports live', () async {
    await fs
        .collection('users')
        .doc('u1')
        .collection('chits')
        .doc('c1')
        .set(chit('c1').toJson());
    await pumpEventQueue();
    expect(cubit.state.isLive, isTrue);
    expect(cubit.state.chitFunds.map((c) => c.id), ['c1']);
  });

  test('add / update / delete are immediate and persisted', () async {
    await pumpEventQueue();
    cubit.addChitFund(chit('c1'));
    expect(cubit.state.chitFunds, hasLength(1));

    cubit.updateChitFund(chit('c1', name: 'Renamed'));
    expect(cubit.state.chitFunds.single.name, 'Renamed');

    await pumpEventQueue();
    final stored = await fs
        .collection('users')
        .doc('u1')
        .collection('chits')
        .doc('c1')
        .get();
    expect(stored.data()!['name'], 'Renamed');

    cubit.deleteChitFund('c1');
    expect(cubit.state.chitFunds, isEmpty);
    await pumpEventQueue();
    expect(cubit.state.chitFunds, isEmpty);
  });

  test('togglePayment flips the first member payment and persists', () async {
    await pumpEventQueue();
    cubit.addChitFund(
      chit(
        'c1',
        members: [
          member('m1', payments: [payment('p1')]),
        ],
      ),
    );

    cubit.togglePayment('c1', 'p1');
    expect(
      cubit.state.chitFunds.single.members.first.payments.single.isPaid,
      isTrue,
    );

    await pumpEventQueue();
    final stored = await fs
        .collection('users')
        .doc('u1')
        .collection('chits')
        .doc('c1')
        .get();
    final members = stored.data()!['members'] as List<dynamic>;
    final payments = (members.first as Map)['payments'] as List<dynamic>;
    expect((payments.first as Map)['isPaid'], isTrue);

    cubit.togglePayment('c1', 'p1');
    await pumpEventQueue();
    expect(
      cubit.state.chitFunds.single.members.first.payments.single.isPaid,
      isFalse,
    );
  });

  test(
    'edits from elsewhere (another device) arrive without a refresh',
    () async {
      await pumpEventQueue();
      await fs
          .collection('users')
          .doc('u1')
          .collection('chits')
          .doc('remote')
          .set(chit('remote').toJson());
      await pumpEventQueue();
      expect(cubit.state.chitFunds.map((c) => c.id), ['remote']);
    },
  );
}
