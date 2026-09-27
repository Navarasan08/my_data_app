import 'package:flutter/material.dart';

/// Whether an event happens once (anniversary of a graduation, a future
/// concert, etc.) or repeats every year (birthday, death anniversary).
enum DaysCounterRecurrence { oneTime, yearly }

extension DaysCounterRecurrenceX on DaysCounterRecurrence {
  String get label {
    switch (this) {
      case DaysCounterRecurrence.oneTime:
        return 'One time';
      case DaysCounterRecurrence.yearly:
        return 'Every year';
    }
  }
}

/// User-managed category for an event (Birthday, Death Anniversary,
/// Wedding Anniversary, Festival, …). The default trio is seeded once on
/// first load and from then on the user can add or remove freely — events
/// embed a snapshot of their type so deletion never strips the label.
class DaysCounterEventType {
  final String id;
  final String displayName;
  final int iconIndex;
  final int colorIndex;

  const DaysCounterEventType({
    required this.id,
    required this.displayName,
    required this.iconIndex,
    required this.colorIndex,
  });

  IconData get icon =>
      availableIcons[iconIndex.clamp(0, availableIcons.length - 1)];
  Color get color =>
      availableColors[colorIndex.clamp(0, availableColors.length - 1)];

  // IMPORTANT: existing entries store an `iconIndex` here — only append.
  static final List<IconData> availableIcons = [
    Icons.cake_rounded, // 0 birthday
    Icons.spa_rounded, // 1 death anniversary / remembrance
    Icons.favorite_rounded, // 2 wedding anniversary / love
    Icons.celebration_rounded, // 3 festival / celebration
    Icons.school_rounded, // 4 graduation
    Icons.work_rounded, // 5 work anniversary
    Icons.flight_takeoff_rounded, // 6 trip
    Icons.event_rounded, // 7 generic event
    Icons.local_florist_rounded, // 8 flower / memorial
    Icons.diamond_rounded, // 9 milestone / silver/gold
    Icons.child_friendly_rounded, // 10 baby
    Icons.handshake_rounded, // 11 friendship / contract
    Icons.health_and_safety_rounded, // 12 medical milestone
    Icons.home_rounded, // 13 house warming
    Icons.directions_run_rounded, // 14 marathon / event
    Icons.music_note_rounded, // 15 concert
    Icons.sports_esports_rounded, // 16 game / hobby
    Icons.account_balance_rounded, // 17 institutional
    Icons.menu_book_rounded, // 18 exam / education
    Icons.card_giftcard_rounded, // 19 gift / surprise
    Icons.star_rounded, // 20 milestone
    Icons.location_on_rounded, // 21 trip / place
  ];

  static final List<Color> availableColors = [
    Colors.pink,
    Colors.grey,
    Colors.red,
    Colors.amber,
    Colors.purple,
    Colors.indigo,
    Colors.green,
    Colors.teal,
    Colors.orange,
    Colors.blue,
    Colors.brown,
    Colors.deepPurple,
    Colors.cyan,
    Colors.deepOrange,
  ];

  /// Seeded once on first init.
  static final List<DaysCounterEventType> seedDefaults = [
    DaysCounterEventType(
      id: 'birthday',
      displayName: 'Birthday',
      iconIndex: 0,
      colorIndex: 0,
    ),
    DaysCounterEventType(
      id: 'death_anniversary',
      displayName: 'Death Anniversary',
      iconIndex: 1,
      colorIndex: 1,
    ),
    DaysCounterEventType(
      id: 'wedding_anniversary',
      displayName: 'Wedding Anniversary',
      iconIndex: 2,
      colorIndex: 2,
    ),
    DaysCounterEventType(
      id: 'festival',
      displayName: 'Festival',
      iconIndex: 3,
      colorIndex: 3,
    ),
  ];

  DaysCounterEventType copyWith({
    String? displayName,
    int? iconIndex,
    int? colorIndex,
  }) => DaysCounterEventType(
    id: id,
    displayName: displayName ?? this.displayName,
    iconIndex: iconIndex ?? this.iconIndex,
    colorIndex: colorIndex ?? this.colorIndex,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'displayName': displayName,
    'iconIndex': iconIndex,
    'colorIndex': colorIndex,
  };

  factory DaysCounterEventType.fromJson(Map<String, dynamic> json) =>
      DaysCounterEventType(
        id: json['id'] as String,
        displayName: json['displayName'] as String,
        iconIndex: (json['iconIndex'] as int? ?? 0),
        colorIndex: (json['colorIndex'] as int? ?? 0),
      );

  @override
  bool operator ==(Object other) =>
      other is DaysCounterEventType && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

class DaysCounterEvent {
  final String id;
  final String title;
  final DaysCounterEventType eventType;

  /// Original / "ground truth" date — for yearly events this is the
  /// reference day-of-year; for one-time events this is the only occurrence.
  final DateTime date;
  final DaysCounterRecurrence recurrence;
  final String? notes;

  /// False when only the day and month are known (e.g. a birthday whose
  /// year the user does not know). Age / years-since labels are hidden.
  final bool yearKnown;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DaysCounterEvent({
    required this.id,
    required this.title,
    required this.eventType,
    required this.date,
    required this.recurrence,
    this.notes,
    this.yearKnown = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Day-only floor used everywhere so leftover hours don't make us
  /// miscount "days left" (e.g., 23:59 today vs 00:00 tomorrow).
  static DateTime _floor(DateTime d) => DateTime(d.year, d.month, d.day);

  /// The next occurrence that is today-or-later. Returns `null` only for
  /// one-time events whose date is already in the past.
  DateTime? get nextOccurrence {
    final today = _floor(DateTime.now());
    if (recurrence == DaysCounterRecurrence.oneTime) {
      final d = _floor(date);
      return d.isBefore(today) ? null : d;
    }
    // Yearly — anchor on this year's anniversary, push to next year if it
    // has already passed.
    var anniversary = DateTime(today.year, date.month, date.day);
    if (anniversary.isBefore(today)) {
      anniversary = DateTime(today.year + 1, date.month, date.day);
    }
    return _floor(anniversary);
  }

  /// Whole days from today to [nextOccurrence] — `null` if event has no
  /// future occurrence. 0 means "today".
  int? get daysUntilNext {
    final next = nextOccurrence;
    if (next == null) return null;
    return next.difference(_floor(DateTime.now())).inDays;
  }

  /// Whole days since the most recent past occurrence — `null` if the
  /// event has never happened yet (purely future one-time).
  int? get daysSincePast {
    final today = _floor(DateTime.now());
    if (recurrence == DaysCounterRecurrence.oneTime) {
      final d = _floor(date);
      return d.isBefore(today) ? today.difference(d).inDays : null;
    }
    // Yearly: this year's anniversary if passed, otherwise last year's.
    var anniversary = DateTime(today.year, date.month, date.day);
    if (anniversary.isAfter(today)) {
      anniversary = DateTime(today.year - 1, date.month, date.day);
    }
    return today.difference(_floor(anniversary)).inDays;
  }

  /// How many full years separate [asOf] from the original [date]. Used
  /// for "turning 60" / "12 years ago" on yearly events.
  int yearsFromOriginalOn(DateTime asOf) {
    int years = asOf.year - date.year;
    if (asOf.month < date.month ||
        (asOf.month == date.month && asOf.day < date.day)) {
      years--;
    }
    return years;
  }

  bool get isYearly => recurrence == DaysCounterRecurrence.yearly;

  DaysCounterEvent copyWith({
    String? title,
    DaysCounterEventType? eventType,
    DateTime? date,
    DaysCounterRecurrence? recurrence,
    String? notes,
    bool clearNotes = false,
    bool? yearKnown,
    DateTime? updatedAt,
  }) => DaysCounterEvent(
    id: id,
    title: title ?? this.title,
    eventType: eventType ?? this.eventType,
    date: date ?? this.date,
    recurrence: recurrence ?? this.recurrence,
    notes: clearNotes ? null : (notes ?? this.notes),
    yearKnown: yearKnown ?? this.yearKnown,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'eventType': eventType.toJson(),
    'date': date.toIso8601String(),
    'recurrence': recurrence.index,
    'notes': notes,
    'yearKnown': yearKnown,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory DaysCounterEvent.fromJson(Map<String, dynamic> json) {
    final etRaw = json['eventType'];
    final DaysCounterEventType et;
    if (etRaw is Map<String, dynamic>) {
      et = DaysCounterEventType.fromJson(etRaw);
    } else if (etRaw is Map) {
      et = DaysCounterEventType.fromJson(Map<String, dynamic>.from(etRaw));
    } else {
      et = DaysCounterEventType.seedDefaults.first;
    }
    return DaysCounterEvent(
      id: json['id'] as String,
      title: json['title'] as String,
      eventType: et,
      date: DateTime.parse(json['date'] as String),
      recurrence:
          DaysCounterRecurrence.values[(json['recurrence'] as int? ?? 0).clamp(
            0,
            DaysCounterRecurrence.values.length - 1,
          )],
      notes: json['notes'] as String?,
      yearKnown: json['yearKnown'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

// ─── Type-aware details (age, anniversaries, years since) ────────────────────

/// What an event type represents, so the card can say "Turning 33" for a
/// birthday but "12th death anniversary" for a memorial. Resolved from the
/// seeded type ids first, then from the type's name for custom types.
enum DaysCounterEventKind { birthday, memorial, wedding, festival, other }

DaysCounterEventKind daysCounterKindOf(DaysCounterEventType type) {
  final name = type.displayName.toLowerCase();
  if (type.id == 'birthday' || name.contains('birth')) {
    return DaysCounterEventKind.birthday;
  }
  if (type.id == 'death_anniversary' ||
      name.contains('death') ||
      name.contains('memorial') ||
      name.contains('passing') ||
      name.contains('remembrance')) {
    return DaysCounterEventKind.memorial;
  }
  if (type.id == 'wedding_anniversary' ||
      name.contains('wedding') ||
      name.contains('marriage')) {
    return DaysCounterEventKind.wedding;
  }
  if (type.id == 'festival' || name.contains('festival')) {
    return DaysCounterEventKind.festival;
  }
  return DaysCounterEventKind.other;
}

/// 1 → "1st", 22 → "22nd", 13 → "13th".
String ordinal(int n) {
  final r100 = n % 100;
  if (r100 >= 11 && r100 <= 13) return '${n}th';
  switch (n % 10) {
    case 1:
      return '${n}st';
    case 2:
      return '${n}nd';
    case 3:
      return '${n}rd';
    default:
      return '${n}th';
  }
}

const _monthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _fmtDate(DateTime d) => '${d.day} ${_monthNames[d.month - 1]} ${d.year}';

/// Two lines the card shows for a yearly event: a short [headline] such as
/// "Turning 33" and a longer [detail] such as "Born 12 Mar 1994 · 32 years
/// old". Either can be null when there is nothing meaningful to say.
class DaysCounterEventDetail {
  final String? headline;
  final String? detail;
  const DaysCounterEventDetail({this.headline, this.detail});
}

extension DaysCounterEventDetails on DaysCounterEvent {
  DaysCounterEventKind get kind => daysCounterKindOf(eventType);

  /// [nextOccurrence] relative to an explicit [today] (for tests and previews).
  DateTime? nextOccurrenceOn(DateTime today) {
    final t = DaysCounterEvent._floor(today);
    if (recurrence == DaysCounterRecurrence.oneTime) {
      final d = DaysCounterEvent._floor(date);
      return d.isBefore(t) ? null : d;
    }
    var a = DateTime(t.year, date.month, date.day);
    if (a.isBefore(t)) a = DateTime(t.year + 1, date.month, date.day);
    return DaysCounterEvent._floor(a);
  }

  /// The most recent occurrence on or before [today]; null if none yet.
  DateTime? lastOccurrenceOn(DateTime today) {
    final t = DaysCounterEvent._floor(today);
    if (recurrence == DaysCounterRecurrence.oneTime) {
      final d = DaysCounterEvent._floor(date);
      return d.isAfter(t) ? null : d;
    }
    var a = DateTime(t.year, date.month, date.day);
    if (a.isAfter(t)) a = DateTime(t.year - 1, date.month, date.day);
    return DaysCounterEvent._floor(a);
  }

  /// Completed years from the original date to today; negative if the
  /// original date is still in the future.
  int yearsNowOn(DateTime today) =>
      yearsFromOriginalOn(DaysCounterEvent._floor(today));

  DaysCounterEventDetail describe({required bool upcoming, DateTime? today}) {
    final t = DaysCounterEvent._floor(today ?? DateTime.now());
    if (!isYearly) return const DaysCounterEventDetail();
    if (!yearKnown)
      return const DaysCounterEventDetail(detail: 'Year not known');

    final origin = DaysCounterEvent._floor(date);
    if (origin.isAfter(t)) {
      // Original date still ahead: nothing to count yet.
      return DaysCounterEventDetail(
        detail: switch (kind) {
          DaysCounterEventKind.birthday => 'Expected ${_fmtDate(origin)}',
          DaysCounterEventKind.wedding => 'Wedding on ${_fmtDate(origin)}',
          _ => 'Starts ${_fmtDate(origin)}',
        },
      );
    }

    final yearsNow = yearsNowOn(t);
    final occ = upcoming ? nextOccurrenceOn(t) : lastOccurrenceOn(t);
    final n = occ == null ? 0 : yearsFromOriginalOn(occ);
    final isToday = occ == t;

    String? headline;
    String? detail;
    switch (kind) {
      case DaysCounterEventKind.birthday:
        if (n > 0) {
          headline = upcoming
              ? (isToday ? 'Turns $n today' : 'Turning $n')
              : 'Turned $n';
        }
        detail =
            'Born ${_fmtDate(origin)}'
            '${yearsNow > 0 ? ' · $yearsNow years old' : ''}';
        break;
      case DaysCounterEventKind.memorial:
        if (n > 0) headline = '${ordinal(n)} death anniversary';
        detail =
            'Passed away ${_fmtDate(origin)}'
            '${yearsNow > 0 ? ' · $yearsNow years ago' : ''}';
        break;
      case DaysCounterEventKind.wedding:
        if (n > 0) headline = '${ordinal(n)} wedding anniversary';
        detail =
            'Married ${_fmtDate(origin)}'
            '${yearsNow > 0 ? ' · $yearsNow years together' : ''}';
        break;
      case DaysCounterEventKind.festival:
        break;
      case DaysCounterEventKind.other:
        if (n > 0) headline = '${ordinal(n)} anniversary';
        if (yearsNow > 0) detail = 'Since ${origin.year} · $yearsNow years';
        break;
    }
    return DaysCounterEventDetail(headline: headline, detail: detail);
  }
}
