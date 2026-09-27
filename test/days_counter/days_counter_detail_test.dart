import 'package:flutter_test/flutter_test.dart';
import 'package:my_data_app/src/days_counter/model/days_counter_model.dart';

DaysCounterEventType type(String id, String name) => DaysCounterEventType(
  id: id,
  displayName: name,
  iconIndex: 0,
  colorIndex: 0,
);

DaysCounterEvent ev(
  DaysCounterEventType t,
  DateTime date, {
  DaysCounterRecurrence recurrence = DaysCounterRecurrence.yearly,
  bool yearKnown = true,
}) => DaysCounterEvent(
  id: 'e',
  title: 'x',
  eventType: t,
  date: date,
  recurrence: recurrence,
  yearKnown: yearKnown,
  createdAt: date,
  updatedAt: date,
);

void main() {
  final today = DateTime(2026, 9, 28);
  final birthday = type('birthday', 'Birthday');
  final memorial = type('death_anniversary', 'Death Anniversary');
  final wedding = type('wedding_anniversary', 'Wedding Anniversary');
  final festival = type('festival', 'Festival');

  group('kind detection', () {
    test('seeded ids map directly', () {
      expect(daysCounterKindOf(birthday), DaysCounterEventKind.birthday);
      expect(daysCounterKindOf(memorial), DaysCounterEventKind.memorial);
      expect(daysCounterKindOf(wedding), DaysCounterEventKind.wedding);
      expect(daysCounterKindOf(festival), DaysCounterEventKind.festival);
    });

    test('custom types are recognised by name', () {
      expect(
        daysCounterKindOf(type('x1', 'Dad\'s Birth Day')),
        DaysCounterEventKind.birthday,
      );
      expect(
        daysCounterKindOf(type('x2', 'Memorial')),
        DaysCounterEventKind.memorial,
      );
      expect(
        daysCounterKindOf(type('x3', 'Marriage')),
        DaysCounterEventKind.wedding,
      );
      expect(
        daysCounterKindOf(type('x4', 'Work anniversary')),
        DaysCounterEventKind.other,
      );
    });
  });

  test('ordinal suffixes', () {
    expect([1, 2, 3, 4, 11, 12, 13, 21, 22, 23, 101, 111].map(ordinal), [
      '1st',
      '2nd',
      '3rd',
      '4th',
      '11th',
      '12th',
      '13th',
      '21st',
      '22nd',
      '23rd',
      '101st',
      '111th',
    ]);
  });

  group('birthday', () {
    final born = DateTime(1994, 3, 12);

    test('upcoming: turning next age, with current age in the detail', () {
      final d = ev(birthday, born).describe(upcoming: true, today: today);
      expect(d.headline, 'Turning 33');
      expect(d.detail, 'Born 12 Mar 1994 · 32 years old');
    });

    test('past: turned age at the last birthday', () {
      final d = ev(birthday, born).describe(upcoming: false, today: today);
      expect(d.headline, 'Turned 32');
      expect(d.detail, 'Born 12 Mar 1994 · 32 years old');
    });

    test('on the day itself', () {
      final d = ev(
        birthday,
        born,
      ).describe(upcoming: true, today: DateTime(2026, 3, 12));
      expect(d.headline, 'Turns 32 today');
    });

    test('birthday later this year has not added a year yet', () {
      final d = ev(
        birthday,
        DateTime(2000, 12, 25),
      ).describe(upcoming: true, today: today);
      expect(d.headline, 'Turning 26');
      expect(d.detail, 'Born 25 Dec 2000 · 25 years old');
    });

    test('infant under one year shows no age', () {
      final d = ev(
        birthday,
        DateTime(2026, 5, 1),
      ).describe(upcoming: true, today: today);
      expect(d.headline, 'Turning 1');
      expect(d.detail, 'Born 1 May 2026');
    });

    test('year unknown hides age entirely', () {
      final d = ev(
        birthday,
        born,
        yearKnown: false,
      ).describe(upcoming: true, today: today);
      expect(d.headline, isNull);
      expect(d.detail, 'Year not known');
    });

    test('a future original date is described as expected', () {
      final d = ev(
        birthday,
        DateTime(2027, 1, 10),
      ).describe(upcoming: true, today: today);
      expect(d.headline, isNull);
      expect(d.detail, 'Expected 10 Jan 2027');
    });
  });

  test('memorial wording', () {
    final d = ev(
      memorial,
      DateTime(2014, 6, 5),
    ).describe(upcoming: true, today: today);
    expect(d.headline, '13th death anniversary');
    expect(d.detail, 'Passed away 5 Jun 2014 · 12 years ago');
  });

  test('wedding wording', () {
    final d = ev(
      wedding,
      DateTime(2016, 11, 20),
    ).describe(upcoming: true, today: today);
    expect(d.headline, '10th wedding anniversary');
    expect(d.detail, 'Married 20 Nov 2016 · 9 years together');
    final past = ev(
      wedding,
      DateTime(2016, 11, 20),
    ).describe(upcoming: false, today: today);
    expect(past.headline, '9th wedding anniversary');
  });

  test('festival says nothing about years', () {
    final d = ev(
      festival,
      DateTime(2020, 10, 24),
    ).describe(upcoming: true, today: today);
    expect(d.headline, isNull);
    expect(d.detail, isNull);
  });

  test('other yearly types get a generic anniversary', () {
    final d = ev(
      type('w', 'Work anniversary'),
      DateTime(2021, 2, 1),
    ).describe(upcoming: true, today: today);
    expect(d.headline, '6th anniversary');
    expect(d.detail, 'Since 2021 · 5 years');
  });

  test('one-time events have no year details', () {
    final d = ev(
      birthday,
      DateTime(2026, 12, 1),
      recurrence: DaysCounterRecurrence.oneTime,
    ).describe(upcoming: true, today: today);
    expect(d.headline, isNull);
    expect(d.detail, isNull);
  });

  test('yearKnown round-trips through JSON and defaults to true', () {
    final e = ev(birthday, DateTime(1994, 3, 12), yearKnown: false);
    final back = DaysCounterEvent.fromJson(e.toJson());
    expect(back.yearKnown, isFalse);
    final legacy = Map<String, dynamic>.from(e.toJson())..remove('yearKnown');
    expect(DaysCounterEvent.fromJson(legacy).yearKnown, isTrue);
    expect(e.copyWith(yearKnown: true).yearKnown, isTrue);
  });
}
