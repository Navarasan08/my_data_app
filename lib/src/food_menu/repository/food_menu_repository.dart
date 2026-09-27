import 'package:my_data_app/src/core/sync/single_collection_repository.dart';
import 'package:my_data_app/src/core/sync/sync_node.dart';
import 'package:my_data_app/src/food_menu/model/food_menu_model.dart';

abstract class FoodMenuRepository implements SyncNode {
  List<MealEntry> getAll();
  void add(MealEntry entry);
  void update(MealEntry entry);
  void delete(String id);
}

class FirestoreFoodMenuRepository extends SingleCollectionRepository<MealEntry>
    implements FoodMenuRepository {
  FirestoreFoodMenuRepository({required super.uid, super.firestore})
    : super(
        collectionName: 'food_menu',
        fromDoc: (json, _) => MealEntry.fromJson(json),
        toJson: (e) => e.toJson(),
        idOf: (e) => e.id,
      );

  @override
  void add(MealEntry entry) => store.save(entry);

  @override
  void update(MealEntry entry) => store.save(entry);

  @override
  void delete(String id) => store.remove(id);
}
