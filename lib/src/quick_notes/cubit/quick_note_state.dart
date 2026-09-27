import 'package:my_data_app/src/core/sync/sync_snapshot.dart';
import 'package:my_data_app/src/quick_notes/model/quick_note.dart';

class QuickNoteState {
  final List<QuickNote> notes;
  final SyncStatus syncStatus;

  /// Case-insensitive match against title, body and checklist items.
  final String search;

  const QuickNoteState({
    required this.notes,
    this.syncStatus = SyncStatus.loading,
    this.search = '',
  });

  bool get isLive => syncStatus.isLive;
  bool get isLoading => syncStatus.isLoading;

  QuickNoteState copyWith({
    List<QuickNote>? notes,
    SyncStatus? syncStatus,
    String? search,
  }) => QuickNoteState(
    notes: notes ?? this.notes,
    syncStatus: syncStatus ?? this.syncStatus,
    search: search ?? this.search,
  );
}
