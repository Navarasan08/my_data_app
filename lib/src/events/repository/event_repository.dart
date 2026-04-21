import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_data_app/src/events/model/event_model.dart';

abstract class EventRepository {
  List<EventFund> getAllEvents();
  void addEvent(EventFund event);
  void updateEvent(EventFund event);
  void deleteEvent(String eventId);

  List<EventExpense> getExpensesFor(String eventId);
  void addExpense(EventExpense expense);
  void updateExpense(EventExpense expense);
  void deleteExpense(String eventId, String expenseId);

  Future<void> init();
}

class FirestoreEventRepository implements EventRepository {
  final String uid;
  final FirebaseFirestore _firestore;

  List<EventFund> _events = [];
  final Map<String, List<EventExpense>> _expenses = {};

  FirestoreEventRepository({
    required this.uid,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _eventsCollection =>
      _firestore.collection('users').doc(uid).collection('events');

  CollectionReference<Map<String, dynamic>> _expensesCollection(String eventId) =>
      _eventsCollection.doc(eventId).collection('expenses');

  @override
  Future<void> init() async {
    final evSnap = await _eventsCollection.get();
    _events = evSnap.docs.map((d) => EventFund.fromJson(d.data())).toList();

    // Lazy-load expenses in parallel for each event
    await Future.wait(_events.map((e) async {
      final expSnap = await _expensesCollection(e.id).get();
      _expenses[e.id] =
          expSnap.docs.map((d) => EventExpense.fromJson(d.data())).toList();
    }));
  }

  @override
  List<EventFund> getAllEvents() => List.unmodifiable(_events);

  @override
  void addEvent(EventFund event) {
    _events.add(event);
    _expenses[event.id] = [];
    _eventsCollection.doc(event.id).set(event.toJson());
  }

  @override
  void updateEvent(EventFund event) {
    final i = _events.indexWhere((e) => e.id == event.id);
    if (i != -1) {
      _events[i] = event;
      _eventsCollection.doc(event.id).set(event.toJson());
    }
  }

  @override
  void deleteEvent(String eventId) {
    _events.removeWhere((e) => e.id == eventId);
    final ex = _expenses.remove(eventId) ?? const [];
    _eventsCollection.doc(eventId).delete();
    // Delete nested expenses best-effort
    for (final e in ex) {
      _expensesCollection(eventId).doc(e.id).delete();
    }
  }

  @override
  List<EventExpense> getExpensesFor(String eventId) =>
      List.unmodifiable(_expenses[eventId] ?? const []);

  @override
  void addExpense(EventExpense expense) {
    (_expenses[expense.eventId] ??= []).add(expense);
    _expensesCollection(expense.eventId).doc(expense.id).set(expense.toJson());
  }

  @override
  void updateExpense(EventExpense expense) {
    final list = _expenses[expense.eventId];
    if (list == null) return;
    final i = list.indexWhere((e) => e.id == expense.id);
    if (i != -1) {
      list[i] = expense;
      _expensesCollection(expense.eventId)
          .doc(expense.id)
          .set(expense.toJson());
    }
  }

  @override
  void deleteExpense(String eventId, String expenseId) {
    _expenses[eventId]?.removeWhere((e) => e.id == expenseId);
    _expensesCollection(eventId).doc(expenseId).delete();
  }
}
