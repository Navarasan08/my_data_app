import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_data_app/src/core/sync/sync_snapshot.dart';
import 'package:my_data_app/src/home/cubit/home_record_cubit.dart';
import 'package:my_data_app/src/home/cubit/home_record_state.dart';
import 'package:my_data_app/src/home/home_record_model.dart';
import 'package:my_data_app/src/home/repository/home_record_repository.dart';

import 'home_test_fixtures.dart';

void main() {
  late FakeFirebaseFirestore fs;
  late FirestoreHomeRecordRepository repo;
  late HomeRecordCubit cubit;

  setUp(() {
    fs = seededFirestore();
    repo = FirestoreHomeRecordRepository(uid: testUid, firestore: fs)..start();
    cubit = HomeRecordCubit(repo);
  });

  tearDown(() async {
    await cubit.close();
    await repo.dispose();
  });

  test('starts loading, becomes live once the repository reports', () async {
    // The repo was started in setUp but nothing has been pumped yet.
    expect(cubit.state.syncStatus, SyncStatus.loading);
    expect(cubit.state.isLoading, isTrue);

    await pumpEventQueue();
    expect(cubit.state.syncStatus, SyncStatus.live);
    expect(cubit.state.isLive, isTrue);
    expect(cubit.state.records, isEmpty);
  });

  test('record writes flow back into state', () async {
    await pumpEventQueue();

    cubit.addRecord(record(id: 'r1', title: 'Milk'));
    await pumpEventQueue();
    expect(cubit.state.records.single.title, 'Milk');

    cubit.updateRecord(record(id: 'r1', title: 'Curd'));
    await pumpEventQueue();
    expect(cubit.state.records.single.title, 'Curd');

    cubit.deleteRecord('r1');
    await pumpEventQueue();
    expect(cubit.state.records, isEmpty);
  });

  test('UI state survives data updates', () async {
    await pumpEventQueue();
    cubit.changeMonth(-2);
    cubit.setViewMode(HomeViewMode.all);
    final cat = HomeCategory.defaults.first;
    cubit.toggleCategory(cat);
    final selected = cubit.state.selectedDate;

    cubit.addRecord(record(id: 'r1'));
    await pumpEventQueue();

    expect(cubit.state.records.length, 1);
    expect(cubit.state.selectedDate, selected);
    expect(cubit.state.viewMode, HomeViewMode.all);
    expect(cubit.state.selectedCategoryIds, {cat.id});
  });

  test('settings toggles round-trip through the repository', () async {
    await pumpEventQueue();
    expect(cubit.state.isCalendarView, isFalse);

    cubit.toggleCalendarView();
    await pumpEventQueue();
    expect(cubit.state.isCalendarView, isTrue);

    cubit.setCurrency(HomeCurrency.usd);
    cubit.setMonthlyStartDay(45); // clamps to 31
    cubit.setWeekendAdjustment(WeekendAdjustment.followingMonday);
    cubit.setShowMonthlyCalendar(false);
    await pumpEventQueue();

    expect(cubit.state.currency, HomeCurrency.usd);
    expect(cubit.state.monthlyStartDay, 31);
    expect(cubit.state.weekendAdjustment, WeekendAdjustment.followingMonday);
    expect(cubit.state.showMonthlyCalendar, isFalse);
  });

  test('renaming a custom category updates records using it', () async {
    await pumpEventQueue();
    cubit.addCustomCategory(customCategory());
    cubit.addRecord(record(id: 'r1', category: customCategory()));
    await pumpEventQueue();
    expect(cubit.state.records.single.category.displayName, 'Gym');

    cubit.updateCustomCategory(customCategory(name: 'Fitness'));
    await pumpEventQueue();
    expect(cubit.state.customCategories.single.displayName, 'Fitness');
    expect(cubit.state.records.single.category.displayName, 'Fitness');
    expect(cubit.isCategoryInUse('cat_custom'), isTrue);
  });

  test(
    'updating a payment type rewrites the snapshot on its records',
    () async {
      await pumpEventQueue();
      const upi = PaymentType(
        id: 'upi',
        displayName: 'UPI',
        iconIndex: 1,
        colorIndex: 1,
      );
      cubit.addPaymentType(upi);
      cubit.addRecord(record(id: 'r1', paymentType: upi));
      cubit.addRecord(record(id: 'r2'));
      await pumpEventQueue();

      cubit.updatePaymentType(upi.copyWith(displayName: 'GPay'));
      await pumpEventQueue();

      final byId = {for (final r in cubit.state.records) r.id: r};
      expect(byId['r1']!.paymentType!.displayName, 'GPay');
      expect(byId['r2']!.paymentType, isNull);
      expect(cubit.state.paymentTypes.single.displayName, 'GPay');
      expect(cubit.isPaymentTypeInUse('upi'), isTrue);
    },
  );

  test('derived totals follow the live records', () async {
    await pumpEventQueue();
    final inMonth = DateTime(DateTime.now().year, DateTime.now().month, 10);
    cubit.addRecord(record(id: 'e1', amount: 100, date: inMonth));
    cubit.addRecord(record(id: 'e2', amount: 50, date: inMonth));
    cubit.addRecord(
      record(
        id: 'i1',
        amount: 900,
        date: inMonth,
        isIncome: true,
        category: HomeCategory.incomeDefaults.first,
      ),
    );
    await pumpEventQueue();

    expect(cubit.displayTotal, 150);
    expect(cubit.displayIncomeTotal, 900);
    expect(cubit.filteredRecords.length, 3);
    expect(cubit.dailyTotalsForSelectedCycle[inMonth], 150);
    expect(cubit.dailyIncomeForSelectedCycle[inMonth], 900);
  });

  test('close stops listening; later repo events do not throw', () async {
    await pumpEventQueue();
    await cubit.close();
    repo.add(record(id: 'r1'));
    await pumpEventQueue();
    // No exception, and the closed cubit kept its last state.
    expect(cubit.state.records, isEmpty);
  });
}
