import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_data_app/src/diet/cubit/diet_state.dart';
import 'package:my_data_app/src/diet/model/diet_model.dart';
import 'package:my_data_app/src/diet/repository/diet_repository.dart';

class DietCubit extends Cubit<DietState> {
  final DietRepository _repository;

  DietCubit(this._repository)
      : super(DietState(
          items: _repository.getItems(),
          entries: _repository.getEntries(),
          selectedMonth: DateTime(DateTime.now().year, DateTime.now().month, 1),
        ));

  /// Re-emits state from the repository after a background server refresh.
  void reloadFromRepository() {
    emit(state.copyWith(
      items: _repository.getItems(),
      entries: _repository.getEntries(),
    ));
  }

  // ── Food items ──────────────────────────────────────────────────────────

  void addItem(FoodItem item) {
    _repository.addItem(item);
    emit(state.copyWith(items: _repository.getItems()));
  }

  void updateItem(FoodItem item) {
    _repository.updateItem(item.copyWith(updatedAt: DateTime.now()));
    emit(state.copyWith(items: _repository.getItems()));
  }

  void deleteItem(String itemId) {
    _repository.deleteItem(itemId);
    emit(state.copyWith(
      items: _repository.getItems(),
      entries: _repository.getEntries(),
    ));
  }

  FoodItem? itemById(String id) {
    final hits = state.items.where((i) => i.id == id);
    return hits.isEmpty ? null : hits.first;
  }

  // ── Food entries ────────────────────────────────────────────────────────

  void addEntry(FoodEntry entry) {
    _repository.addEntry(entry);
    emit(state.copyWith(entries: _repository.getEntries()));
  }

  void updateEntry(FoodEntry entry) {
    _repository.updateEntry(entry);
    emit(state.copyWith(entries: _repository.getEntries()));
  }

  void deleteEntry(String entryId) {
    _repository.deleteEntry(entryId);
    emit(state.copyWith(entries: _repository.getEntries()));
  }

  // ── Month navigation ────────────────────────────────────────────────────

  void changeMonth(int delta) {
    final cur = state.selectedMonth;
    emit(state.copyWith(
      selectedMonth: DateTime(cur.year, cur.month + delta, 1),
    ));
  }

  void resetToCurrentMonth() {
    final now = DateTime.now();
    emit(state.copyWith(selectedMonth: DateTime(now.year, now.month, 1)));
  }

  // ── Aggregates ──────────────────────────────────────────────────────────

  /// Total consumed quantity per item for a specific year+month.
  Map<String, double> consumedInMonth(int year, int month) {
    final out = <String, double>{};
    for (final e in state.entries) {
      if (e.date.year != year || e.date.month != month) continue;
      out[e.foodItemId] = (out[e.foodItemId] ?? 0) + e.quantity;
    }
    return out;
  }

  /// Total for [item] in the currently selected month.
  double consumedThisMonth(String itemId) {
    final m = state.selectedMonth;
    return consumedInMonth(m.year, m.month)[itemId] ?? 0;
  }

  /// Entries for an item within the selected month, newest first.
  List<FoodEntry> entriesForItemInMonth(String itemId) {
    final m = state.selectedMonth;
    return state.entries
        .where((e) =>
            e.foodItemId == itemId &&
            e.date.year == m.year &&
            e.date.month == m.month)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// `monthlyLimit - consumed` clamped to >= 0. Returns null when the item
  /// has no limit configured.
  double? remainingThisMonth(FoodItem item) {
    if (item.monthlyLimit == null) return null;
    final used = consumedThisMonth(item.id);
    final left = item.monthlyLimit! - used;
    return left < 0 ? 0 : left;
  }

  /// 12-month consumption series for one item (oldest → newest), used by
  /// the analysis page.
  Map<DateTime, double> monthlySeries(String itemId, {int months = 12}) {
    final now = DateTime.now();
    final result = <DateTime, double>{};
    for (int i = months - 1; i >= 0; i--) {
      final m = DateTime(now.year, now.month - i, 1);
      final total = state.entries
          .where((e) =>
              e.foodItemId == itemId &&
              e.date.year == m.year &&
              e.date.month == m.month)
          .fold<double>(0, (s, e) => s + e.quantity);
      result[m] = total;
    }
    return result;
  }

  /// Aggregate consumption per item across the last [months] months,
  /// used by the analysis page's leaderboard.
  Map<String, double> totalsLastNMonths({int months = 12}) {
    final now = DateTime.now();
    final cutoff = DateTime(now.year, now.month - (months - 1), 1);
    final out = <String, double>{};
    for (final e in state.entries) {
      if (e.date.isBefore(cutoff)) continue;
      out[e.foodItemId] = (out[e.foodItemId] ?? 0) + e.quantity;
    }
    return out;
  }

  /// Count of entries this month — used as the dashboard badge count.
  int get entriesThisMonthCount {
    final m = state.selectedMonth;
    return state.entries
        .where((e) => e.date.year == m.year && e.date.month == m.month)
        .length;
  }
}
