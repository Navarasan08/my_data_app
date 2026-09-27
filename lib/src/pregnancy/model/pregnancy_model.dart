import 'package:flutter/material.dart';

/// Standard pregnancy length counted from the first day of the last
/// menstrual period (LMP).
const int kPregnancyDays = 280;
const int kPregnancyWeeks = 40;

/// The user's current pregnancy. One document per account.
class PregnancyProfile {
  /// First day of the last menstrual period. Week 1 starts here.
  final DateTime? lmpDate;

  /// Due date given by the doctor (from a dating scan). When set it wins
  /// over the LMP-derived date and everything is counted back from it.
  final DateTime? dueDateOverride;

  final bool active;
  final bool checksSeeded;
  final String? babyName;
  final String? doctorName;
  final String? hospital;

  const PregnancyProfile({
    this.lmpDate,
    this.dueDateOverride,
    this.active = false,
    this.checksSeeded = false,
    this.babyName,
    this.doctorName,
    this.hospital,
  });

  static const defaults = PregnancyProfile();

  /// True once dates are known and the pregnancy is being tracked.
  bool get isSet => active && (lmpDate != null || dueDateOverride != null);

  DateTime? get dueDate =>
      dueDateOverride ??
      (lmpDate == null
          ? null
          : _day(lmpDate!).add(const Duration(days: kPregnancyDays)));

  /// Day 1 of week 1.
  DateTime? get startDate {
    if (lmpDate != null) return _day(lmpDate!);
    final due = dueDateOverride;
    return due == null
        ? null
        : _day(due).subtract(const Duration(days: kPregnancyDays));
  }

  /// Gestational week (1-based) on [day], clamped to 1..42.
  int weekOn(DateTime day) {
    final start = startDate;
    if (start == null) return 1;
    final days = _day(day).difference(start).inDays;
    return (days ~/ 7 + 1).clamp(1, 42);
  }

  /// Days into the current week (0..6) on [day].
  int dayOfWeekOn(DateTime day) {
    final start = startDate;
    if (start == null) return 0;
    return (_day(day).difference(start).inDays % 7).clamp(0, 6);
  }

  static int trimesterOf(int week) => week <= 13 ? 1 : (week <= 27 ? 2 : 3);

  /// First day of [week].
  DateTime? dateForWeek(int week) =>
      startDate?.add(Duration(days: (week - 1) * 7));

  /// Last day of [week].
  DateTime? endOfWeek(int week) => startDate?.add(Duration(days: week * 7 - 1));

  PregnancyProfile copyWith({
    DateTime? lmpDate,
    bool clearLmp = false,
    DateTime? dueDateOverride,
    bool clearDueDateOverride = false,
    bool? active,
    bool? checksSeeded,
    String? babyName,
    String? doctorName,
    String? hospital,
  }) {
    return PregnancyProfile(
      lmpDate: clearLmp ? null : (lmpDate ?? this.lmpDate),
      dueDateOverride: clearDueDateOverride
          ? null
          : (dueDateOverride ?? this.dueDateOverride),
      active: active ?? this.active,
      checksSeeded: checksSeeded ?? this.checksSeeded,
      babyName: babyName ?? this.babyName,
      doctorName: doctorName ?? this.doctorName,
      hospital: hospital ?? this.hospital,
    );
  }

  Map<String, dynamic> toJson() => {
    'lmpDate': lmpDate?.toIso8601String(),
    'dueDateOverride': dueDateOverride?.toIso8601String(),
    'active': active,
    'checksSeeded': checksSeeded,
    'babyName': babyName,
    'doctorName': doctorName,
    'hospital': hospital,
  };

  factory PregnancyProfile.fromJson(Map<String, dynamic>? json) {
    if (json == null) return defaults;
    DateTime? d(String key) {
      final v = json[key];
      return v is String ? DateTime.tryParse(v) : null;
    }

    return PregnancyProfile(
      lmpDate: d('lmpDate'),
      dueDateOverride: d('dueDateOverride'),
      active: json['active'] as bool? ?? false,
      checksSeeded: json['checksSeeded'] as bool? ?? false,
      babyName: json['babyName'] as String?,
      doctorName: json['doctorName'] as String?,
      hospital: json['hospital'] as String?,
    );
  }
}

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

enum PregnancyCheckCategory {
  appointment('Appointment', Icons.event_available_rounded, Colors.blue),
  scan('Scan', Icons.monitor_heart_rounded, Colors.purple),
  test('Lab test', Icons.biotech_rounded, Colors.teal),
  vaccine('Vaccine', Icons.vaccines_rounded, Colors.orange),
  supplement('Supplement', Icons.medication_rounded, Colors.green),
  lifestyle('Lifestyle', Icons.self_improvement_rounded, Colors.pink),
  preparation('Preparation', Icons.checklist_rounded, Colors.indigo),
  custom('Custom', Icons.push_pin_rounded, Colors.blueGrey);

  final String label;
  final IconData icon;
  final MaterialColor color;
  const PregnancyCheckCategory(this.label, this.icon, this.color);

  static PregnancyCheckCategory fromName(String? name) =>
      PregnancyCheckCategory.values.firstWhere(
        (c) => c.name == name,
        orElse: () => PregnancyCheckCategory.custom,
      );
}

/// One thing to do during the pregnancy, tied to a window of weeks.
class PregnancyCheckItem {
  final String id;
  final String title;
  final String description;
  final PregnancyCheckCategory category;

  /// Recommended window, inclusive. A single-week item has fromWeek == toWeek.
  final int fromWeek;
  final int toWeek;
  final bool done;
  final DateTime? doneDate;
  final String? notes;
  final bool isCustom;

  /// Display order within the same week window.
  final int order;

  const PregnancyCheckItem({
    required this.id,
    required this.title,
    this.description = '',
    required this.category,
    required this.fromWeek,
    required this.toWeek,
    this.done = false,
    this.doneDate,
    this.notes,
    this.isCustom = false,
    this.order = 0,
  });

  int get trimester => PregnancyProfile.trimesterOf(fromWeek);

  String get windowLabel =>
      fromWeek == toWeek ? 'Week $fromWeek' : 'Weeks $fromWeek–$toWeek';

  /// Last day of the recommended window, used for reminders and overdue.
  DateTime? dueDate(PregnancyProfile profile) => profile.endOfWeek(toWeek);

  bool isOverdueAt(int currentWeek) => !done && currentWeek > toWeek;
  bool isCurrentAt(int currentWeek) =>
      !done && currentWeek >= fromWeek && currentWeek <= toWeek;

  PregnancyCheckItem copyWith({
    String? title,
    String? description,
    PregnancyCheckCategory? category,
    int? fromWeek,
    int? toWeek,
    bool? done,
    DateTime? doneDate,
    bool clearDoneDate = false,
    String? notes,
    bool? isCustom,
    int? order,
  }) {
    return PregnancyCheckItem(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      fromWeek: fromWeek ?? this.fromWeek,
      toWeek: toWeek ?? this.toWeek,
      done: done ?? this.done,
      doneDate: clearDoneDate ? null : (doneDate ?? this.doneDate),
      notes: notes ?? this.notes,
      isCustom: isCustom ?? this.isCustom,
      order: order ?? this.order,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'category': category.name,
    'fromWeek': fromWeek,
    'toWeek': toWeek,
    'done': done,
    'doneDate': doneDate?.toIso8601String(),
    'notes': notes,
    'isCustom': isCustom,
    'order': order,
  };

  factory PregnancyCheckItem.fromJson(Map<String, dynamic> json) {
    final doneRaw = json['doneDate'];
    return PregnancyCheckItem(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      category: PregnancyCheckCategory.fromName(json['category'] as String?),
      fromWeek: (json['fromWeek'] as num?)?.toInt() ?? 1,
      toWeek: (json['toWeek'] as num?)?.toInt() ?? 40,
      done: json['done'] as bool? ?? false,
      doneDate: doneRaw is String ? DateTime.tryParse(doneRaw) : null,
      notes: json['notes'] as String?,
      isCustom: json['isCustom'] as bool? ?? false,
      order: (json['order'] as num?)?.toInt() ?? 0,
    );
  }

  /// The standard antenatal schedule. Windows follow common guidance; the
  /// user's doctor may move or skip items, which is why every one can be
  /// edited or deleted.
  static final List<PregnancyCheckItem> seedDefaults = [
    _seed(
      'folic_acid',
      'Start folic acid',
      'Daily folic acid (usually 400 mcg) through the first trimester supports neural tube development.',
      PregnancyCheckCategory.supplement,
      4,
      12,
      0,
    ),
    _seed(
      'booking_visit',
      'First prenatal (booking) visit',
      'Medical history, weight, blood pressure and the plan for the pregnancy.',
      PregnancyCheckCategory.appointment,
      6,
      10,
      1,
    ),
    _seed(
      'dating_scan',
      'Dating / viability scan',
      'Confirms the pregnancy, the heartbeat and how far along you are.',
      PregnancyCheckCategory.scan,
      6,
      10,
      2,
    ),
    _seed(
      'booking_bloods',
      'Booking blood tests',
      'Blood group and Rh, haemoglobin, blood sugar, thyroid, HIV, hepatitis B, syphilis, rubella immunity; plus urine.',
      PregnancyCheckCategory.test,
      8,
      12,
      3,
    ),
    _seed(
      'nt_scan',
      'NT scan & first-trimester screening',
      'Nuchal translucency scan with blood markers to screen for chromosomal conditions.',
      PregnancyCheckCategory.scan,
      11,
      14,
      4,
    ),
    _seed(
      'iron_calcium',
      'Start iron & calcium',
      'Iron and calcium supplements are usually started after the first trimester.',
      PregnancyCheckCategory.supplement,
      13,
      16,
      5,
    ),
    _seed(
      'flu_vaccine',
      'Flu vaccine',
      'Safe in any trimester; ask at your next visit.',
      PregnancyCheckCategory.vaccine,
      14,
      30,
      6,
    ),
    _seed(
      'visit_2',
      'Second-trimester check-up',
      'Blood pressure, weight, fundal height and the baby\'s heartbeat.',
      PregnancyCheckCategory.appointment,
      16,
      20,
      7,
    ),
    _seed(
      'anomaly_scan',
      'Anomaly (TIFFA) scan',
      'Detailed scan of the baby\'s organs, spine, limbs and the placenta.',
      PregnancyCheckCategory.scan,
      18,
      22,
      8,
    ),
    _seed(
      'ogtt',
      'Glucose tolerance test (OGTT)',
      'Screens for gestational diabetes.',
      PregnancyCheckCategory.test,
      24,
      28,
      9,
    ),
    _seed(
      'hb_recheck',
      'Haemoglobin recheck',
      'Iron levels are rechecked in the late second trimester.',
      PregnancyCheckCategory.test,
      26,
      30,
      10,
    ),
    _seed(
      'tdap',
      'Tdap vaccine',
      'Protects the newborn from whooping cough; given between 27 and 36 weeks.',
      PregnancyCheckCategory.vaccine,
      27,
      36,
      11,
    ),
    _seed(
      'anti_d',
      'Anti-D injection (if Rh negative)',
      'Only needed when your blood group is Rh negative.',
      PregnancyCheckCategory.vaccine,
      28,
      28,
      12,
    ),
    _seed(
      'kick_counts',
      'Start daily kick counts',
      'From 28 weeks, notice the baby\'s usual pattern of movements every day.',
      PregnancyCheckCategory.lifestyle,
      28,
      28,
      13,
    ),
    _seed(
      'growth_scan',
      'Growth scan',
      'Checks the baby\'s growth, fluid and placenta position.',
      PregnancyCheckCategory.scan,
      28,
      34,
      14,
    ),
    _seed(
      'birth_plan',
      'Birth plan & hospital registration',
      'Register at the hospital, discuss delivery preferences and who will be with you.',
      PregnancyCheckCategory.preparation,
      30,
      34,
      15,
    ),
    _seed(
      'gbs',
      'GBS swab (if advised)',
      'Group B strep screening is offered in some settings between 35 and 37 weeks.',
      PregnancyCheckCategory.test,
      35,
      37,
      16,
    ),
    _seed(
      'hospital_bag',
      'Pack the hospital bag',
      'Documents, clothes for you and the baby, toiletries, chargers and snacks.',
      PregnancyCheckCategory.preparation,
      34,
      37,
      17,
    ),
    _seed(
      'presentation_scan',
      'Position / presentation check',
      'The doctor checks whether the baby is head-down.',
      PregnancyCheckCategory.appointment,
      36,
      37,
      18,
    ),
    _seed(
      'weekly_visits',
      'Weekly check-ups begin',
      'Visits become weekly from 36 weeks until delivery.',
      PregnancyCheckCategory.appointment,
      36,
      40,
      19,
    ),
  ];

  static PregnancyCheckItem _seed(
    String id,
    String title,
    String description,
    PregnancyCheckCategory category,
    int from,
    int to,
    int order,
  ) => PregnancyCheckItem(
    id: id,
    title: title,
    description: description,
    category: category,
    fromWeek: from,
    toWeek: to,
    order: order,
  );
}

/// A journal entry: how the mother is doing on a given day.
class PregnancyLog {
  final String id;
  final DateTime date;
  final double? weightKg;
  final int? bpSystolic;
  final int? bpDiastolic;
  final List<String> symptoms;
  final String? mood;
  final int? kicks;
  final String? notes;

  const PregnancyLog({
    required this.id,
    required this.date,
    this.weightKg,
    this.bpSystolic,
    this.bpDiastolic,
    this.symptoms = const [],
    this.mood,
    this.kicks,
    this.notes,
  });

  bool get hasBp => bpSystolic != null && bpDiastolic != null;
  String get bpLabel => hasBp ? '$bpSystolic/$bpDiastolic' : '';

  static const symptomOptions = [
    'Nausea',
    'Fatigue',
    'Headache',
    'Back pain',
    'Heartburn',
    'Swelling',
    'Cramps',
    'Dizziness',
    'Mood swings',
    'Sleep trouble',
    'Cravings',
    'Breathlessness',
  ];

  static const moodOptions = ['Great', 'Okay', 'Tired', 'Anxious', 'Low'];

  PregnancyLog copyWith({
    DateTime? date,
    double? weightKg,
    int? bpSystolic,
    int? bpDiastolic,
    List<String>? symptoms,
    String? mood,
    int? kicks,
    String? notes,
  }) {
    return PregnancyLog(
      id: id,
      date: date ?? this.date,
      weightKg: weightKg ?? this.weightKg,
      bpSystolic: bpSystolic ?? this.bpSystolic,
      bpDiastolic: bpDiastolic ?? this.bpDiastolic,
      symptoms: symptoms ?? this.symptoms,
      mood: mood ?? this.mood,
      kicks: kicks ?? this.kicks,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'weightKg': weightKg,
    'bpSystolic': bpSystolic,
    'bpDiastolic': bpDiastolic,
    'symptoms': symptoms,
    'mood': mood,
    'kicks': kicks,
    'notes': notes,
  };

  factory PregnancyLog.fromJson(Map<String, dynamic> json) => PregnancyLog(
    id: json['id'] as String,
    date: DateTime.parse(json['date'] as String),
    weightKg: (json['weightKg'] as num?)?.toDouble(),
    bpSystolic: (json['bpSystolic'] as num?)?.toInt(),
    bpDiastolic: (json['bpDiastolic'] as num?)?.toInt(),
    symptoms: (json['symptoms'] as List<dynamic>?)?.cast<String>() ?? const [],
    mood: json['mood'] as String?,
    kicks: (json['kicks'] as num?)?.toInt(),
    notes: json['notes'] as String?,
  );
}
