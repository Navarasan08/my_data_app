class ChecklistItem {
  final String id;
  final String title;
  final bool isCompleted;
  final DateTime? completedDate;

  ChecklistItem({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.completedDate,
  });

  ChecklistItem copyWith({
    String? id,
    String? title,
    bool? isCompleted,
    DateTime? completedDate,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      completedDate: completedDate ?? this.completedDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
      'completedDate': completedDate?.toIso8601String(),
    };
  }

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      id: json['id'] as String,
      title: json['title'] as String,
      isCompleted: json['isCompleted'] as bool? ?? false,
      completedDate: json['completedDate'] != null
          ? DateTime.parse(json['completedDate'] as String)
          : null,
    );
  }
}

class ChecklistGroup {
  final String id;
  final String name;
  final String? description;
  final DateTime targetDate;
  final DateTime createdDate;
  final List<ChecklistItem> items;

  ChecklistGroup({
    required this.id,
    required this.name,
    this.description,
    required this.targetDate,
    required this.createdDate,
    this.items = const [],
  });

  int get totalItems => items.length;
  int get completedItems => items.where((i) => i.isCompleted).length;
  double get progress => totalItems == 0 ? 0 : completedItems / totalItems;
  bool get isAllCompleted => totalItems > 0 && completedItems == totalItems;

  int get daysLeft {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(targetDate.year, targetDate.month, targetDate.day);
    return target.difference(today).inDays;
  }

  ChecklistGroup copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? targetDate,
    DateTime? createdDate,
    List<ChecklistItem>? items,
  }) {
    return ChecklistGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      targetDate: targetDate ?? this.targetDate,
      createdDate: createdDate ?? this.createdDate,
      items: items ?? this.items,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'targetDate': targetDate.toIso8601String(),
      'createdDate': createdDate.toIso8601String(),
      'items': items.map((i) => i.toJson()).toList(),
    };
  }

  factory ChecklistGroup.fromJson(Map<String, dynamic> json) {
    return ChecklistGroup(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      targetDate: DateTime.parse(json['targetDate'] as String),
      createdDate: DateTime.parse(json['createdDate'] as String),
      items: (json['items'] as List<dynamic>?)
              ?.map((i) => ChecklistItem.fromJson(i as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
