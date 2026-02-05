enum RecurrenceType { daily, weekly, monthly, custom }

class BillTask {
  final String id;
  final String title;
  final String? description;
  final double? amount;
  final RecurrenceType recurrence;
  final List<int>? customDays; // For custom recurrence (day of month)
  final DateTime createdDate;
  final List<DateTime> completedOccurrences;

  BillTask({
    required this.id,
    required this.title,
    this.description,
    this.amount,
    required this.recurrence,
    this.customDays,
    required this.createdDate,
    this.completedOccurrences = const [],
  });

  BillTask copyWith({
    String? id,
    String? title,
    String? description,
    double? amount,
    RecurrenceType? recurrence,
    List<int>? customDays,
    DateTime? createdDate,
    List<DateTime>? completedOccurrences,
  }) {
    return BillTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      recurrence: recurrence ?? this.recurrence,
      customDays: customDays ?? this.customDays,
      createdDate: createdDate ?? this.createdDate,
      completedOccurrences: completedOccurrences ?? this.completedOccurrences,
    );
  }

  bool isCompletedForDate(DateTime date) {
    return completedOccurrences.any((completed) =>
        completed.year == date.year &&
        completed.month == date.month &&
        completed.day == date.day);
  }

  bool isDueForDate(DateTime date) {
    switch (recurrence) {
      case RecurrenceType.daily:
        return true;
      case RecurrenceType.weekly:
        return date.weekday == createdDate.weekday;
      case RecurrenceType.monthly:
        return date.day == createdDate.day;
      case RecurrenceType.custom:
        return customDays?.contains(date.day) ?? false;
    }
  }
}
