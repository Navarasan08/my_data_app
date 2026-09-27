/// One line of a checklist inside a note.
class NoteItem {
  final String id;
  final String text;
  final bool done;

  const NoteItem({required this.id, required this.text, this.done = false});

  NoteItem copyWith({String? text, bool? done}) =>
      NoteItem(id: id, text: text ?? this.text, done: done ?? this.done);

  Map<String, dynamic> toJson() => {'id': id, 'text': text, 'done': done};

  factory NoteItem.fromJson(Map<String, dynamic> json) => NoteItem(
    id: json['id'] as String,
    text: json['text'] as String? ?? '',
    done: json['done'] as bool? ?? false,
  );
}

/// A quick note in the Apple Notes sense: free text, an optional checklist,
/// or both. Pinned notes stay at the top.
class QuickNote {
  final String id;
  final String title;
  final String body;
  final List<NoteItem> items;
  final bool pinned;
  final DateTime createdAt;
  final DateTime updatedAt;

  const QuickNote({
    required this.id,
    this.title = '',
    this.body = '',
    this.items = const [],
    this.pinned = false,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isEmpty =>
      title.trim().isEmpty && body.trim().isEmpty && items.isEmpty;
  bool get hasChecklist => items.isNotEmpty;
  int get doneCount => items.where((i) => i.done).length;

  /// Title to show in lists: the title, or the first line of the body, or
  /// the first checklist item.
  String get displayTitle {
    if (title.trim().isNotEmpty) return title.trim();
    final firstLine = body.trim().split('\n').first.trim();
    if (firstLine.isNotEmpty) return firstLine;
    if (items.isNotEmpty) return items.first.text;
    return 'New note';
  }

  /// Short body preview, skipping the line used as the title.
  String get preview {
    final lines = body
        .trim()
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (title.trim().isEmpty && lines.isNotEmpty) lines.removeAt(0);
    return lines.take(3).join(' · ');
  }

  QuickNote copyWith({
    String? title,
    String? body,
    List<NoteItem>? items,
    bool? pinned,
    DateTime? updatedAt,
  }) => QuickNote(
    id: id,
    title: title ?? this.title,
    body: body ?? this.body,
    items: items ?? this.items,
    pinned: pinned ?? this.pinned,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'items': items.map((i) => i.toJson()).toList(),
    'pinned': pinned,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory QuickNote.fromJson(Map<String, dynamic> json) => QuickNote(
    id: json['id'] as String,
    title: json['title'] as String? ?? '',
    body: json['body'] as String? ?? '',
    items: (json['items'] as List<dynamic>? ?? const [])
        .map((e) => NoteItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    pinned: json['pinned'] as bool? ?? false,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
}
