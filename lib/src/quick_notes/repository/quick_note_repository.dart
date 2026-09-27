import 'package:my_data_app/src/core/sync/single_collection_repository.dart';
import 'package:my_data_app/src/core/sync/sync_node.dart';
import 'package:my_data_app/src/quick_notes/model/quick_note.dart';

abstract class QuickNoteRepository implements SyncNode {
  List<QuickNote> getAll();
  void add(QuickNote note);
  void update(QuickNote note);
  void delete(String id);
}

class FirestoreQuickNoteRepository extends SingleCollectionRepository<QuickNote>
    implements QuickNoteRepository {
  FirestoreQuickNoteRepository({required super.uid, super.firestore})
    : super(
        collectionName: 'quick_notes',
        fromDoc: (json, _) => QuickNote.fromJson(json),
        toJson: (n) => n.toJson(),
        idOf: (n) => n.id,
      );

  @override
  void add(QuickNote note) => store.save(note);

  @override
  void update(QuickNote note) => store.save(note);

  @override
  void delete(String id) => store.remove(id);
}
