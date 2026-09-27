import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_data_app/src/core/sync/firestore_list_store.dart';
import 'package:my_data_app/src/core/sync/sync_node.dart';
import 'package:my_data_app/src/core/sync/sync_snapshot.dart';

class _Item {
  final String id;
  final int n;
  const _Item(this.id, this.n);
}

void main() {
  late FakeFirebaseFirestore fs;
  late FirestoreListStore<_Item> store;

  setUp(() {
    fs = FakeFirebaseFirestore();
    store = FirestoreListStore<_Item>(
      collection: fs.collection('items'),
      fromDoc: (json, id) => _Item(id, json['n'] as int),
      toJson: (i) => {'n': i.n},
      idOf: (i) => i.id,
    );
  });

  tearDown(() => store.dispose());

  test(
    'save is visible synchronously, then confirmed by the listener',
    () async {
      store.start();
      await pumpEventQueue();
      expect(store.items, isEmpty);
      expect(store.syncStatus, SyncStatus.live);

      store.save(const _Item('a', 1));
      // Optimistic: no await needed.
      expect(store.items.single.n, 1);
      expect(store.hasPendingWrites, isTrue);

      await pumpEventQueue();
      // Listener caught up: overlay dropped, data still there.
      expect(store.items.single.n, 1);
      expect(store.hasPendingWrites, isFalse);
      expect((await fs.collection('items').doc('a').get()).data(), {'n': 1});
    },
  );

  test('save replaces an existing id in place', () async {
    store.start();
    await pumpEventQueue();
    store.save(const _Item('a', 1));
    store.save(const _Item('b', 2));
    store.save(const _Item('a', 9));
    expect(store.items.map((i) => '${i.id}${i.n}'), ['a9', 'b2']);
    await pumpEventQueue();
    expect(store.items.map((i) => i.n), unorderedEquals([9, 2]));
  });

  test('remove is synchronous locally and deletes remotely', () async {
    await fs.collection('items').doc('a').set({'n': 1});
    store.start();
    await pumpEventQueue();
    expect(store.items, hasLength(1));

    store.remove('a');
    expect(store.items, isEmpty);
    await pumpEventQueue();
    expect(store.items, isEmpty);
    expect((await fs.collection('items').doc('a').get()).exists, isFalse);
  });

  test('removeWhere deletes matching docs in a batch', () async {
    for (var i = 0; i < 5; i++) {
      await fs.collection('items').doc('i$i').set({'n': i});
    }
    store.start();
    await pumpEventQueue();

    store.removeWhere((i) => i.n.isEven);
    expect(store.items.map((i) => i.n), unorderedEquals([1, 3]));
    await pumpEventQueue();
    expect(store.items.map((i) => i.n), unorderedEquals([1, 3]));
    expect((await fs.collection('items').get()).docs, hasLength(2));
  });

  test('remote changes flow in and clear any overlay', () async {
    store.start();
    await pumpEventQueue();
    await fs.collection('items').doc('r').set({'n': 7});
    await pumpEventQueue();
    expect(store.items.single.id, 'r');
    expect(store.byId('r')!.n, 7);
    expect(store.byId('missing'), isNull);
  });

  test('changes fires for local and remote writes', () async {
    var count = 0;
    store.changes.listen((_) => count++);
    store.start();
    await pumpEventQueue();
    final base = count;
    store.save(const _Item('a', 1));
    // Items update synchronously; the notification lands on the next
    // microtask (one for the local overlay, one for the listener echo).
    expect(store.items, hasLength(1));
    await pumpEventQueue();
    expect(count, greaterThanOrEqualTo(base + 2));
  });

  test('works before start as a plain local list (tests, previews)', () {
    store.save(const _Item('a', 1));
    expect(store.items.single.id, 'a');
    expect(store.syncStatus, SyncStatus.loading);
  });

  test('CompositeSyncNode folds status and forwards changes', () async {
    final other = FirestoreListStore<_Item>(
      collection: fs.collection('other'),
      fromDoc: (json, id) => _Item(id, json['n'] as int),
      toJson: (i) => {'n': i.n},
      idOf: (i) => i.id,
    );
    final composite = _Composite([store, other]);
    expect(composite.syncStatus, SyncStatus.loading);

    var events = 0;
    composite.changes.listen((_) => events++);
    composite.start();
    await pumpEventQueue();
    expect(composite.syncStatus, SyncStatus.live);
    expect(events, greaterThan(0));

    final before = events;
    other.save(const _Item('z', 0));
    expect(composite.hasPendingWrites, isTrue);
    await pumpEventQueue();
    expect(events, greaterThan(before));
    expect(composite.hasPendingWrites, isFalse);
    await composite.dispose();
  });
}

class _Composite extends CompositeSyncNode {
  _Composite(super.nodes);
}
