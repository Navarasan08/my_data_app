import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_data_app/src/core/firestore_read.dart';
import 'package:my_data_app/src/diet/model/diet_model.dart';

abstract class DietRepository {
  List<FoodItem> getItems();
  void addItem(FoodItem item);
  void updateItem(FoodItem item);
  void deleteItem(String itemId);

  List<FoodEntry> getEntries();
  void addEntry(FoodEntry entry);
  void updateEntry(FoodEntry entry);
  void deleteEntry(String entryId);

  Future<void> init();
}

class FirestoreDietRepository implements DietRepository {
  final String uid;
  final FirebaseFirestore _firestore;
  List<FoodItem> _items = [];
  List<FoodEntry> _entries = [];

  FirestoreDietRepository({
    required this.uid,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _itemsCol =>
      _firestore.collection('users').doc(uid).collection('diet_items');

  CollectionReference<Map<String, dynamic>> get _entriesCol =>
      _firestore.collection('users').doc(uid).collection('diet_entries');

  @override
  Future<void> init() => _load(cacheFirst: true);

  /// Re-reads from the server, replacing the cache-first data from [init].
  Future<void> refresh() => _load(cacheFirst: false);

  Future<void> _load({required bool cacheFirst}) async {
    final itemsSnap = cacheFirst
        ? await readQueryCacheFirst(_itemsCol)
        : await _itemsCol.get();
    _items =
        itemsSnap.docs.map((d) => FoodItem.fromJson(d.data())).toList();
    final entriesSnap = cacheFirst
        ? await readQueryCacheFirst(_entriesCol)
        : await _entriesCol.get();
    _entries =
        entriesSnap.docs.map((d) => FoodEntry.fromJson(d.data())).toList();
  }

  @override
  List<FoodItem> getItems() => List.unmodifiable(_items);

  @override
  void addItem(FoodItem item) {
    _items.add(item);
    _itemsCol.doc(item.id).set(item.toJson());
  }

  @override
  void updateItem(FoodItem item) {
    final i = _items.indexWhere((x) => x.id == item.id);
    if (i != -1) {
      _items[i] = item;
      _itemsCol.doc(item.id).set(item.toJson());
    }
  }

  @override
  void deleteItem(String itemId) {
    _items.removeWhere((x) => x.id == itemId);
    _itemsCol.doc(itemId).delete();
    // Cascade: remove all entries linked to this item.
    final orphans =
        _entries.where((e) => e.foodItemId == itemId).map((e) => e.id).toList();
    _entries.removeWhere((e) => e.foodItemId == itemId);
    for (final id in orphans) {
      _entriesCol.doc(id).delete();
    }
  }

  @override
  List<FoodEntry> getEntries() => List.unmodifiable(_entries);

  @override
  void addEntry(FoodEntry entry) {
    _entries.add(entry);
    _entriesCol.doc(entry.id).set(entry.toJson());
  }

  @override
  void updateEntry(FoodEntry entry) {
    final i = _entries.indexWhere((x) => x.id == entry.id);
    if (i != -1) {
      _entries[i] = entry;
      _entriesCol.doc(entry.id).set(entry.toJson());
    }
  }

  @override
  void deleteEntry(String entryId) {
    _entries.removeWhere((x) => x.id == entryId);
    _entriesCol.doc(entryId).delete();
  }
}
