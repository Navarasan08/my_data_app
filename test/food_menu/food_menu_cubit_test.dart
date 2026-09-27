import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_data_app/src/core/sync/sync_snapshot.dart';
import 'package:my_data_app/src/food_menu/cubit/food_menu_cubit.dart';
import 'package:my_data_app/src/food_menu/model/food_menu_model.dart';
import 'package:my_data_app/src/food_menu/repository/food_menu_repository.dart';

MealEntry meal(
  String id, {
  int weekday = 1,
  MealType type = MealType.breakfast,
  String items = 'Eggs',
}) {
  return MealEntry(id: id, weekday: weekday, mealType: type, items: items);
}

void main() {
  late FakeFirebaseFirestore fs;
  late FirestoreFoodMenuRepository repo;
  late FoodMenuCubit cubit;

  setUp(() {
    fs = FakeFirebaseFirestore();
    repo = FirestoreFoodMenuRepository(uid: 'u1', firestore: fs)..start();
    cubit = FoodMenuCubit(repo);
  });

  tearDown(() async {
    await cubit.close();
    await repo.dispose();
  });

  test('starts in the loading state', () {
    expect(cubit.state.syncStatus, SyncStatus.loading);
    expect(cubit.state.isLive, isFalse);
  });

  test('loads existing meals and reports live', () async {
    await fs
        .collection('users')
        .doc('u1')
        .collection('food_menu')
        .doc('m1')
        .set(meal('m1').toJson());
    await pumpEventQueue();
    expect(cubit.state.isLive, isTrue);
    expect(cubit.state.entries.map((e) => e.id), ['m1']);
  });

  test('add / update / delete are immediate and persisted', () async {
    await pumpEventQueue();
    cubit.addEntry(meal('m1'));
    expect(cubit.state.entries, hasLength(1));

    cubit.updateEntry(meal('m1', items: 'Toast'));
    expect(cubit.state.entries.single.items, 'Toast');

    await pumpEventQueue();
    final stored = await fs
        .collection('users')
        .doc('u1')
        .collection('food_menu')
        .doc('m1')
        .get();
    expect(stored.data()!['items'], 'Toast');

    cubit.deleteEntry('m1');
    expect(cubit.state.entries, isEmpty);
    await pumpEventQueue();
    expect(cubit.state.entries, isEmpty);
  });

  test(
    'selectWeekday keeps entries and weekday queries follow state',
    () async {
      await pumpEventQueue();
      cubit.addEntry(meal('m1', weekday: 1, type: MealType.dinner));
      cubit.addEntry(meal('m2', weekday: 1, type: MealType.breakfast));
      cubit.addEntry(meal('m3', weekday: 2));

      cubit.selectWeekday(1);
      expect(cubit.state.selectedWeekday, 1);
      expect(cubit.selectedDayEntries.map((e) => e.id), ['m2', 'm1']);
      expect(cubit.mealsCountForDay(2), 1);
      expect(cubit.totalMeals, 3);

      await pumpEventQueue();
      expect(cubit.state.selectedWeekday, 1);
      expect(cubit.totalMeals, 3);
    },
  );

  test(
    'edits from elsewhere (another device) arrive without a refresh',
    () async {
      await pumpEventQueue();
      await fs
          .collection('users')
          .doc('u1')
          .collection('food_menu')
          .doc('remote')
          .set(meal('remote').toJson());
      await pumpEventQueue();
      expect(cubit.state.entries.map((e) => e.id), ['remote']);
    },
  );
}
