import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_data_app/src/core/sync/sync_snapshot.dart';
import 'package:my_data_app/src/money_owe/cubit/money_owe_cubit.dart';
import 'package:my_data_app/src/money_owe/model/money_owe_model.dart';
import 'package:my_data_app/src/money_owe/repository/money_owe_repository.dart';

DebtEntry entry(String id, {double amount = 500}) => DebtEntry(
  id: id,
  personName: 'Person $id',
  direction: DebtDirection.lent,
  amount: amount,
  date: DateTime.now(),
);

void main() {
  late FakeFirebaseFirestore fs;
  late FirestoreMoneyOweRepository repo;
  late MoneyOweCubit cubit;

  setUp(() {
    fs = FakeFirebaseFirestore();
    repo = FirestoreMoneyOweRepository(uid: 'u1', firestore: fs)..start();
    cubit = MoneyOweCubit(repo);
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
        .collection('money_owe')
        .doc('e1')
        .set(entry('e1').toJson());
    await pumpEventQueue();
    expect(cubit.state.isLive, isTrue);
    expect(cubit.state.entries.map((e) => e.id), ['e1']);
  });

  test('add / update / delete are immediate and persisted', () async {
    await pumpEventQueue();
    cubit.addEntry(entry('e1'));
    expect(cubit.state.entries, hasLength(1));

    cubit.updateEntry(entry('e1', amount: 750));
    expect(cubit.state.entries.single.amount, 750);

    await pumpEventQueue();
    final stored = await fs
        .collection('users')
        .doc('u1')
        .collection('money_owe')
        .doc('e1')
        .get();
    expect(stored.data()!['amount'], 750);

    cubit.deleteEntry('e1');
    expect(cubit.state.entries, isEmpty);
    await pumpEventQueue();
    expect(cubit.state.entries, isEmpty);
  });

  test(
    'edits from elsewhere (another device) arrive without a refresh',
    () async {
      await pumpEventQueue();
      await fs
          .collection('users')
          .doc('u1')
          .collection('money_owe')
          .doc('remote')
          .set(entry('remote').toJson());
      await pumpEventQueue();
      expect(cubit.state.entries.map((e) => e.id), ['remote']);
    },
  );
}
