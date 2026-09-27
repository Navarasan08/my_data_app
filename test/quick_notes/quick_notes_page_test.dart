import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_data_app/src/quick_notes/cubit/quick_note_cubit.dart';
import 'package:my_data_app/src/quick_notes/model/quick_note.dart';
import 'package:my_data_app/src/quick_notes/quick_notes_page.dart';
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

  Widget app(Widget child) => MaterialApp(
    home: BlocProvider.value(value: cubit, child: child),
  );

  testWidgets('empty state, then cards with sections and a tickable item', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Let the fake deliver its first snapshot so the cubit is live and no
    // indeterminate progress bar is animating (pumpAndSettle would never
    // settle otherwise).
    await pumpEventQueue();
    await tester.pumpWidget(app(const QuickNotesPage()));
    await tester.pumpAndSettle();
    expect(find.text('Your notes live here'), findsOneWidget);

    final now = DateTime.now();
    cubit.save(
      QuickNote(
        id: 'p',
        title: 'Pinned one',
        pinned: true,
        createdAt: now,
        updatedAt: now,
      ),
    );
    cubit.save(
      QuickNote(
        id: 'c',
        title: 'Packing',
        items: const [
          NoteItem(id: 'a', text: 'Charger'),
          NoteItem(id: 'b', text: 'Passport'),
        ],
        createdAt: now,
        updatedAt: now,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('PINNED'), findsOneWidget);
    expect(find.text('NOTES'), findsOneWidget);
    expect(find.text('Pinned one'), findsOneWidget);
    expect(find.text('0 of 2 done'), findsOneWidget);

    await tester.tap(find.text('Charger'));
    await tester.pumpAndSettle();
    expect(find.text('1 of 2 done'), findsOneWidget);
    expect(cubit.byId('c')!.doneCount, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('editor saves on back and drops an empty note', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Let the fake deliver its first snapshot so the cubit is live and no
    // indeterminate progress bar is animating (pumpAndSettle would never
    // settle otherwise).
    await pumpEventQueue();
    await tester.pumpWidget(app(const QuickNotesPage()));
    await tester.pumpAndSettle();

    // Open a fresh note editor directly.
    final note = cubit.newNote();
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: cubit,
                      child: QuickNoteEditorPage(note: note),
                    ),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Start writing…'), findsOneWidget);

    // Leave without typing: nothing is saved.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(cubit.state.notes, isEmpty);

    // Type a title, leave: it is saved.
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Title'), 'Ideas');
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(cubit.state.notes.single.title, 'Ideas');
    expect(tester.takeException(), isNull);
  });
}
