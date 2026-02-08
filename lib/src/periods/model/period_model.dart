class PeriodEntry {
  final String id;
  final DateTime startDate;
  final DateTime endDate;
  final String? notes;

  PeriodEntry({
    required this.id,
    required this.startDate,
    required this.endDate,
    this.notes,
  });

  int get periodLength => endDate.difference(startDate).inDays + 1;

  PeriodEntry copyWith({
    String? id,
    DateTime? startDate,
    DateTime? endDate,
    String? notes,
  }) {
    return PeriodEntry(
      id: id ?? this.id,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'notes': notes,
    };
  }

  factory PeriodEntry.fromJson(Map<String, dynamic> json) {
    return PeriodEntry(
      id: json['id'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      notes: json['notes'] as String?,
    );
  }
}
