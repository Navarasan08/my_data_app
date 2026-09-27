import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_data_app/src/checklist/model/checklist_model.dart';
import 'package:my_data_app/src/checklist/repository/checklist_repository.dart';
import 'package:my_data_app/src/checklist/cubit/checklist_state.dart';

class ChecklistCubit extends Cubit<ChecklistState> {
  final ChecklistRepository _repository;
  StreamSubscription<void>? _sub;

  ChecklistCubit(this._repository)
    : super(
        ChecklistState(
          checklists: _repository.getAll(),
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
        checklists: _repository.getAll(),
        syncStatus: _repository.syncStatus,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }

  void addChecklist(ChecklistGroup group) {
    _repository.add(group);
    _sync();
  }

  void updateChecklist(ChecklistGroup group) {
    _repository.update(group);
    _sync();
  }

  void deleteChecklist(String groupId) {
    _repository.delete(groupId);
    _sync();
  }

  void addItem(String groupId, ChecklistItem item) {
    final group = state.checklists.firstWhere((c) => c.id == groupId);
    final updatedItems = List<ChecklistItem>.from(group.items)..add(item);
    _repository.update(group.copyWith(items: updatedItems));
    _sync();
  }

  void updateItem(String groupId, ChecklistItem item) {
    final group = state.checklists.firstWhere((c) => c.id == groupId);
    final updatedItems = List<ChecklistItem>.from(group.items);
    final index = updatedItems.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      updatedItems[index] = item;
    }
    _repository.update(group.copyWith(items: updatedItems));
    _sync();
  }

  void deleteItem(String groupId, String itemId) {
    final group = state.checklists.firstWhere((c) => c.id == groupId);
    final updatedItems = List<ChecklistItem>.from(group.items)
      ..removeWhere((i) => i.id == itemId);
    _repository.update(group.copyWith(items: updatedItems));
    _sync();
  }

  void toggleItem(String groupId, String itemId) {
    final group = state.checklists.firstWhere((c) => c.id == groupId);
    final updatedItems = List<ChecklistItem>.from(group.items);
    final index = updatedItems.indexWhere((i) => i.id == itemId);
    if (index != -1) {
      final item = updatedItems[index];
      updatedItems[index] = item.copyWith(
        isCompleted: !item.isCompleted,
        completedDate: !item.isCompleted ? DateTime.now() : null,
      );
    }
    _repository.update(group.copyWith(items: updatedItems));
    _sync();
  }

  ChecklistGroup? getChecklistById(String groupId) {
    final matches = state.checklists.where((c) => c.id == groupId);
    return matches.isNotEmpty ? matches.first : null;
  }
}
