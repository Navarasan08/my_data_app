import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_data_app/src/core/sync/sync_snapshot.dart';
import 'package:my_data_app/src/loans/cubit/loan_cubit.dart';
import 'package:my_data_app/src/loans/model/loan_model.dart';
import 'package:my_data_app/src/loans/repository/loan_repository.dart';

Loan loan(String id, {double emi = 900}) {
  final now = DateTime.now();
  return Loan(
    id: id,
    name: 'Loan $id',
    type: LoanType.personal,
    principalAmount: 10000,
    interestRate: 10,
    tenureMonths: 12,
    emiAmount: emi,
    // Current month so addLoan does not auto-generate past EMIs.
    startDate: DateTime(now.year, now.month, 1),
  );
}

void main() {
  late FakeFirebaseFirestore fs;
  late FirestoreLoanRepository repo;
  late LoanCubit cubit;

  setUp(() {
    fs = FakeFirebaseFirestore();
    repo = FirestoreLoanRepository(uid: 'u1', firestore: fs)..start();
    cubit = LoanCubit(repo);
  });

  tearDown(() async {
    await cubit.close();
    await repo.dispose();
  });

  test('starts in the loading state', () {
    expect(cubit.state.syncStatus, SyncStatus.loading);
    expect(cubit.state.isLive, isFalse);
  });

  test('loads existing loans and reports live', () async {
    await fs
        .collection('users')
        .doc('u1')
        .collection('loans')
        .doc('l1')
        .set(loan('l1').toJson());
    await pumpEventQueue();
    expect(cubit.state.isLive, isTrue);
    expect(cubit.state.loans.map((l) => l.id), ['l1']);
  });

  test('add / update / delete are immediate and persisted', () async {
    await pumpEventQueue();
    cubit.addLoan(loan('l1'));
    expect(cubit.state.loans, hasLength(1));

    cubit.updateLoan(loan('l1', emi: 950));
    expect(cubit.state.loans.single.emiAmount, 950);

    await pumpEventQueue();
    final stored = await fs
        .collection('users')
        .doc('u1')
        .collection('loans')
        .doc('l1')
        .get();
    expect(stored.data()!['emiAmount'], 950);

    cubit.deleteLoan('l1');
    expect(cubit.state.loans, isEmpty);
    await pumpEventQueue();
    expect(cubit.state.loans, isEmpty);
  });

  test(
    'edits from elsewhere (another device) arrive without a refresh',
    () async {
      await pumpEventQueue();
      await fs
          .collection('users')
          .doc('u1')
          .collection('loans')
          .doc('remote')
          .set(loan('remote').toJson());
      await pumpEventQueue();
      expect(cubit.state.loans.map((l) => l.id), ['remote']);
    },
  );
}
