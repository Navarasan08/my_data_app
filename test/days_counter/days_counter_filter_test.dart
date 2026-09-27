import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_data_app/src/days_counter/cubit/days_counter_cubit.dart';
import 'package:my_data_app/src/days_counter/cubit/days_counter_state.dart';
import 'package:my_data_app/src/days_counter/model/days_counter_model.dart';
import 'package:my_data_app/src/days_counter/repository/days_counter_repository.dart';

DaysCounterEventType type(String id) => DaysCounterEventType(
  id: id,
  displayName: 'Type $id',
  iconIndex: 0,
  colorIndex: 0,
);

DaysCounterEvent ev(
  String id, {
  required DaysCounterEventType t,
  required DateTime date,
  DaysCounterRecurrence recurrence = DaysCounterRecurrence.yearly,
  String? title,
  String? notes,
}) {
  final now = DateTime.now();
  return DaysCounterEvent(
    id: id,
    title: title ?? 'Event $id',
    eventType: t,
    date: date,
    recurrence: recurrence,
    notes: notes,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late FakeFirebaseFirestore fs;
  late FirestoreDaysCounterRepository repo;
  late DaysCounterCubit cubit;
  final today = DateTime.now();
  DateTime inDays(int d) {
    final t = today.add(Duration(days: d));
    return DateTime(t.year, t.month, t.day);
  }

  final birthday = type('birthday');
  final festival = type('festival');

  setUp(() async {
    fs = FakeFirebaseFirestore();
    await fs
        .collection('users')
        .doc('u1')
        .collection('days_counter_settings')
        .doc('prefs')
        .set({'typesSeeded': true});
    repo = FirestoreDaysCounterRepository(uid: 'u1', firestore: fs)..start();
    cubit = DaysCounterCubit(repo);
    await pumpEventQueue();
    // Yearly birthday in 5 days, yearly festival in 60 days, one-time
    // event in 200 days, one-time event 10 days ago, one-time 100 days ago.
    cubit.addEvent(ev('b5', t: birthday, date: inDays(5), title: 'Mom'));
    cubit.addEvent(ev('f60', t: festival, date: inDays(60), title: 'Diwali'));
    cubit.addEvent(
      ev(
        'o200',
        t: festival,
        date: inDays(200),
        recurrence: DaysCounterRecurrence.oneTime,
        title: 'Concert',
        notes: 'front row',
      ),
    );
    cubit.addEvent(
      ev(
        'p10',
        t: birthday,
        date: inDays(-10),
        recurrence: DaysCounterRecurrence.oneTime,
        title: 'Exam',
      ),
    );
    cubit.addEvent(
      ev(
        'p100',
        t: festival,
        date: inDays(-100),
        recurrence: DaysCounterRecurrence.oneTime,
        title: 'Trip',
      ),
    );
  });

  tearDown(() async {
    await cubit.close();
    await repo.dispose();
  });

  List<String> ids(List<DaysCounterEvent> l) => l.map((e) => e.id).toList();

  test('no filters: everything shows, sorted', () {
    expect(ids(cubit.upcoming), ['b5', 'f60', 'o200']);
    expect(ids(cubit.past), ['p10', 'p100']);
    expect(cubit.state.hasActiveFilters, isFalse);
    expect(cubit.hiddenByFilters, 0);
  });

  test('window limits upcoming ahead and past back', () {
    cubit.setWindow(DaysCounterWindow.month);
    expect(ids(cubit.upcoming), ['b5']);
    expect(ids(cubit.past), ['p10']);
    expect(cubit.hiddenByFilters, 3);

    cubit.setWindow(DaysCounterWindow.quarter);
    expect(ids(cubit.upcoming), ['b5', 'f60']);
    expect(ids(cubit.past), ['p10']);
  });

  test('type filter is multi-select and toggles', () {
    cubit.toggleTypeFilter('birthday');
    expect(ids(cubit.upcoming), ['b5']);
    expect(ids(cubit.past), ['p10']);

    cubit.toggleTypeFilter('festival');
    expect(ids(cubit.upcoming), ['b5', 'f60', 'o200']);

    cubit.toggleTypeFilter('birthday');
    expect(ids(cubit.upcoming), ['f60', 'o200']);
    expect(cubit.state.activeFilterCount, 1);
  });

  test('recurrence filter', () {
    cubit.setRecurrenceFilter(DaysCounterRecurrence.oneTime);
    expect(ids(cubit.upcoming), ['o200']);
    cubit.setRecurrenceFilter(DaysCounterRecurrence.yearly);
    expect(ids(cubit.upcoming), ['b5', 'f60']);
    expect(ids(cubit.past), isEmpty);
    cubit.setRecurrenceFilter(null);
    expect(ids(cubit.upcoming), ['b5', 'f60', 'o200']);
  });

  test('search matches title and notes, case-insensitively', () {
    cubit.setSearch('MOM');
    expect(ids(cubit.upcoming), ['b5']);
    cubit.setSearch('front');
    expect(ids(cubit.upcoming), ['o200']);
    cubit.setSearch('   ');
    expect(cubit.state.hasActiveFilters, isFalse);
  });

  test('filters combine and clear together', () {
    cubit.toggleTypeFilter('festival');
    cubit.setWindow(DaysCounterWindow.year);
    cubit.setRecurrenceFilter(DaysCounterRecurrence.oneTime);
    expect(ids(cubit.upcoming), ['o200']);
    expect(ids(cubit.past), ['p100']);
    expect(cubit.state.activeFilterCount, 3);

    cubit.clearFilters();
    expect(cubit.state.hasActiveFilters, isFalse);
    expect(ids(cubit.upcoming), ['b5', 'f60', 'o200']);
  });

  test('dashboard count ignores filters', () {
    cubit.setWindow(DaysCounterWindow.week);
    cubit.toggleTypeFilter('festival');
    expect(cubit.upcoming, isEmpty);
    expect(cubit.upcomingCount, 3);
  });

  test('filters survive data updates', () async {
    cubit.setWindow(DaysCounterWindow.week);
    await pumpEventQueue();
    cubit.addEvent(ev('b2', t: birthday, date: inDays(2), title: 'Dad'));
    await pumpEventQueue();
    expect(cubit.state.window, DaysCounterWindow.week);
    expect(ids(cubit.upcoming), ['b2', 'b5']);
  });
}
