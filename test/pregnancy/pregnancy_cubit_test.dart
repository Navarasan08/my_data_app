import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_data_app/src/core/sync/sync_snapshot.dart';
import 'package:my_data_app/src/pregnancy/cubit/pregnancy_cubit.dart';
import 'package:my_data_app/src/pregnancy/model/pregnancy_guide.dart';
import 'package:my_data_app/src/pregnancy/model/pregnancy_model.dart';
import 'package:my_data_app/src/pregnancy/pregnancy_reminder_source.dart';
import 'package:my_data_app/src/pregnancy/repository/pregnancy_repository.dart';

void main() {
  late FakeFirebaseFirestore fs;
  late FirestorePregnancyRepository repo;
  late PregnancyCubit cubit;

  // Pin "today" so week maths is deterministic: LMP 100 days ago → week 15.
  final today = DateTime(2026, 9, 28);
  final lmp = today.subtract(const Duration(days: 100));

  setUp(() {
    fs = FakeFirebaseFirestore();
    repo = FirestorePregnancyRepository(uid: 'u1', firestore: fs)..start();
    cubit = PregnancyCubit(repo, now: () => today);
  });

  tearDown(() async {
    await cubit.close();
    await repo.dispose();
  });

  test('starts loading and not tracking', () async {
    expect(cubit.state.syncStatus, SyncStatus.loading);
    expect(cubit.isTracking, isFalse);
    await pumpEventQueue();
    expect(cubit.state.isLive, isTrue);
    expect(cubit.isTracking, isFalse);
    expect(cubit.state.checks, isEmpty);
  });

  test(
    'startPregnancy with LMP sets dates, week and seeds the checklist',
    () async {
      await pumpEventQueue();
      cubit.startPregnancy(lmpDate: lmp);

      expect(cubit.isTracking, isTrue);
      expect(cubit.currentWeek, 15);
      expect(cubit.currentDayOfWeek, 2);
      expect(cubit.trimester, 2);
      expect(cubit.dueDate, lmp.add(const Duration(days: 280)));
      expect(cubit.daysToGo, 180);
      expect(cubit.progress, closeTo(100 / 280, 0.001));
      expect(cubit.state.checks.length, PregnancyCheckItem.seedDefaults.length);

      await pumpEventQueue();
      final stored = await fs
          .collection('users')
          .doc('u1')
          .collection('pregnancy_settings')
          .doc('profile')
          .get();
      expect(stored.data()!['active'], isTrue);
      expect(cubit.state.checks.length, PregnancyCheckItem.seedDefaults.length);
    },
  );

  test('startPregnancy with a due date counts back 280 days', () async {
    await pumpEventQueue();
    final due = today.add(const Duration(days: 70));
    cubit.startPregnancy(dueDate: due);
    expect(cubit.dueDate, due);
    expect(cubit.currentWeek, 31); // 210 days in → week 31
    expect(cubit.trimester, 3);
  });

  test('week is clamped and trimester boundaries are right', () {
    final p = PregnancyProfile(lmpDate: lmp, active: true);
    expect(p.weekOn(lmp.subtract(const Duration(days: 30))), 1);
    expect(p.weekOn(lmp.add(const Duration(days: 400))), 42);
    expect(PregnancyProfile.trimesterOf(13), 1);
    expect(PregnancyProfile.trimesterOf(14), 2);
    expect(PregnancyProfile.trimesterOf(27), 2);
    expect(PregnancyProfile.trimesterOf(28), 3);
  });

  test('checks are classified as overdue, current and upcoming', () async {
    await pumpEventQueue();
    cubit.startPregnancy(lmpDate: lmp); // week 15
    await pumpEventQueue();

    final overdueIds = cubit.overdueChecks.map((c) => c.id).toList();
    expect(overdueIds, containsAll(['booking_visit', 'nt_scan']));
    expect(overdueIds, isNot(contains('ogtt')));

    final currentIds = cubit.currentChecks.map((c) => c.id).toList();
    expect(currentIds, containsAll(['iron_calcium', 'flu_vaccine']));

    final upcoming = cubit.upcomingChecks(limit: 3);
    expect(upcoming.length, 3);
    expect(upcoming.first.isCurrentAt(15), isTrue);
  });

  test('toggleCheck marks done with today and clears on undo', () async {
    await pumpEventQueue();
    cubit.startPregnancy(lmpDate: lmp);
    await pumpEventQueue();

    cubit.toggleCheck('nt_scan');
    var item = cubit.state.checks.firstWhere((c) => c.id == 'nt_scan');
    expect(item.done, isTrue);
    expect(item.doneDate, today);
    expect(cubit.completedCount, 1);
    expect(cubit.overdueChecks.map((c) => c.id), isNot(contains('nt_scan')));

    cubit.toggleCheck('nt_scan');
    item = cubit.state.checks.firstWhere((c) => c.id == 'nt_scan');
    expect(item.done, isFalse);
    expect(item.doneDate, isNull);

    await pumpEventQueue();
    expect(
      cubit.state.checks.firstWhere((c) => c.id == 'nt_scan').done,
      isFalse,
    );
  });

  test('custom checks can be added, edited and deleted', () async {
    await pumpEventQueue();
    cubit.startPregnancy(lmpDate: lmp);
    cubit.addCheck(
      const PregnancyCheckItem(
        id: 'c1',
        title: 'Dentist',
        category: PregnancyCheckCategory.appointment,
        fromWeek: 16,
        toWeek: 18,
      ),
    );
    expect(cubit.state.checks.firstWhere((c) => c.id == 'c1').isCustom, isTrue);

    cubit.updateCheck(
      cubit.state.checks
          .firstWhere((c) => c.id == 'c1')
          .copyWith(title: 'Dentist visit'),
    );
    expect(
      cubit.state.checks.firstWhere((c) => c.id == 'c1').title,
      'Dentist visit',
    );

    cubit.deleteCheck('c1');
    expect(cubit.state.checks.any((c) => c.id == 'c1'), isFalse);
    await pumpEventQueue();
    expect(cubit.state.checks.any((c) => c.id == 'c1'), isFalse);
  });

  test('journal logs sort newest first and report weight change', () async {
    await pumpEventQueue();
    cubit.addLog(
      PregnancyLog(
        id: 'l1',
        date: today.subtract(const Duration(days: 30)),
        weightKg: 58,
      ),
    );
    cubit.addLog(
      PregnancyLog(
        id: 'l2',
        date: today,
        weightKg: 60.5,
        bpSystolic: 110,
        bpDiastolic: 70,
        symptoms: const ['Nausea'],
      ),
    );
    expect(cubit.sortedLogs.first.id, 'l2');
    expect(cubit.latestLog!.bpLabel, '110/70');
    expect(cubit.weightChange, closeTo(2.5, 0.001));

    cubit.deleteLog('l1');
    expect(cubit.weightChange, isNull);
    await pumpEventQueue();
    expect(cubit.state.logs.map((l) => l.id), ['l2']);
  });

  test('endPregnancy keeps data; resetAll wipes it', () async {
    await pumpEventQueue();
    cubit.startPregnancy(lmpDate: lmp);
    cubit.addLog(PregnancyLog(id: 'l1', date: today));
    await pumpEventQueue();

    cubit.endPregnancy();
    expect(cubit.isTracking, isFalse);
    expect(cubit.state.checks, isNotEmpty);

    cubit.resetAll();
    expect(cubit.state.checks, isEmpty);
    expect(cubit.state.logs, isEmpty);
    await pumpEventQueue();
    expect(
      (await fs
              .collection('users')
              .doc('u1')
              .collection('pregnancy_checks')
              .get())
          .docs,
      isEmpty,
    );
  });

  test('reminder source emits pending checks closing in the window', () async {
    await pumpEventQueue();
    cubit.startPregnancy(lmpDate: lmp); // week 15, day 2
    final source = PregnancyReminderSource(cubit: cubit);

    // iron_calcium closes at the end of week 16 → 12 days from today.
    final endOfWeek16 = cubit.profile.endOfWeek(16)!;
    final items = source.pendingIn(
      endOfWeek16.subtract(const Duration(days: 1)),
      endOfWeek16.add(const Duration(days: 1)),
    );
    expect(items.map((i) => i.itemId), contains('iron_calcium'));

    cubit.toggleCheck('iron_calcium');
    final after = source.pendingIn(
      endOfWeek16.subtract(const Duration(days: 1)),
      endOfWeek16.add(const Duration(days: 1)),
    );
    expect(after.map((i) => i.itemId), isNot(contains('iron_calcium')));

    cubit.endPregnancy();
    expect(
      source.pendingIn(today, today.add(const Duration(days: 365))),
      isEmpty,
    );
  });

  test('week guide resolves to the nearest earlier entry', () {
    expect(PregnancyWeekGuide.forWeek(2).week, 1);
    expect(PregnancyWeekGuide.forWeek(15).week, 15);
    expect(PregnancyWeekGuide.forWeek(42).week, 40);
    expect(
      PregnancyWeekGuide.weeks.map((g) => g.week).toSet().length,
      PregnancyWeekGuide.weeks.length,
    );
  });
}
