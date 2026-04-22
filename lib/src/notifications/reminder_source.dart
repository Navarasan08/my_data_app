/// One pending reminder item produced by a [ReminderSource].
///
/// The sweeper turns each [ReminderItem] into an [AppNotification] with the
/// appropriate severity based on how far away [dueDate] is from today.
class ReminderItem {
  final String itemId;
  final DateTime dueDate;
  final String title;

  /// Optional override for the body text. If null, the sweeper auto-fills
  /// "Coming up in 2 days" / "Tomorrow" / "Due today" / "Missed yesterday".
  final String? body;

  /// Free-form metadata carried into the notification (e.g. category name).
  final Map<String, String> meta;

  const ReminderItem({
    required this.itemId,
    required this.dueDate,
    required this.title,
    this.body,
    this.meta = const {},
  });

  /// yyyy-MM-dd key used in notification dedupe so the same item across
  /// multiple due dates produces distinct notifications.
  String get dateKey {
    final y = dueDate.year.toString().padLeft(4, '0');
    final m = dueDate.month.toString().padLeft(2, '0');
    final d = dueDate.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

/// A pluggable source of reminders.
///
/// Any module that wants to emit "task due soon" notifications implements
/// this interface and is registered with [ReminderSweeper]. The sweeper
/// handles scheduling, severity, dedupe, and auto-resolve — the source just
/// answers "what's pending in this window?".
abstract class ReminderSource {
  /// Stable module identifier — also used as `sourceModule` on the resulting
  /// notifications and as the routing key in [MainShell].
  String get module;

  /// Stream that fires whenever the source data changes. The sweeper
  /// listens to this and re-runs immediately, so completing/deleting a task
  /// makes its notification disappear right away.
  ///
  /// Most sources will return their cubit's `stream`.
  Stream<dynamic> get changes;

  /// Return every item due in [windowStart, windowEnd] that is **not** yet
  /// done. The sweeper does the rest.
  ///
  /// The window is typically `[yesterday, today + 2 days]`.
  List<ReminderItem> pendingIn(DateTime windowStart, DateTime windowEnd);
}
