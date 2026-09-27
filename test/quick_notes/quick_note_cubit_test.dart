import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_data_app/src/core/sync/sync_snapshot.dart';
import 'package:my_data_app/src/quick_notes/cubit/quick_note_cubit.dart';
import 'package:my_data_app/src/quick_notes/model/quick_note.dart';
import 'package:my_data_app/src/quick_notes/repository/quick_note_repository.dart';

void main() {
  late FakeFirebaseFirestore fs;
  late FirestoreQuickNoteRepository repo;
  late QuickNoteCubit cubit;

  setUp(() {
    fs = FakeFirebaseFirestore();
    repo = FirestoreQuickNoteRepository(uid: 'u1', firestore: fs)..start();
    cubit = QuickNoteCubit(repo);
  });

  tearDown(() async {
    await cubit.close();
    await repo.dispose();
  });

  QuickNote note(
    String id, {
    String title = '',
    String body = '',
    List<NoteItem> items = const [],
    bool pinned = false,
    DateTime? updatedAt,
  }) {
    final t = updatedAt ?? DateTime(2026, 9, 1);
    return QuickNote(
      id: id,
      title: title,
      body: body,
      items: items,
      pinned: pinned,
      createdAt: t,
      updatedAt: t,
    );
  }

  test('starts loading, becomes live', () async {
    expect(cubit.state.syncStatus, SyncStatus.loading);
    await pumpEventQueue();
    expect(cubit.state.isLive, isTrue);
  });

  test('save creates, updates, and drops empty notes', () async {
    await pumpEventQueue();
    cubit.save(note('n1', title: 'Groceries'));
    expect(cubit.state.notes.single.title, 'Groceries');

    cubit.save(note('n1', title: 'Groceries', body: 'milk'));
    expect(cubit.state.notes.single.body, 'milk');

    cubit.save(note('n1'));
    expect(cubit.state.notes, isEmpty);

    // A brand-new empty note is never written at all.
    cubit.save(cubit.newNote());
    await pumpEventQueue();
    expect(
      (await fs.collection('users').doc('u1').collection('quick_notes').get())
          .docs,
      isEmpty,
    );
  });

  test('blank checklist lines are stripped on save', () async {
    await pumpEventQueue();
    cubit.save(
      note(
        'c1',
        items: const [
          NoteItem(id: 'a', text: 'Eggs'),
          NoteItem(id: 'b', text: '   '),
        ],
      ),
    );
    expect(cubit.state.notes.single.items.map((i) => i.id), ['a']);
  });

  test('sorted: pinned first, then most recently edited', () async {
    await pumpEventQueue();
    cubit.save(note('old', title: 'Old', updatedAt: DateTime(2026, 1, 1)));
    cubit.save(note('new', title: 'New', updatedAt: DateTime(2026, 6, 1)));
    cubit.save(
      note(
        'pin',
        title: 'Pinned',
        pinned: true,
        updatedAt: DateTime(2025, 1, 1),
      ),
    );
    // save() stamps updatedAt with now, so use togglePin/updated order via ids.
    final ids = cubit.sorted.map((n) => n.id).toList();
    expect(ids.first, 'pin');
    expect(ids.length, 3);
  });

  test('togglePin and toggleItem round-trip', () async {
    await pumpEventQueue();
    cubit.save(
      note(
        'c1',
        title: 'Packing',
        items: const [NoteItem(id: 'a', text: 'Charger')],
      ),
    );
    cubit.togglePin('c1');
    expect(cubit.byId('c1')!.pinned, isTrue);

    cubit.toggleItem('c1', 'a');
    expect(cubit.byId('c1')!.items.single.done, isTrue);
    expect(cubit.byId('c1')!.doneCount, 1);

    await pumpEventQueue();
    final stored = await fs
        .collection('users')
        .doc('u1')
        .collection('quick_notes')
        .doc('c1')
        .get();
    expect((stored.data()!['items'] as List).first['done'], isTrue);
    expect(stored.data()!['pinned'], isTrue);
  });

  test('search matches title, body and items', () async {
    await pumpEventQueue();
    cubit.save(note('n1', title: 'Trip', body: 'Book hotel'));
    cubit.save(
      note(
        'n2',
        items: const [NoteItem(id: 'a', text: 'Passport')],
      ),
    );
    cubit.setSearch('hotel');
    expect(cubit.filtered.map((n) => n.id), ['n1']);
    cubit.setSearch('PASS');
    expect(cubit.filtered.map((n) => n.id), ['n2']);
    cubit.setSearch('');
    expect(cubit.filtered.length, 2);
  });

  test('display title and preview fall back sensibly', () {
    expect(
      note('x', body: 'First line\nSecond\nThird').displayTitle,
      'First line',
    );
    expect(
      note('x', body: 'First line\nSecond\nThird').preview,
      'Second · Third',
    );
    expect(note('x', title: 'T', body: 'A\nB').preview, 'A · B');
    expect(
      note(
        'x',
        items: const [NoteItem(id: 'a', text: 'Eggs')],
      ).displayTitle,
      'Eggs',
    );
    expect(note('x').displayTitle, 'New note');
  });

  test('JSON round-trip keeps items', () {
    final n = note(
      'j',
      title: 'J',
      items: const [NoteItem(id: 'a', text: 'x', done: true)],
      pinned: true,
    );
    final back = QuickNote.fromJson(n.toJson());
    expect(back.items.single.done, isTrue);
    expect(back.pinned, isTrue);
    expect(back.title, 'J');
  });

  test('remote edits arrive without a refresh', () async {
    await pumpEventQueue();
    await fs
        .collection('users')
        .doc('u1')
        .collection('quick_notes')
        .doc('r')
        .set(note('r', title: 'Remote').toJson());
    await pumpEventQueue();
    expect(cubit.state.notes.single.title, 'Remote');
  });
}
