import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_data_app/src/profile_vault/model/profile_vault_model.dart';
import 'package:my_data_app/src/profile_vault/repository/profile_vault_repository.dart';
import 'package:my_data_app/src/profile_vault/cubit/profile_vault_state.dart';

class ProfileVaultCubit extends Cubit<ProfileVaultState> {
  final ProfileVaultRepository _repository;

  ProfileVaultCubit(this._repository)
      : super(ProfileVaultState(entries: _repository.getAll()));

  void addEntry(VaultEntry entry) {
    _repository.add(entry);
    emit(state.copyWith(entries: _repository.getAll()));
  }

  void updateEntry(VaultEntry entry) {
    _repository.update(entry);
    emit(state.copyWith(entries: _repository.getAll()));
  }

  void deleteEntry(String id) {
    _repository.delete(id);
    emit(state.copyWith(entries: _repository.getAll()));
  }

  void toggleFavorite(String id) {
    final entry = state.entries.firstWhere((e) => e.id == id);
    updateEntry(entry.copyWith(isFavorite: !entry.isFavorite));
  }

  VaultEntry? getEntryById(String id) {
    final matches = state.entries.where((e) => e.id == id);
    return matches.isNotEmpty ? matches.first : null;
  }

  List<VaultEntry> entriesForSection(VaultSection section) =>
      state.entries.where((e) => e.section == section).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  List<VaultEntry> get favorites =>
      state.entries.where((e) => e.isFavorite).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  Map<VaultSection, int> get sectionCounts {
    final map = <VaultSection, int>{};
    for (final e in state.entries) {
      map[e.section] = (map[e.section] ?? 0) + 1;
    }
    return map;
  }

  /// Search across all entries
  List<VaultEntry> search(String query) {
    final q = query.toLowerCase();
    return state.entries.where((e) {
      if (e.title.toLowerCase().contains(q)) return true;
      for (final v in e.fields.values) {
        if (v.toLowerCase().contains(q)) return true;
      }
      return false;
    }).toList();
  }

  /// Get shareable text for a whole section
  String shareableTextForSection(VaultSection section) {
    final entries = entriesForSection(section);
    if (entries.isEmpty) return '';
    final buffer = StringBuffer();
    buffer.writeln('═══ ${section.label} ═══');
    buffer.writeln();
    for (final entry in entries) {
      buffer.writeln(entry.toShareableText());
      buffer.writeln();
    }
    return buffer.toString().trim();
  }
}
