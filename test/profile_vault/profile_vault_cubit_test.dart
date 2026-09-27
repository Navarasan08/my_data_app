import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_data_app/src/core/sync/sync_snapshot.dart';
import 'package:my_data_app/src/profile_vault/cubit/profile_vault_cubit.dart';
import 'package:my_data_app/src/profile_vault/model/profile_vault_model.dart';
import 'package:my_data_app/src/profile_vault/repository/profile_vault_repository.dart';

VaultEntry entry(String id, {String? title}) {
  final now = DateTime.now();
  return VaultEntry(
    id: id,
    section: VaultSection.basicDetails,
    title: title ?? 'Entry $id',
    fields: const {'Full Name': 'Someone'},
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late FakeFirebaseFirestore fs;
  late FirestoreProfileVaultRepository repo;
  late ProfileVaultCubit cubit;

  setUp(() {
    fs = FakeFirebaseFirestore();
    repo = FirestoreProfileVaultRepository(uid: 'u1', firestore: fs)..start();
    cubit = ProfileVaultCubit(repo);
  });

  tearDown(() async {
    await cubit.close();
    await repo.dispose();
  });

  test('starts in the loading state', () {
    expect(cubit.state.syncStatus, SyncStatus.loading);
    expect(cubit.state.isLive, isFalse);
  });

  test('loads existing entries and reports live', () async {
    await fs
        .collection('users')
        .doc('u1')
        .collection('vault_entries')
        .doc('v1')
        .set(entry('v1').toJson());
    await pumpEventQueue();
    expect(cubit.state.isLive, isTrue);
    expect(cubit.state.entries.map((e) => e.id), ['v1']);
  });

  test('add / update / delete are immediate and persisted', () async {
    await pumpEventQueue();
    cubit.addEntry(entry('v1'));
    expect(cubit.state.entries, hasLength(1));

    cubit.updateEntry(entry('v1', title: 'Renamed'));
    expect(cubit.state.entries.single.title, 'Renamed');

    await pumpEventQueue();
    final stored = await fs
        .collection('users')
        .doc('u1')
        .collection('vault_entries')
        .doc('v1')
        .get();
    expect(stored.data()!['title'], 'Renamed');

    cubit.deleteEntry('v1');
    expect(cubit.state.entries, isEmpty);
    await pumpEventQueue();
    expect(cubit.state.entries, isEmpty);
  });

  test(
    'edits from elsewhere (another device) arrive without a refresh',
    () async {
      await pumpEventQueue();
      await fs
          .collection('users')
          .doc('u1')
          .collection('vault_entries')
          .doc('remote')
          .set(entry('remote').toJson());
      await pumpEventQueue();
      expect(cubit.state.entries.map((e) => e.id), ['remote']);
    },
  );
}
