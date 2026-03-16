import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_data_app/src/money_owe/model/money_owe_model.dart';
import 'package:my_data_app/src/money_owe/repository/money_owe_repository.dart';
import 'package:my_data_app/src/money_owe/cubit/money_owe_state.dart';

class MoneyOweCubit extends Cubit<MoneyOweState> {
  final MoneyOweRepository _repository;

  MoneyOweCubit(this._repository)
      : super(MoneyOweState(entries: _repository.getAll()));

  void addEntry(DebtEntry entry) {
    _repository.add(entry);
    emit(state.copyWith(entries: _repository.getAll()));
  }

  void updateEntry(DebtEntry entry) {
    _repository.update(entry);
    emit(state.copyWith(entries: _repository.getAll()));
  }

  void deleteEntry(String id) {
    _repository.delete(id);
    emit(state.copyWith(entries: _repository.getAll()));
  }

  void addSettlement(String entryId, DebtSettlement settlement) {
    final entry = state.entries.firstWhere((e) => e.id == entryId);
    final updated = entry.copyWith(
      settlements: [...entry.settlements, settlement],
      isSettled: entry.pendingAmount - settlement.amount <= 0,
    );
    _repository.update(updated);
    emit(state.copyWith(entries: _repository.getAll()));
  }

  void markSettled(String entryId) {
    final entry = state.entries.firstWhere((e) => e.id == entryId);
    _repository.update(entry.copyWith(isSettled: true));
    emit(state.copyWith(entries: _repository.getAll()));
  }

  List<DebtEntry> get lentEntries =>
      state.entries.where((e) => e.direction == DebtDirection.lent).toList();

  List<DebtEntry> get borrowedEntries =>
      state.entries.where((e) => e.direction == DebtDirection.borrowed).toList();

  List<DebtEntry> get pendingEntries =>
      state.entries.where((e) => !e.isFullySettled && !e.isSettled).toList();

  double get totalLentPending => lentEntries
      .where((e) => !e.isFullySettled)
      .fold(0.0, (sum, e) => sum + e.pendingAmount);

  double get totalBorrowedPending => borrowedEntries
      .where((e) => !e.isFullySettled)
      .fold(0.0, (sum, e) => sum + e.pendingAmount);

  /// Group by person name
  Map<String, List<DebtEntry>> get groupedByPerson {
    final map = <String, List<DebtEntry>>{};
    for (final e in state.entries) {
      (map[e.personName] ??= []).add(e);
    }
    return map;
  }

  /// Net amount per person (positive = they owe me, negative = I owe them)
  Map<String, double> get netByPerson {
    final map = <String, double>{};
    for (final e in state.entries) {
      final pending = e.pendingAmount;
      if (e.direction == DebtDirection.lent) {
        map[e.personName] = (map[e.personName] ?? 0) + pending;
      } else {
        map[e.personName] = (map[e.personName] ?? 0) - pending;
      }
    }
    return map;
  }
}
