import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_data_app/src/notifications/model/app_notification.dart';
import 'package:my_data_app/src/notifications/repository/notification_repository.dart';
import 'package:my_data_app/src/notifications/cubit/notification_state.dart';
import 'package:my_data_app/src/notifications/notification_service.dart';

/// Single point of contact for any module that wants to notify the user.
///
/// Producers should call [push] with a fully-formed [AppNotification]. The
/// cubit will dedupe by [AppNotification.dedupeKey], persist it, and (on
/// supported platforms) emit a local OS notification.
class NotificationCubit extends Cubit<NotificationState> {
  final NotificationRepository _repository;
  final LocalNotificationService _local;
  StreamSubscription<void>? _sub;

  NotificationCubit(this._repository, this._local)
    : super(
        NotificationState(
          items: _repository.getAll(),
          syncStatus: _repository.syncStatus,
        ),
      ) {
    _sub = _repository.changes.listen((_) => _sync());
  }

  /// Pulls the repository's current list and sync status into state. Runs
  /// on every realtime change and after each local write.
  void _sync() {
    emit(
      state.copyWith(
        items: _repository.getAll(),
        syncStatus: _repository.syncStatus,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }

  // ── Public API used by other modules ────────────────────────────────────

  /// Add or refresh a notification. If a notification with the same
  /// [AppNotification.dedupeKey] already exists, its content is updated and
  /// the existing OS notification is re-shown (e.g. severity escalates).
  void push(AppNotification n) {
    final existing = state.items
        .where((x) => x.dedupeKey == n.dedupeKey)
        .toList();
    if (existing.isNotEmpty) {
      // Refresh existing — keep id, but update body/severity/etc.
      final old = existing.first;
      final refreshed = n.copyWith(
        id: old.id,
        createdAt: old.createdAt,
        // Don't reset read state — but if severity escalated, mark unread
        isRead: n.severity == old.severity ? old.isRead : false,
        isDismissed: false,
      );
      _repository.update(refreshed);
      _local.show(refreshed);
      _sync();
      return;
    }
    _repository.add(n);
    _local.show(n);
    _sync();
  }

  /// Remove all notifications matching a given source. Producers call this
  /// when the underlying item resolves (e.g. the schedule task is completed).
  void resolve({
    required String sourceModule,
    required String sourceItemId,
    String? sourceDate,
  }) {
    final removed = state.items
        .where(
          (n) =>
              n.sourceModule == sourceModule &&
              n.sourceItemId == sourceItemId &&
              (sourceDate == null || n.sourceDate == sourceDate),
        )
        .toList();
    for (final n in removed) {
      _repository.delete(n.id);
      _local.cancel(n.id);
    }
    if (removed.isNotEmpty) _sync();
  }

  /// Remove every notification belonging to a source item (any date).
  void resolveAllFor(String sourceModule, String sourceItemId) {
    resolve(sourceModule: sourceModule, sourceItemId: sourceItemId);
  }

  // ── User actions ────────────────────────────────────────────────────────

  void markRead(String id) {
    final i = state.items.indexWhere((n) => n.id == id);
    if (i == -1) return;
    if (state.items[i].isRead) return;
    final updated = state.items[i].copyWith(isRead: true);
    _repository.update(updated);
    _sync();
  }

  void markAllRead() {
    bool changed = false;
    for (final n in state.items) {
      if (!n.isRead) {
        _repository.update(n.copyWith(isRead: true));
        changed = true;
      }
    }
    if (changed) _sync();
  }

  void dismiss(String id) {
    _repository.delete(id);
    _local.cancel(id);
    _sync();
  }

  void clearAll() {
    for (final n in state.items) {
      _local.cancel(n.id);
    }
    _repository.deleteAll();
    _sync();
  }

  // ── Computed ────────────────────────────────────────────────────────────

  int get unreadCount => state.items.where((n) => !n.isRead).length;

  List<AppNotification> get sorted {
    final list = List<AppNotification>.from(state.items);
    list.sort((a, b) {
      if (a.isRead != b.isRead) return a.isRead ? 1 : -1;
      return b.createdAt.compareTo(a.createdAt);
    });
    return list;
  }
}
