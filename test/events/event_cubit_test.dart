import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_data_app/src/core/sync/sync_snapshot.dart';
import 'package:my_data_app/src/events/cubit/event_cubit.dart';
import 'package:my_data_app/src/events/model/event_model.dart';
import 'package:my_data_app/src/events/repository/event_repository.dart';

EventFund fund(String id, {String name = 'Event'}) {
  final now = DateTime.now();
  return EventFund(id: id, name: '$name $id', createdAt: now, updatedAt: now);
}

EventExpense expense(String id, String eventId, {double amount = 100}) =>
    EventExpense(
      id: id,
      eventId: eventId,
      title: 'Expense $id',
      amount: amount,
      date: DateTime.now(),
    );

void main() {
  late FakeFirebaseFirestore fs;
  late FirestoreEventRepository repo;
  late EventCubit cubit;

  setUp(() {
    fs = FakeFirebaseFirestore();
    repo = FirestoreEventRepository(uid: 'u1', firestore: fs)..start();
    cubit = EventCubit(repo);
  });

  tearDown(() async {
    await cubit.close();
    await repo.dispose();
  });

  Future<List<String>> storedExpenseIds(String eventId) async {
    final snap = await fs
        .collection('users')
        .doc('u1')
        .collection('events')
        .doc(eventId)
        .collection('expenses')
        .get();
    return snap.docs.map((d) => d.id).toList()..sort();
  }

  /// One pump for the event list, one for the expense listeners it attaches.
  Future<void> settle() async {
    await pumpEventQueue();
    await pumpEventQueue();
  }

  test('starts in the loading state', () {
    expect(cubit.state.syncStatus, SyncStatus.loading);
    expect(cubit.state.isLive, isFalse);
  });

  test('loads existing events with their expenses and reports live', () async {
    final events = fs.collection('users').doc('u1').collection('events');
    await events.doc('ev1').set(fund('ev1').toJson());
    await events
        .doc('ev1')
        .collection('expenses')
        .doc('x1')
        .set(expense('x1', 'ev1', amount: 40).toJson());
    await settle();
    expect(cubit.state.isLive, isTrue);
    expect(cubit.state.events.map((e) => e.id), ['ev1']);
    expect(cubit.expensesFor('ev1').map((e) => e.id), ['x1']);
    expect(cubit.totalSpentFor('ev1'), 40);
  });

  test('add / update / delete events are immediate and persisted', () async {
    await settle();
    cubit.addEvent(fund('ev1'));
    expect(cubit.state.events, hasLength(1));
    expect(cubit.state.expensesByEvent.keys, ['ev1']);

    cubit.updateEvent(fund('ev1', name: 'Renamed'));
    expect(cubit.state.events.single.name, 'Renamed ev1');

    await settle();
    final stored = await fs
        .collection('users')
        .doc('u1')
        .collection('events')
        .doc('ev1')
        .get();
    expect(stored.data()!['name'], 'Renamed ev1');

    cubit.deleteEvent('ev1');
    expect(cubit.state.events, isEmpty);
    await settle();
    expect(cubit.state.events, isEmpty);
  });

  test('adding an expense to a new event works and is persisted', () async {
    await settle();
    cubit.addEvent(fund('ev1'));
    cubit.addExpense(expense('x1', 'ev1', amount: 25));
    expect(cubit.expensesFor('ev1').map((e) => e.id), ['x1']);
    expect(cubit.totalSpentFor('ev1'), 25);

    await settle();
    expect(cubit.state.isLive, isTrue);
    expect(cubit.expensesFor('ev1').map((e) => e.id), ['x1']);
    expect(await storedExpenseIds('ev1'), ['x1']);

    cubit.updateExpense(expense('x1', 'ev1', amount: 75));
    expect(cubit.totalSpentFor('ev1'), 75);

    cubit.deleteExpense('ev1', 'x1');
    expect(cubit.expensesFor('ev1'), isEmpty);
    await settle();
    expect(await storedExpenseIds('ev1'), isEmpty);
  });

  test('deleting an event removes its expenses from the store', () async {
    await settle();
    cubit.addEvent(fund('ev1'));
    cubit.addExpense(expense('x1', 'ev1'));
    cubit.addExpense(expense('x2', 'ev1'));
    await settle();
    expect(await storedExpenseIds('ev1'), ['x1', 'x2']);

    cubit.deleteEvent('ev1');
    expect(cubit.state.events, isEmpty);
    expect(cubit.expensesFor('ev1'), isEmpty);
    await settle();
    expect(await storedExpenseIds('ev1'), isEmpty);
    final events = await fs
        .collection('users')
        .doc('u1')
        .collection('events')
        .get();
    expect(events.docs, isEmpty);
  });

  test(
    'edits from elsewhere (another device) arrive without a refresh',
    () async {
      await settle();
      final events = fs.collection('users').doc('u1').collection('events');
      await events.doc('remote').set(fund('remote').toJson());
      await settle();
      expect(cubit.state.events.map((e) => e.id), ['remote']);

      await events
          .doc('remote')
          .collection('expenses')
          .doc('rx')
          .set(expense('rx', 'remote').toJson());
      await settle();
      expect(cubit.expensesFor('remote').map((e) => e.id), ['rx']);
    },
  );
}
