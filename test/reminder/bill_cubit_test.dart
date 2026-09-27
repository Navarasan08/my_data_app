import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_data_app/src/core/sync/sync_snapshot.dart';
import 'package:my_data_app/src/reminder/cubit/bill_cubit.dart';
import 'package:my_data_app/src/reminder/model/bill_model.dart';
import 'package:my_data_app/src/reminder/repository/bill_repository.dart';

Bill bill(String id, {int day = 5, double amount = 100}) {
  final now = DateTime.now();
  return Bill(
    id: id,
    name: 'Bill $id',
    description: '',
    amount: amount,
    dueDate: DateTime(now.year, now.month, day),
    createdDate: now,
  );
}

void main() {
  late FakeFirebaseFirestore fs;
  late FirestoreBillRepository repo;
  late BillCubit cubit;

  setUp(() {
    fs = FakeFirebaseFirestore();
    repo = FirestoreBillRepository(uid: 'u1', firestore: fs)..start();
    cubit = BillCubit(repo);
  });

  tearDown(() async {
    await cubit.close();
    await repo.dispose();
  });

  test('starts in the loading state', () {
    expect(cubit.state.syncStatus, SyncStatus.loading);
    expect(cubit.state.isLive, isFalse);
  });

  test('loads existing bills and reports live', () async {
    await fs
        .collection('users')
        .doc('u1')
        .collection('bills')
        .doc('b1')
        .set(bill('b1').toJson());
    await pumpEventQueue();
    expect(cubit.state.isLive, isTrue);
    expect(cubit.state.bills.map((b) => b.id), ['b1']);
  });

  test('add / update / delete are immediate and persisted', () async {
    await pumpEventQueue();
    cubit.addBill(bill('b1'));
    expect(cubit.state.bills, hasLength(1));

    cubit.updateBill(bill('b1', amount: 250));
    expect(cubit.state.bills.single.amount, 250);

    await pumpEventQueue();
    final stored = await fs
        .collection('users')
        .doc('u1')
        .collection('bills')
        .doc('b1')
        .get();
    expect(stored.data()!['amount'], 250);

    cubit.deleteBill('b1');
    expect(cubit.state.bills, isEmpty);
    await pumpEventQueue();
    expect(cubit.state.bills, isEmpty);
  });

  test('togglePaidForMonth round-trips and keeps selectedMonth', () async {
    await pumpEventQueue();
    cubit.addBill(bill('b1'));
    cubit.changeMonth(-1);
    final month = cubit.state.selectedMonth;

    cubit.togglePaidForMonth('b1', month);
    await pumpEventQueue();
    expect(cubit.state.bills.single.isPaidForMonth(month), isTrue);
    expect(cubit.state.selectedMonth, month);

    cubit.togglePaidForMonth('b1', month);
    await pumpEventQueue();
    expect(cubit.state.bills.single.isPaidForMonth(month), isFalse);
  });

  test(
    'edits from elsewhere (another device) arrive without a refresh',
    () async {
      await pumpEventQueue();
      await fs
          .collection('users')
          .doc('u1')
          .collection('bills')
          .doc('remote')
          .set(bill('remote').toJson());
      await pumpEventQueue();
      expect(cubit.state.bills.map((b) => b.id), ['remote']);
    },
  );
}
