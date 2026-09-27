import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_data_app/src/core/sync/sync_snapshot.dart';
import 'package:my_data_app/src/diet/cubit/diet_cubit.dart';
import 'package:my_data_app/src/diet/model/diet_model.dart';
import 'package:my_data_app/src/diet/repository/diet_repository.dart';

FoodItem item(String id, {String name = 'Item'}) {
  final now = DateTime(2026, 1, 1);
  return FoodItem(
    id: id,
    name: name,
    iconIndex: 0,
    colorIndex: 0,
    createdAt: now,
    updatedAt: now,
  );
}

FoodEntry entry(String id, {String itemId = 'i1', double quantity = 1}) =>
    FoodEntry(
      id: id,
      foodItemId: itemId,
      quantity: quantity,
      date: DateTime(2026, 1, 15),
      createdAt: DateTime(2026, 1, 15),
    );

void main() {
  late FakeFirebaseFirestore fs;
  late FirestoreDietRepository repo;
  late DietCubit cubit;

  CollectionReference<Map<String, dynamic>> items() =>
      fs.collection('users').doc('u1').collection('diet_items');
  CollectionReference<Map<String, dynamic>> entries() =>
      fs.collection('users').doc('u1').collection('diet_entries');

  setUp(() {
    fs = FakeFirebaseFirestore();
    repo = FirestoreDietRepository(uid: 'u1', firestore: fs)..start();
    cubit = DietCubit(repo);
  });

  tearDown(() async {
    await cubit.close();
    await repo.dispose();
  });

  test('starts in the loading state', () {
    expect(cubit.state.syncStatus, SyncStatus.loading);
    expect(cubit.state.isLive, isFalse);
  });

  test('loads existing items and entries and reports live', () async {
    await items().doc('i1').set(item('i1').toJson());
    await entries().doc('e1').set(entry('e1').toJson());
    await pumpEventQueue();
    expect(cubit.state.isLive, isTrue);
    expect(cubit.state.items.map((i) => i.id), ['i1']);
    expect(cubit.state.entries.map((e) => e.id), ['e1']);
  });

  test('item add / update / delete are immediate and persisted', () async {
    await pumpEventQueue();
    cubit.addItem(item('i1'));
    expect(cubit.state.items, hasLength(1));

    cubit.updateItem(item('i1', name: 'Renamed'));
    expect(cubit.state.items.single.name, 'Renamed');

    await pumpEventQueue();
    final stored = await items().doc('i1').get();
    expect(stored.data()!['name'], 'Renamed');

    cubit.deleteItem('i1');
    expect(cubit.state.items, isEmpty);
    await pumpEventQueue();
    expect(cubit.state.items, isEmpty);
    expect((await items().doc('i1').get()).exists, isFalse);
  });

  test('entry add / update / delete are immediate and persisted', () async {
    await pumpEventQueue();
    cubit.addEntry(entry('e1'));
    expect(cubit.state.entries, hasLength(1));

    cubit.updateEntry(entry('e1', quantity: 3));
    expect(cubit.state.entries.single.quantity, 3);

    await pumpEventQueue();
    final stored = await entries().doc('e1').get();
    expect(stored.data()!['quantity'], 3);

    cubit.deleteEntry('e1');
    expect(cubit.state.entries, isEmpty);
    await pumpEventQueue();
    expect(cubit.state.entries, isEmpty);
    expect((await entries().doc('e1').get()).exists, isFalse);
  });

  test('deleting an item cascades to its entries', () async {
    await pumpEventQueue();
    cubit.addItem(item('i1'));
    cubit.addItem(item('i2'));
    cubit.addEntry(entry('e1', itemId: 'i1'));
    cubit.addEntry(entry('e2', itemId: 'i1'));
    cubit.addEntry(entry('e3', itemId: 'i2'));

    cubit.deleteItem('i1');
    expect(cubit.state.items.map((i) => i.id), ['i2']);
    expect(cubit.state.entries.map((e) => e.id), ['e3']);

    await pumpEventQueue();
    expect(cubit.state.entries.map((e) => e.id), ['e3']);
    expect((await entries().doc('e1').get()).exists, isFalse);
    expect((await entries().doc('e2').get()).exists, isFalse);
    expect((await entries().doc('e3').get()).exists, isTrue);
  });

  test(
    'edits from elsewhere (another device) arrive without a refresh',
    () async {
      await pumpEventQueue();
      await items().doc('remote').set(item('remote').toJson());
      await entries().doc('re').set(entry('re', itemId: 'remote').toJson());
      await pumpEventQueue();
      expect(cubit.state.items.map((i) => i.id), ['remote']);
      expect(cubit.state.entries.map((e) => e.id), ['re']);
    },
  );
}
