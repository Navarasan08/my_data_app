import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_data_app/src/core/sync/firestore_list_store.dart';
import 'package:my_data_app/src/core/sync/sync_node.dart';
import 'package:my_data_app/src/events/model/event_model.dart';

abstract class EventRepository implements SyncNode {
  List<EventFund> getAllEvents();
  void addEvent(EventFund event);
  void updateEvent(EventFund event);
  void deleteEvent(String eventId);

  List<EventExpense> getExpensesFor(String eventId);
  void addExpense(EventExpense expense);
  void updateExpense(EventExpense expense);
  void deleteExpense(String eventId, String expenseId);
}

/// Listener-based Firestore implementation.
///
/// One realtime store for `events`, plus one store per event for its
/// `events/{id}/expenses` sub-collection. The expense stores are attached
/// and detached as events appear in and disappear from the event list, so
/// the set of listeners always mirrors the data.
class FirestoreEventRepository extends CompositeSyncNode
    implements EventRepository {
  final String uid;
  final CollectionReference<Map<String, dynamic>> _eventsCollection;
  final FirestoreListStore<EventFund> _events;
  final Map<String, FirestoreListStore<EventExpense>> _expenses = {};

  factory FirestoreEventRepository({
    required String uid,
    FirebaseFirestore? firestore,
  }) {
    final collection = (firestore ?? FirebaseFirestore.instance)
        .collection('users')
        .doc(uid)
        .collection('events');
    final events = FirestoreListStore<EventFund>(
      collection: collection,
      fromDoc: (json, _) => EventFund.fromJson(json),
      toJson: (e) => e.toJson(),
      idOf: (e) => e.id,
      debugLabel: 'events',
    );
    return FirestoreEventRepository._(uid, collection, events);
  }

  FirestoreEventRepository._(this.uid, this._eventsCollection, this._events)
    : super([_events]);

  @override
  void start() {
    super.start();
    _reconcile();
  }

  @override
  void onNodeChanged() => _reconcile();

  /// Returns the expense store for [eventId], creating and registering it
  /// on demand so a write issued before the event listener has caught up
  /// still lands in the right place.
  FirestoreListStore<EventExpense> _storeFor(String eventId) {
    return _expenses.putIfAbsent(eventId, () {
      final store = FirestoreListStore<EventExpense>(
        collection: _eventsCollection.doc(eventId).collection('expenses'),
        fromDoc: (json, _) => EventExpense.fromJson(json),
        toJson: (e) => e.toJson(),
        idOf: (e) => e.id,
        debugLabel: 'events/$eventId/expenses',
      );
      addNode(store);
      return store;
    });
  }

  /// Keeps one expense store per known event: attaches stores for new
  /// events and drops the stores of events that no longer exist.
  void _reconcile() {
    final ids = _events.items.map((e) => e.id).toSet();
    for (final id in ids) {
      _storeFor(id);
    }
    for (final id in _expenses.keys.where((k) => !ids.contains(k)).toList()) {
      final store = _expenses.remove(id)!;
      unawaited(removeNode(store));
    }
  }

  @override
  Future<void> dispose() async {
    await super.dispose();
    _expenses.clear();
  }

  // ── Events ──────────────────────────────────────────────────────────────

  @override
  List<EventFund> getAllEvents() => _events.items;

  @override
  void addEvent(EventFund event) => _events.save(event);

  @override
  void updateEvent(EventFund event) => _events.save(event);

  @override
  void deleteEvent(String eventId) {
    // Delete nested expenses first; the store is detached by the next
    // reconcile once the event is gone from the list.
    _expenses[eventId]?.removeWhere((_) => true);
    _events.remove(eventId);
  }

  // ── Expenses ────────────────────────────────────────────────────────────

  @override
  List<EventExpense> getExpensesFor(String eventId) =>
      _expenses[eventId]?.items ?? const [];

  @override
  void addExpense(EventExpense expense) =>
      _storeFor(expense.eventId).save(expense);

  @override
  void updateExpense(EventExpense expense) =>
      _storeFor(expense.eventId).save(expense);

  @override
  void deleteExpense(String eventId, String expenseId) =>
      _storeFor(eventId).remove(expenseId);
}
