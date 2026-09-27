import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_data_app/src/core/sync/firestore_list_store.dart';
import 'package:my_data_app/src/core/sync/sync_node.dart';
import 'package:my_data_app/src/diet/model/diet_model.dart';

abstract class DietRepository implements SyncNode {
  List<FoodItem> getItems();
  void addItem(FoodItem item);
  void updateItem(FoodItem item);
  void deleteItem(String itemId);

  List<FoodEntry> getEntries();
  void addEntry(FoodEntry entry);
  void updateEntry(FoodEntry entry);
  void deleteEntry(String entryId);
}

/// Realtime Firestore implementation over the food-items and food-entries
/// collections.
class FirestoreDietRepository extends CompositeSyncNode
    implements DietRepository {
  final String uid;
  final FirestoreListStore<FoodItem> _items;
  final FirestoreListStore<FoodEntry> _entries;

  factory FirestoreDietRepository({
    required String uid,
    FirebaseFirestore? firestore,
  }) {
    final user = (firestore ?? FirebaseFirestore.instance)
        .collection('users')
        .doc(uid);
    return FirestoreDietRepository._(
      uid,
      FirestoreListStore<FoodItem>(
        collection: user.collection('diet_items'),
        fromDoc: (json, _) => FoodItem.fromJson(json),
        toJson: (i) => i.toJson(),
        idOf: (i) => i.id,
        debugLabel: 'diet_items',
      ),
      FirestoreListStore<FoodEntry>(
        collection: user.collection('diet_entries'),
        fromDoc: (json, _) => FoodEntry.fromJson(json),
        toJson: (e) => e.toJson(),
        idOf: (e) => e.id,
        debugLabel: 'diet_entries',
      ),
    );
  }

  FirestoreDietRepository._(this.uid, this._items, this._entries)
    : super([_items, _entries]);

  // ── Food items ──────────────────────────────────────────────────────────

  @override
  List<FoodItem> getItems() => _items.items;

  @override
  void addItem(FoodItem item) => _items.save(item);

  @override
  void updateItem(FoodItem item) => _items.save(item);

  @override
  void deleteItem(String itemId) {
    _items.remove(itemId);
    // Cascade: remove all entries linked to this item.
    _entries.removeWhere((e) => e.foodItemId == itemId);
  }

  // ── Food entries ────────────────────────────────────────────────────────

  @override
  List<FoodEntry> getEntries() => _entries.items;

  @override
  void addEntry(FoodEntry entry) => _entries.save(entry);

  @override
  void updateEntry(FoodEntry entry) => _entries.save(entry);

  @override
  void deleteEntry(String entryId) => _entries.remove(entryId);
}
