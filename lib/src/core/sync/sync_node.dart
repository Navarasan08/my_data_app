import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:my_data_app/src/core/sync/sync_snapshot.dart';

/// Anything that streams from Firestore and can report its sync state:
/// a collection source, a document source, a list store, or a whole
/// repository composed of several of those.
abstract interface class SyncNode {
  SyncStatus get syncStatus;
  bool get hasPendingWrites;

  /// Fires after every change. Carries no payload: read the node's current
  /// value after the event. Delivery is asynchronous (next microtask).
  Stream<void> get changes;

  /// Attaches listeners. Idempotent.
  void start();

  Future<void> dispose();
}

/// Fire-and-forget a Firestore write.
///
/// Firestore applies writes to the local cache immediately and syncs them
/// when it can, so awaiting them would only make the UI wait on the network.
/// Failures (rules, quota) are logged instead of surfacing as unhandled
/// async errors.
void fireAndForget(Future<void> future, {String label = 'firestore'}) {
  unawaited(
    future.catchError((Object e) {
      if (kDebugMode) debugPrint('[$label] write failed: $e');
    }),
  );
}

/// Folds several nodes into one: status is the weakest of the parts,
/// pending writes if any part has them, and `changes` fires when any part
/// changes. Subclass this for a repository made of more than one collection.
///
/// Children can also be added and removed after construction (see
/// [addNode] / [removeNode]) for repositories whose set of listeners depends
/// on data, such as one sub-collection per parent document.
abstract class CompositeSyncNode implements SyncNode {
  final List<SyncNode> _nodes = [];
  final Map<SyncNode, StreamSubscription<void>> _subs = {};
  final _changes = StreamController<void>.broadcast();
  bool _started = false;

  CompositeSyncNode(List<SyncNode> nodes) {
    _nodes.addAll(nodes);
  }

  @protected
  List<SyncNode> get nodes => List.unmodifiable(_nodes);

  @override
  SyncStatus get syncStatus =>
      combineSyncStatus(_nodes.map((n) => n.syncStatus));

  @override
  bool get hasPendingWrites => _nodes.any((n) => n.hasPendingWrites);

  @override
  Stream<void> get changes => _changes.stream;

  bool get isStarted => _started;

  /// Subclasses may override to react before listeners are notified, e.g.
  /// to re-derive data that depends on more than one node.
  @protected
  void onNodeChanged() {}

  /// Registers [node]; it is started immediately if this composite already
  /// is.
  @protected
  void addNode(SyncNode node) {
    if (_nodes.contains(node)) return;
    _nodes.add(node);
    if (_started) _attach(node);
  }

  /// Unregisters and disposes [node].
  @protected
  Future<void> removeNode(SyncNode node) async {
    if (!_nodes.remove(node)) return;
    await _subs.remove(node)?.cancel();
    await node.dispose();
  }

  void _attach(SyncNode node) {
    _subs[node] = node.changes.listen((_) {
      onNodeChanged();
      _notify();
    });
    node.start();
  }

  /// Fires [changes] without any child having changed, e.g. after a
  /// composite-level local write.
  @protected
  void notifyChanged() => _notify();

  void _notify() {
    if (!_changes.isClosed) _changes.add(null);
  }

  @override
  void start() {
    if (_started) return;
    _started = true;
    for (final n in List<SyncNode>.of(_nodes)) {
      _attach(n);
    }
  }

  @override
  Future<void> dispose() async {
    for (final s in _subs.values) {
      await s.cancel();
    }
    _subs.clear();
    await Future.wait(_nodes.map((n) => n.dispose()));
    _nodes.clear();
    await _changes.close();
  }
}
