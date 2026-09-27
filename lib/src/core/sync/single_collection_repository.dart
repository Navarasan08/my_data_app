import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_data_app/src/core/sync/firestore_collection_source.dart';
import 'package:my_data_app/src/core/sync/firestore_list_store.dart';
import 'package:my_data_app/src/core/sync/sync_node.dart';
import 'package:my_data_app/src/core/sync/sync_snapshot.dart';

/// Base for the common "one collection under users/{uid}" repository.
///
/// Subclasses supply the collection name and the model's JSON mapping and
/// get realtime reads, optimistic writes, sync status and lifecycle for
/// free. Module-specific write methods (`add`, `update`, `delete`, …) are
/// one-liners over [store].
abstract class SingleCollectionRepository<T> implements SyncNode {
  final String uid;
  final FirestoreListStore<T> store;

  SingleCollectionRepository({
    required this.uid,
    required String collectionName,
    required DocMapper<T> fromDoc,
    required Map<String, dynamic> Function(T item) toJson,
    required String Function(T item) idOf,
    FirebaseFirestore? firestore,
  }) : store = FirestoreListStore<T>(
         collection: (firestore ?? FirebaseFirestore.instance)
             .collection('users')
             .doc(uid)
             .collection(collectionName),
         fromDoc: fromDoc,
         toJson: toJson,
         idOf: idOf,
         debugLabel: collectionName,
       );

  List<T> getAll() => store.items;

  @override
  SyncStatus get syncStatus => store.syncStatus;

  @override
  bool get hasPendingWrites => store.hasPendingWrites;

  @override
  Stream<void> get changes => store.changes;

  @override
  void start() => store.start();

  @override
  Future<void> dispose() => store.dispose();
}
