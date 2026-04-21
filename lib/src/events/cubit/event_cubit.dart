import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_data_app/src/events/model/event_model.dart';
import 'package:my_data_app/src/events/repository/event_repository.dart';
import 'package:my_data_app/src/events/cubit/event_state.dart';

class EventCubit extends Cubit<EventState> {
  final EventRepository _repository;

  EventCubit(this._repository)
      : super(EventState(
          events: _repository.getAllEvents(),
          expensesByEvent: _buildMap(_repository),
        ));

  static Map<String, List<EventExpense>> _buildMap(EventRepository repo) {
    final map = <String, List<EventExpense>>{};
    for (final e in repo.getAllEvents()) {
      map[e.id] = repo.getExpensesFor(e.id);
    }
    return map;
  }

  // ── Events ──────────────────────────────────────────────────────────────

  void addEvent(EventFund event) {
    _repository.addEvent(event);
    emit(state.copyWith(
      events: _repository.getAllEvents(),
      expensesByEvent: _buildMap(_repository),
    ));
  }

  void updateEvent(EventFund event) {
    _repository.updateEvent(event);
    emit(state.copyWith(events: _repository.getAllEvents()));
  }

  void deleteEvent(String eventId) {
    _repository.deleteEvent(eventId);
    emit(state.copyWith(
      events: _repository.getAllEvents(),
      expensesByEvent: _buildMap(_repository),
    ));
  }

  void toggleArchive(String eventId) {
    final e = state.events.firstWhere((x) => x.id == eventId);
    updateEvent(e.copyWith(
      isArchived: !e.isArchived,
      updatedAt: DateTime.now(),
    ));
  }

  EventFund? getEvent(String eventId) {
    final matches = state.events.where((e) => e.id == eventId);
    return matches.isNotEmpty ? matches.first : null;
  }

  // ── Expenses ────────────────────────────────────────────────────────────

  void addExpense(EventExpense expense) {
    _repository.addExpense(expense);
    emit(state.copyWith(expensesByEvent: _buildMap(_repository)));
  }

  void updateExpense(EventExpense expense) {
    _repository.updateExpense(expense);
    emit(state.copyWith(expensesByEvent: _buildMap(_repository)));
  }

  void deleteExpense(String eventId, String expenseId) {
    _repository.deleteExpense(eventId, expenseId);
    emit(state.copyWith(expensesByEvent: _buildMap(_repository)));
  }

  // ── Computed ────────────────────────────────────────────────────────────

  List<EventExpense> expensesFor(String eventId) =>
      state.expensesByEvent[eventId] ?? const [];

  double totalSpentFor(String eventId) =>
      expensesFor(eventId).fold(0.0, (s, e) => s + e.amount);

  /// Sum grouped by category for an event.
  Map<String, double> categoryBreakdown(String eventId) {
    final map = <String, double>{};
    for (final e in expensesFor(eventId)) {
      final key = (e.category?.trim().isEmpty ?? true) ? 'Uncategorized' : e.category!.trim();
      map[key] = (map[key] ?? 0) + e.amount;
    }
    return map;
  }

  /// Distinct categories previously used in this event (for chip suggestions).
  List<String> categoriesUsed(String eventId) {
    final set = <String>{};
    for (final e in expensesFor(eventId)) {
      final c = e.category?.trim();
      if (c != null && c.isNotEmpty) set.add(c);
    }
    return set.toList()..sort();
  }

  List<EventFund> get activeEvents =>
      state.events.where((e) => !e.isArchived).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  List<EventFund> get archivedEvents =>
      state.events.where((e) => e.isArchived).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
}
