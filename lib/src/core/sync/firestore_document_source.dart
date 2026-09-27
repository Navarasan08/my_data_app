import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:my_data_app/src/core/sync/sync_node.dart';
import 'package:my_data_app/src/core/sync/sync_snapshot.dart';

/// A realtime, cache-first view of one Firestore document — typically a
/// per-module settings doc. Mirrors [FirestoreCollectionSource].
///
/// [fromDoc] receives `null` when the document does not exist, so it can
/// return defaults.
class FirestoreDocumentSource<T> implements SyncNode {
  final DocumentReference<Map<String, dynamic>> ref;
  final T Function(Map<String, dynamic>? json) fromDoc;
  final String debugLabel;

  final _controller = StreamController<SyncSnapshot<T>>.broadcast();
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;
  SyncSnapshot<T> _current;

  FirestoreDocumentSource({
    required this.ref,
    required this.fromDoc,
    required T initial,
    this.debugLabel = 'document',
  }) : _current = SyncSnapshot<T>(data: initial, status: SyncStatus.loading);

  SyncSnapshot<T> get current => _current;
  Stream<SyncSnapshot<T>> get stream => _controller.stream;
  bool get isStarted => _sub != null;

  @override
  SyncStatus get syncStatus => _current.status;

  @override
  bool get hasPendingWrites => _current.hasPendingWrites;

  @override
  Stream<void> get changes => _controller.stream;

  @override
  void start() {
    if (_sub != null) return;
    _sub = ref
        .snapshots(includeMetadataChanges: true)
        .listen(_onSnapshot, onError: _onError);
  }

  void _onSnapshot(DocumentSnapshot<Map<String, dynamic>> snap) {
    T value;
    try {
      value = fromDoc(snap.exists ? snap.data() : null);
    } catch (e) {
      if (kDebugMode) debugPrint('[$debugLabel] parse failed: $e');
      // Keep the previous value; only the metadata moves on.
      value = _current.data;
    }
    _emit(
      SyncSnapshot<T>(
        data: value,
        status: snap.metadata.isFromCache ? SyncStatus.cached : SyncStatus.live,
        hasPendingWrites: snap.metadata.hasPendingWrites,
      ),
    );
  }

  void _onError(Object error, StackTrace st) {
    if (kDebugMode) debugPrint('[$debugLabel] listener error: $error');
    _emit(_current.copyWith(error: error));
  }

  void _emit(SyncSnapshot<T> next) {
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
