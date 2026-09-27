import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_data_app/src/core/sync/firestore_collection_source.dart';
import 'package:my_data_app/src/core/sync/sync_node.dart';
import 'package:my_data_app/src/core/sync/sync_snapshot.dart';

/// A realtime list of [T] backed by one Firestore collection, with
/// optimistic local writes.
///
/// Reads come from a [FirestoreCollectionSource] listener. Writes are applied
/// to the local list at once (so `save(x); items` already contains `x`),
/// sent to Firestore without awaiting, and then confirmed by the next
/// listener snapshot, which always includes local writes thanks to latency
/// compensation. That keeps the old synchronous repository contract that the
/// cubits rely on while making the listener the single source of truth.
class FirestoreListStore<T> implements SyncNode {
  final CollectionReference<Map<String, dynamic>> collection;
  final Map<String, dynamic> Function(T item) toJson;
  final String Function(T item) idOf;
  final String debugLabel;

  final FirestoreCollectionSource<T> _source;
  final _controller = StreamController<SyncSnapshot<List<T>>>.broadcast();
  StreamSubscription<SyncSnapshot<List<T>>>? _sub;

  /// Local overlay applied after a write, dropped on the next snapshot.
  List<T>? _overlay;

  FirestoreListStore({
    required this.collection,
    required DocMapper<T> fromDoc,
    required this.toJson,
    required this.idOf,
    Query<Map<String, dynamic>>? query,
    this.debugLabel = 'list',
  }) : _source = FirestoreCollectionSource<T>(
         query: query ?? collection,
         fromDoc: fromDoc,
         debugLabel: debugLabel,
       );

  /// Current items, including not-yet-confirmed local writes. Unmodifiable.
  List<T> get items => _overlay ?? _source.current.data;

  SyncSnapshot<List<T>> get snapshot => SyncSnapshot<List<T>>(
    data: items,
    status: _source.current.status,
    hasPendingWrites: _overlay != null || _source.current.hasPendingWrites,
    error: _source.current.error,
  );

  /// Emits the new [snapshot] after every remote or local change.
  Stream<SyncSnapshot<List<T>>> get stream => _controller.stream;

  @override
  SyncStatus get syncStatus => _source.current.status;

  @override
  bool get hasPendingWrites => snapshot.hasPendingWrites;

  @override
  Stream<void> get changes => _controller.stream;

  bool get isStarted => _source.isStarted;

  @override
  void start() {
    if (_sub != null) return;
    _sub = _source.stream.listen((_) {
      _overlay = null;
      _emit();
    });
    _source.start();
  }

  T? byId(String id) {
    for (final item in items) {
      if (idOf(item) == id) return item;
    }
    return null;
  }

  /// Inserts or replaces [item] locally and writes it to Firestore.
  void save(T item) {
    final id = idOf(item);
    final list = List<T>.of(items);
    final i = list.indexWhere((e) => idOf(e) == id);
    if (i >= 0) {
      list[i] = item;
    } else {
      list.add(item);
    }
    _overlay = List.unmodifiable(list);
    _emit();
    fireAndForget(collection.doc(id).set(toJson(item)), label: debugLabel);
  }

  /// Removes the item with [id] locally and deletes it from Firestore.
  void remove(String id) {
    _overlay = List.unmodifiable(items.where((e) => idOf(e) != id));
    _emit();
    fireAndForget(collection.doc(id).delete(), label: debugLabel);
  }

  /// Removes every item matching [test] locally and deletes them from
  /// Firestore in batches of 500 (the per-batch limit).
  void removeWhere(bool Function(T item) test) {
    final doomed = items.where(test).map(idOf).toList();
    if (doomed.isEmpty) return;
    _overlay = List.unmodifiable(items.where((e) => !test(e)));
    _emit();
    final db = collection.firestore;
    for (var i = 0; i < doomed.length; i += 500) {
      final batch = db.batch();
      for (final id in doomed.skip(i).take(500)) {
        batch.delete(collection.doc(id));
      }
      fireAndForget(batch.commit(), label: debugLabel);
    }
  }

  void _emit() {
    if (!_controller.isClosed) _controller.add(snapshot);
  }

  @override
  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
    await _source.dispose();
    await _controller.close();
  }
}
