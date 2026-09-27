import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_data_app/src/core/sync/sync_snapshot.dart';
import 'package:my_data_app/src/home/home_record_model.dart';
import 'package:my_data_app/src/home/repository/home_record_repository.dart';

import 'home_test_fixtures.dart';

void main() {
  late FakeFirebaseFirestore fs;
  late FirestoreHomeRecordRepository repo;

  CollectionReference<Map<String, dynamic>> col(String name) =>
      fs.collection('users').doc(testUid).collection(name);

  setUp(() {
    fs = seededFirestore();
    repo = FirestoreHomeRecordRepository(uid: testUid, firestore: fs);
  });

  tearDown(() => repo.dispose());

  test('is loading before start, live with parsed data after', () async {
    await col(
      'home_categories',
    ).doc('cat_custom').set(customCategory().toJson());
    await col(
      'home_records',
    ).doc('r1').set(record(id: 'r1', category: customCategory()).toJson());
    await col('home_settings').doc('prefs').set({
      'currencyCode': 'USD',
      'monthlyStartDay': 5,
    }, SetOptions(merge: true));

    expect(repo.current.status, SyncStatus.loading);
    expect(repo.current.records, isEmpty);

    repo.start();
    await pumpEventQueue();

    final d = repo.current;
    expect(d.status, SyncStatus.live);
    expect(d.records.map((r) => r.id), ['r1']);
    // The custom category was resolved, not the id-only fallback.
    expect(d.records.single.category.displayName, 'Gym');
    expect(d.customCategories.map((c) => c.id), ['cat_custom']);
    expect(d.settings.currencyCode, 'USD');
    expect(d.settings.monthlyStartDay, 5);
  });

  test('add / update / delete come back through the stream', () async {
    repo.start();
    await pumpEventQueue();
    expect(repo.current.records, isEmpty);

    repo.add(record(id: 'r1', title: 'Tea'));
    await pumpEventQueue();
    expect(repo.current.records.single.title, 'Tea');

    repo.update(record(id: 'r1', title: 'Chai', amount: 40));
    await pumpEventQueue();
    expect(repo.current.records.single.title, 'Chai');
    expect(repo.current.records.single.amount, 40);

    repo.delete('r1');
    await pumpEventQueue();
    expect(repo.current.records, isEmpty);
  });

  test('renaming a category re-parses every record that uses it', () async {
    await col(
      'home_categories',
    ).doc('cat_custom').set(customCategory().toJson());
    await col(
      'home_records',
    ).doc('r1').set(record(id: 'r1', category: customCategory()).toJson());
    await col(
      'home_records',
    ).doc('r2').set(record(id: 'r2', category: customCategory()).toJson());
    repo.start();
    await pumpEventQueue();
    expect(
      repo.current.records.every((r) => r.category.displayName == 'Gym'),
      isTrue,
    );

    repo.updateCustomCategory(customCategory(name: 'Fitness', colorIndex: 7));
    await pumpEventQueue();

    for (final r in repo.current.records) {
      expect(r.category.displayName, 'Fitness');
      expect(r.category.colorIndex, 7);
    }
  });

  test('settings setters persist and round-trip', () async {
    repo.start();
    await pumpEventQueue();

    repo.setCurrencyCode('EUR');
    repo.setShowMonthlyCalendar(false);
    repo.setMonthlyStartDay(25);
    repo.setWeekendAdjustment('previousFriday');
    repo.setIsCalendarView(true);
    await pumpEventQueue();

    final s = repo.current.settings;
    expect(s.currencyCode, 'EUR');
    expect(s.showMonthlyCalendar, isFalse);
    expect(s.monthlyStartDay, 25);
    expect(s.weekendAdjustment, 'previousFriday');
    expect(s.isCalendarView, isTrue);
    // Merge semantics: the seeded flag written in setUp survived.
    expect(s.paymentTypesSeeded, isTrue);
  });

  test('payment types: add, update, delete', () async {
    repo.start();
    await pumpEventQueue();
    // Seeded flag is set, so the list starts empty (no auto-seed).
    expect(repo.current.paymentTypes, isEmpty);

    repo.addPaymentType(
      const PaymentType(
        id: 'wallet',
        displayName: 'Wallet',
        iconIndex: 0,
        colorIndex: 0,
      ),
    );
    await pumpEventQueue();
    expect(repo.current.paymentTypes.single.displayName, 'Wallet');

    repo.updatePaymentType(
      const PaymentType(
        id: 'wallet',
        displayName: 'E-Wallet',
        iconIndex: 1,
        colorIndex: 1,
      ),
    );
    await pumpEventQueue();
    expect(repo.current.paymentTypes.single.displayName, 'E-Wallet');

    repo.deletePaymentType('wallet');
    await pumpEventQueue();
    expect(repo.current.paymentTypes, isEmpty);
  });

  group('payment type seeding', () {
    test('seeds cash/upi/card once on a brand-new account', () async {
      fs = seededFirestore(paymentTypesSeeded: false);
      repo = FirestoreHomeRecordRepository(uid: testUid, firestore: fs);
      repo.start();
      await pumpEventQueue();

      expect(
        repo.current.paymentTypes.map((t) => t.id),
        unorderedEquals(['cash', 'upi', 'card']),
      );
      expect(repo.current.settings.paymentTypesSeeded, isTrue);

      // Deleting one afterwards must not trigger a re-seed.
      repo.deletePaymentType('cash');
      await pumpEventQueue();
      expect(
        repo.current.paymentTypes.map((t) => t.id),
        unorderedEquals(['upi', 'card']),
      );
    });

    test('does not seed when the account already has types', () async {
      fs = seededFirestore(paymentTypesSeeded: false);
      await fs
          .collection('users')
          .doc(testUid)
          .collection('home_payment_types')
          .doc('wallet')
          .set({'id': 'wallet', 'displayName': 'Wallet'});
      repo = FirestoreHomeRecordRepository(uid: testUid, firestore: fs);
      repo.start();
      await pumpEventQueue();

      expect(repo.current.paymentTypes.map((t) => t.id), ['wallet']);
    });
  });

  test('a corrupt record doc is skipped, the rest still load', () async {
    await col('home_records').doc('ok').set(record(id: 'ok').toJson());
    await col(
      'home_records',
    ).doc('broken').set({'id': 'broken', 'amount': 'x'});
    repo.start();
    await pumpEventQueue();

    expect(repo.current.status, SyncStatus.live);
    expect(repo.current.records.map((r) => r.id), ['ok']);
  });

  test('start is idempotent', () async {
    repo.start();
    repo.start();
    await pumpEventQueue();
    repo.add(record(id: 'r1'));
    await pumpEventQueue();
    expect(repo.current.records.length, 1);
  });
}
