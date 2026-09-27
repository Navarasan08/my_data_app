import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_data_app/src/checklist/cubit/checklist_cubit.dart';
import 'package:my_data_app/src/checklist/model/checklist_model.dart';
import 'package:my_data_app/src/checklist/repository/checklist_repository.dart';
import 'package:my_data_app/src/core/sync/sync_snapshot.dart';

ChecklistGroup group(
  String id, {
  String name = 'Trip',
  List<ChecklistItem>? items,
}) {
  return ChecklistGroup(
    id: id,
    name: name,
    targetDate: DateTime(2025, 6, 1),
    createdDate: DateTime(2025, 1, 1),
    items: items ?? const [],
  );
}

ChecklistItem item(String id, {String title = 'Pack'}) =>
    ChecklistItem(id: id, title: title);

void main() {
  late FakeFirebaseFirestore fs;
  late FirestoreChecklistRepository repo;
  late ChecklistCubit cubit;

  setUp(() {
    fs = FakeFirebaseFirestore();
    repo = FirestoreChecklistRepository(uid: 'u1', firestore: fs)..start();
    cubit = ChecklistCubit(repo);
  });

  tearDown(() async {
    await cubit.close();
    await repo.dispose();
  });

  test('starts in the loading state', () {
    expect(cubit.state.syncStatus, SyncStatus.loading);
    expect(cubit.state.isLive, isFalse);
  });

  test('loads existing checklists and reports live', () async {
    await fs
        .collection('users')
        .doc('u1')
        .collection('checklists')
        .doc('g1')
        .set(group('g1').toJson());
    await pumpEventQueue();
    expect(cubit.state.isLive, isTrue);
    expect(cubit.state.checklists.map((g) => g.id), ['g1']);
  });

  test('add / update / delete are immediate and persisted', () async {
    await pumpEventQueue();
    cubit.addChecklist(group('g1'));
    expect(cubit.state.checklists, hasLength(1));

    cubit.updateChecklist(group('g1', name: 'Renamed'));
    expect(cubit.state.checklists.single.name, 'Renamed');

    await pumpEventQueue();
    final stored = await fs
        .collection('users')
        .doc('u1')
        .collection('checklists')
        .doc('g1')
        .get();
    expect(stored.data()!['name'], 'Renamed');

    cubit.deleteChecklist('g1');
    expect(cubit.state.checklists, isEmpty);
    await pumpEventQueue();
    expect(cubit.state.checklists, isEmpty);
  });

  test('item add / toggle / delete round-trip through the group', () async {
    await pumpEventQueue();
    cubit.addChecklist(group('g1'));

    cubit.addItem('g1', item('i1'));
    expect(cubit.state.checklists.single.items.map((i) => i.id), ['i1']);

    cubit.toggleItem('g1', 'i1');
    expect(cubit.state.checklists.single.items.single.isCompleted, isTrue);

    await pumpEventQueue();
    final stored = await fs
        .collection('users')
        .doc('u1')
        .collection('checklists')
        .doc('g1')
        .get();
    final items = stored.data()!['items'] as List<dynamic>;
    expect((items.single as Map)['isCompleted'], isTrue);

    cubit.deleteItem('g1', 'i1');
    await pumpEventQueue();
    expect(cubit.state.checklists.single.items, isEmpty);
  });

  test(
    'edits from elsewhere (another device) arrive without a refresh',
    () async {
      await pumpEventQueue();
      await fs
          .collection('users')
          .doc('u1')
          .collection('checklists')
          .doc('remote')
          .set(group('remote').toJson());
      await pumpEventQueue();
      expect(cubit.state.checklists.map((g) => g.id), ['remote']);
    },
  );
}
