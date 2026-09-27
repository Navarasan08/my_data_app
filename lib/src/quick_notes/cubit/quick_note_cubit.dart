import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_data_app/src/quick_notes/cubit/quick_note_state.dart';
import 'package:my_data_app/src/quick_notes/model/quick_note.dart';
import 'package:my_data_app/src/quick_notes/repository/quick_note_repository.dart';

class QuickNoteCubit extends Cubit<QuickNoteState> {
  final QuickNoteRepository _repository;
  StreamSubscription<void>? _sub;

  QuickNoteCubit(this._repository)
    : super(
        QuickNoteState(
          notes: _repository.getAll(),
          syncStatus: _repository.syncStatus,
        ),
      ) {
    _sub = _repository.changes.listen((_) => _sync());
  }

  void _sync() {
    emit(
      state.copyWith(
        notes: _repository.getAll(),
        syncStatus: _repository.syncStatus,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }

  /// Pinned first, then most recently edited.
  List<QuickNote> get sorted => List<QuickNote>.from(state.notes)
    ..sort((a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });

  List<QuickNote> get filtered {
    final q = state.search.trim().toLowerCase();
    if (q.isEmpty) return sorted;
    return sorted.where((n) {
      if (n.title.toLowerCase().contains(q)) return true;
      if (n.body.toLowerCase().contains(q)) return true;
      return n.items.any((i) => i.text.toLowerCase().contains(q));
    }).toList();
  }

  QuickNote? byId(String id) {
    for (final n in state.notes) {
      if (n.id == id) return n;
    }
    return null;
  }

  void setSearch(String q) => emit(state.copyWith(search: q));

  QuickNote newNote({bool checklist = false}) {
    final now = DateTime.now();
    return QuickNote(
      id: now.millisecondsSinceEpoch.toString(),
      createdAt: now,
      updatedAt: now,
      items: checklist
          ? [NoteItem(id: '${now.millisecondsSinceEpoch}_0', text: '')]
          : const [],
    );
  }

  /// Saves a note, creating or replacing it. Empty notes are dropped, the
  /// way a notes app quietly discards an untouched new note.
  void save(QuickNote note) {
    final cleaned = note.copyWith(
      items: note.items.where((i) => i.text.trim().isNotEmpty).toList(),
      updatedAt: DateTime.now(),
    );
    if (cleaned.isEmpty) {
      if (byId(note.id) != null) _repository.delete(note.id);
    } else if (byId(note.id) == null) {
      _repository.add(cleaned);
    } else {
      _repository.update(cleaned);
    }
    _sync();
  }

  void delete(String id) {
    _repository.delete(id);
    _sync();
  }

  void togglePin(String id) {
    final n = byId(id);
    if (n == null) return;
    _repository.update(n.copyWith(pinned: !n.pinned));
    _sync();
  }

  /// Tick or untick one checklist line straight from the list.
  void toggleItem(String noteId, String itemId) {
    final n = byId(noteId);
    if (n == null) return;
    _repository.update(
      n.copyWith(
        items: n.items
            .map((i) => i.id == itemId ? i.copyWith(done: !i.done) : i)
            .toList(),
        updatedAt: DateTime.now(),
      ),
    );
    _sync();
  }
}
