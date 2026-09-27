import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_data_app/src/core/sync/firestore_collection_source.dart';
import 'package:my_data_app/src/core/sync/firestore_document_source.dart';
import 'package:my_data_app/src/core/sync/sync_snapshot.dart';

void main() {
  late FakeFirebaseFirestore fs;

  setUp(() {
    fs = FakeFirebaseFirestore();
  });

  group('FirestoreCollectionSource', () {
    test('is loading before start and delivers docs after', () async {
      final col = fs.collection('items');
      await col.doc('a').set({'n': 1});
      await col.doc('b').set({'n': 2});

      final src = FirestoreCollectionSource<String>(
        query: col,
        fromDoc: (json, id) => '$id:${json['n']}',
      );
      expect(src.current.isLoading, isTrue);
      expect(src.current.data, isEmpty);
      expect(src.isStarted, isFalse);

      final events = <SyncSnapshot<List<String>>>[];
      src.stream.listen(events.add);
      src.start();
      await pumpEventQueue();

      expect(src.isStarted, isTrue);
      expect(src.current.status, SyncStatus.live);
      expect(src.current.data, unorderedEquals(['a:1', 'b:2']));
      expect(events, isNotEmpty);
      await src.dispose();
    });

    test('streams adds, updates and deletes', () async {
      final col = fs.collection('items');
      final src = FirestoreCollectionSource<String>(
        query: col,
        fromDoc: (json, id) => '$id:${json['n']}',
      );
      src.start();
      await pumpEventQueue();
      expect(src.current.data, isEmpty);
      expect(src.current.status, SyncStatus.live);

      await col.doc('a').set({'n': 1});
      await pumpEventQueue();
      expect(src.current.data, ['a:1']);

      await col.doc('a').set({'n': 5});
      await pumpEventQueue();
      expect(src.current.data, ['a:5']);

      await col.doc('a').delete();
      await pumpEventQueue();
      expect(src.current.data, isEmpty);
      await src.dispose();
    });

    test('skips documents that fail to parse instead of failing', () async {
      final col = fs.collection('items');
      await col.doc('good').set({'n': 1});
      await col.doc('bad').set({'n': 'not a number'});

      final src = FirestoreCollectionSource<int>(
        query: col,
        fromDoc: (json, id) => json['n'] as int,
      );
      src.start();
      await pumpEventQueue();

      expect(src.current.data, [1]);
      expect(src.current.status, SyncStatus.live);
      await src.dispose();
    });

    test('start is idempotent and dispose closes the stream', () async {
      final col = fs.collection('items');
      final src = FirestoreCollectionSource<String>(
        query: col,
        fromDoc: (json, id) => id,
      );
      var events = 0;
      final done = src.stream.listen((_) => events++).asFuture<void>();
      src.start();
      src.start();
      await pumpEventQueue();
      final afterStart = events;

      await src.dispose();
      await done; // stream closed → asFuture completes
      expect(src.isStarted, isFalse);

      // Writes after dispose must not reach the (closed) stream.
      await col.doc('x').set({});
      await pumpEventQueue();
      expect(events, afterStart);
    });

    test('data list is unmodifiable', () async {
      final col = fs.collection('items');
      await col.doc('a').set({});
      final src = FirestoreCollectionSource<String>(
        query: col,
        fromDoc: (json, id) => id,
      );
      src.start();
      await pumpEventQueue();
      expect(() => src.current.data.add('z'), throwsUnsupportedError);
      await src.dispose();
    });
  });

  group('FirestoreDocumentSource', () {
    test('maps a missing doc to the initial/default value', () async {
      final ref = fs.collection('settings').doc('prefs');
      final src = FirestoreDocumentSource<String>(
        ref: ref,
        fromDoc: (json) => (json?['name'] as String?) ?? 'default',
        initial: 'initial',
      );
      expect(src.current.data, 'initial');
      expect(src.current.isLoading, isTrue);

      src.start();
      await pumpEventQueue();
      expect(src.current.data, 'default');
      expect(src.current.status, SyncStatus.live);
      await src.dispose();
    });

    test('follows writes to the doc', () async {
      final ref = fs.collection('settings').doc('prefs');
      final src = FirestoreDocumentSource<String>(
        ref: ref,
        fromDoc: (json) => (json?['name'] as String?) ?? 'default',
        initial: 'initial',
      );
      src.start();
      await pumpEventQueue();

      await ref.set({'name': 'alice'});
      await pumpEventQueue();
      expect(src.current.data, 'alice');

      await ref.set({'other': 1}, SetOptions(merge: true));
      await pumpEventQueue();
      expect(src.current.data, 'alice');
      await src.dispose();
    });

    test('keeps the previous value when parsing throws', () async {
      final ref = fs.collection('settings').doc('prefs');
      await ref.set({'n': 1});
      final src = FirestoreDocumentSource<int>(
        ref: ref,
        fromDoc: (json) => json!['n'] as int,
        initial: -1,
      );
      src.start();
      await pumpEventQueue();
      expect(src.current.data, 1);

      await ref.set({'n': 'oops'});
      await pumpEventQueue();
      expect(src.current.data, 1);
      await src.dispose();
    });
  });
}
