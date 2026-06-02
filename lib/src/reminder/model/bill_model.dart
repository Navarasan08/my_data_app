/// A monthly bill.
///
/// [dueDate] gives the day-of-month the bill is due (and its month is the
/// first month the bill applies). A bill recurs every month; the user marks
/// each month paid, tracked in [paidMonths] (normalised to year-month).
///
/// [deadline] is optional. When set, the bill runs for a fixed number of
/// months (start month → deadline month), so progress can be shown as
/// `completed/total` (e.g. 3/10). When absent, the bill is open-ended and only
/// the completed count is shown (e.g. 3).
class Bill {
  final String id;
  final String name;
  final String? description;
  final double? amount;
  final DateTime dueDate;
  final DateTime? deadline;
  final List<DateTime> paidMonths;
  final DateTime createdDate;

  Bill({
    required this.id,
    required this.name,
    this.description,
    this.amount,
    required this.dueDate,
    this.deadline,
    this.paidMonths = const [],
    required this.createdDate,
  });

  static DateTime _ym(DateTime d) => DateTime(d.year, d.month);

  bool isPaidForMonth(DateTime month) {
    final m = _ym(month);
    return paidMonths.any((p) => p.year == m.year && p.month == m.month);
  }

  /// The due date (with this bill's day-of-month, clamped) inside [month].
  DateTime dueDateInMonth(DateTime month) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final day = dueDate.day.clamp(1, daysInMonth);
    return DateTime(month.year, month.month, day);
  }

  /// Whole days from today until the due date in [month]. 0 = due today,
  /// negative = overdue.
  int daysLeftInMonth(DateTime month) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return dueDateInMonth(month).difference(today).inDays;
  }

  bool isOverdueInMonth(DateTime month) =>
      !isPaidForMonth(month) && daysLeftInMonth(month) < 0;

  /// Whether the bill applies in [month] (on/after its start month and, if a
  /// deadline is set, on/before the deadline month).
  bool isActiveInMonth(DateTime month) {
    final m = _ym(month);
    if (m.isBefore(_ym(dueDate))) return false;
    if (deadline != null && m.isAfter(_ym(deadline!))) return false;
    return true;
  }

  /// Total monthly occurrences when a deadline is set, else null (open-ended).
  int? get totalOccurrences {
    if (deadline == null) return null;
    final start = _ym(dueDate);
    final end = _ym(deadline!);
    final n = (end.year - start.year) * 12 + (end.month - start.month) + 1;
    return n < 1 ? 1 : n;
  }

  /// Number of months marked paid. Bounded to the start→deadline window when a
  /// deadline is set, so it pairs sensibly with [totalOccurrences].
  int get completedCount {
    if (deadline == null) return paidMonths.length;
    final start = _ym(dueDate);
    final end = _ym(deadline!);
    return paidMonths.where((p) {
      final m = _ym(p);
      return !m.isBefore(start) && !m.isAfter(end);
    }).length;
  }

  Bill copyWith({
    String? id,
    String? name,
    String? description,
    double? amount,
    DateTime? dueDate,
    DateTime? deadline,
    bool clearDeadline = false,
    List<DateTime>? paidMonths,
    DateTime? createdDate,
  }) {
    return Bill(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      deadline: clearDeadline ? null : (deadline ?? this.deadline),
      paidMonths: paidMonths ?? this.paidMonths,
      createdDate: createdDate ?? this.createdDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'amount': amount,
      'dueDate': dueDate.toIso8601String(),
      'deadline': deadline?.toIso8601String(),
      'paidMonths': paidMonths.map((d) => d.toIso8601String()).toList(),
      'createdDate': createdDate.toIso8601String(),
    };
  }

  /// Tolerant of older shapes: the legacy "bill/task" used `title`/`createdDate`
  /// with no `dueDate`; the previous single-bill version used a boolean
  /// `isPaid`. Both are migrated rather than dropped.
  factory Bill.fromJson(Map<String, dynamic> json) {
    final createdRaw = json['createdDate'] as String?;
    final created =
        createdRaw != null ? DateTime.parse(createdRaw) : DateTime.now();
    final dueRaw = json['dueDate'] as String?;
    final due = dueRaw != null ? DateTime.parse(dueRaw) : created;

    final paidRaw = json['paidMonths'] as List<dynamic>?;
    var paid = paidRaw
            ?.map((e) => DateTime.parse(e as String))
            .toList() ??
        <DateTime>[];
    // Migrate a legacy single isPaid=true into the due month being paid.
    if (paid.isEmpty && (json['isPaid'] as bool?) == true) {
      paid = [DateTime(due.year, due.month)];
    }

    final deadlineRaw = json['deadline'] as String?;

    return Bill(
      id: json['id'] as String,
      name: (json['name'] ?? json['title'] ?? 'Bill') as String,
      description: json['description'] as String?,
      amount: (json['amount'] as num?)?.toDouble(),
      dueDate: due,
      deadline: deadlineRaw != null ? DateTime.parse(deadlineRaw) : null,
      paidMonths: paid,
      createdDate: created,
    );
  }
}
