import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:my_data_app/src/core/sync/sync_node.dart';
import 'package:my_data_app/src/core/sync/sync_snapshot.dart';

/// Builds a [T] from a Firestore document's data and id.
typedef DocMapper<T> = T Function(Map<String, dynamic> json, String id);

/// A realtime, cache-first view of one Firestore query.
///
/// Attach it once with [start]; Firestore then delivers the cached contents
/// immediately and streams every server change after that, including writes
/// made on other devices. There is nothing to refresh and nothing to retry —
/// the SDK reconnects and re-syncs on its own.
///
/// Documents that fail to parse are skipped (and reported in debug builds)
/// rather than taking the whole collection down with them.
class FirestoreCollectionSource<T> implements SyncNode {
  final Query<Map<String, dynamic>> query;
  final DocMapper<T> fromDoc;

  /// Used only in debug logging.
  final String debugLabel;

  final _controller = StreamController<SyncSnapshot<List<T>>>.broadcast();
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  SyncSnapshot<List<T>> _current;

  FirestoreCollectionSource({
    required this.query,
    required this.fromDoc,
    this.debugLabel = 'collection',
  }) : _current = SyncSnapshot<List<T>>(
         data: const [],
         status: SyncStatus.loading,
       );

  /// Latest snapshot. Safe to read before [start]; it is then `loading`.
  SyncSnapshot<List<T>> get current => _current;

  /// Emits on every change after [start]. Read [current] for the value at
  /// subscription time; this stream does not replay it.
  Stream<SyncSnapshot<List<T>>> get stream => _controller.stream;

  bool get isStarted => _sub != null;

  @override
  SyncStatus get syncStatus => _current.status;

  @override
  bool get hasPendingWrites => _current.hasPendingWrites;

  @override
  Stream<void> get changes => _controller.stream;

  /// Attaches the listener. Calling it again is a no-op.
  DateTime? _startedAt;

  @override
  void start() {
    if (_sub != null) return;
    _startedAt = DateTime.now();
    _sub = query
        .snapshots(includeMetadataChanges: true)
        .listen(_onSnapshot, onError: _onError);
  }

  void _onSnapshot(QuerySnapshot<Map<String, dynamic>> snap) {
    if (!kReleaseMode && _startedAt != null) {
      final ms = DateTime.now().difference(_startedAt!).inMilliseconds;
      debugPrint(
        '[sync] $debugLabel: ${snap.docs.length} docs, '
        '${snap.metadata.isFromCache ? "cache" : "server"}, +${ms}ms',
      );
    }
    final items = <T>[];
    for (final doc in snap.docs) {
      try {
        items.add(fromDoc(doc.data(), doc.id));
      } catch (e) {
        if (kDebugMode) debugPrint('[$debugLabel] skipped doc ${doc.id}: $e');
      }
    }
    _emit(
      SyncSnapshot<List<T>>(
        data: List.unmodifiable(items),
        status: snap.metadata.isFromCache ? SyncStatus.cached : SyncStatus.live,
        hasPendingWrites: snap.metadata.hasPendingWrites,
      ),
    );
  }

  void _onError(Object error, StackTrace st) {
    if (kDebugMode) debugPrint('[$debugLabel] listener error: $error');
    // Keep whatever data we had; just record the error.
    _emit(_current.copyWith(error: error));
  }

  void _emit(SyncSnapshot<List<T>> next) {
    _current = next;
    if (!_controller.isClosed) _controller.add(next);
  }

  @override
  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
    await _controller.close();
  }
}
