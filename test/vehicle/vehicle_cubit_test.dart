import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_data_app/src/core/sync/sync_snapshot.dart';
import 'package:my_data_app/src/vehicle/cubit/vehicle_cubit.dart';
import 'package:my_data_app/src/vehicle/model/vehicle_model.dart';
import 'package:my_data_app/src/vehicle/repository/vehicle_repository.dart';

Vehicle vehicle(
  String id, {
  String name = 'Car',
  List<VehicleRecord>? records,
}) {
  return Vehicle(
    id: id,
    name: name,
    brand: 'Honda',
    model: 'Civic',
    year: '2020',
    registrationNumber: 'ABC-$id',
    purchaseDate: DateTime(2020, 3, 15),
    records: records ?? const [],
  );
}

VehicleRecord record(String id, {double amount = 45.5}) {
  return VehicleRecord(
    id: id,
    type: RecordType.fuel,
    date: DateTime(2024, 1, 10),
    title: 'Fuel $id',
    amount: amount,
  );
}

void main() {
  late FakeFirebaseFirestore fs;
  late FirestoreVehicleRepository repo;
  late VehicleCubit cubit;

  setUp(() {
    fs = FakeFirebaseFirestore();
    repo = FirestoreVehicleRepository(uid: 'u1', firestore: fs)..start();
    cubit = VehicleCubit(repo);
  });

  tearDown(() async {
    await cubit.close();
    await repo.dispose();
  });

  test('starts in the loading state', () {
    expect(cubit.state.syncStatus, SyncStatus.loading);
    expect(cubit.state.isLive, isFalse);
  });

  test('loads existing vehicles and reports live', () async {
    await fs
        .collection('users')
        .doc('u1')
        .collection('vehicles')
        .doc('v1')
        .set(vehicle('v1').toJson());
    await pumpEventQueue();
    expect(cubit.state.isLive, isTrue);
    expect(cubit.state.vehicles.map((v) => v.id), ['v1']);
  });

  test('add / update / delete are immediate and persisted', () async {
    await pumpEventQueue();
    cubit.addVehicle(vehicle('v1'));
    expect(cubit.state.vehicles, hasLength(1));

    cubit.updateVehicle(vehicle('v1', name: 'Renamed'));
    expect(cubit.state.vehicles.single.name, 'Renamed');

    await pumpEventQueue();
    final stored = await fs
        .collection('users')
        .doc('u1')
        .collection('vehicles')
        .doc('v1')
        .get();
    expect(stored.data()!['name'], 'Renamed');

    cubit.deleteVehicle('v1');
    expect(cubit.state.vehicles, isEmpty);
    await pumpEventQueue();
    expect(cubit.state.vehicles, isEmpty);
  });

  test('record add / update / delete round-trip through the vehicle', () async {
    await pumpEventQueue();
    cubit.addVehicle(vehicle('v1'));

    cubit.addRecord('v1', record('r1'));
    expect(cubit.state.vehicles.single.records.map((r) => r.id), ['r1']);

    cubit.updateRecord('v1', record('r1', amount: 99));
    expect(cubit.state.vehicles.single.records.single.amount, 99);

    await pumpEventQueue();
    final stored = await fs
        .collection('users')
        .doc('u1')
        .collection('vehicles')
        .doc('v1')
        .get();
    final records = stored.data()!['records'] as List<dynamic>;
    expect(records, hasLength(1));
    expect((records.first as Map)['amount'], 99);

    cubit.deleteRecord('v1', 'r1');
    await pumpEventQueue();
    expect(cubit.state.vehicles.single.records, isEmpty);
  });

  test(
    'edits from elsewhere (another device) arrive without a refresh',
    () async {
      await pumpEventQueue();
      await fs
          .collection('users')
          .doc('u1')
          .collection('vehicles')
          .doc('remote')
          .set(vehicle('remote').toJson());
      await pumpEventQueue();
      expect(cubit.state.vehicles.map((v) => v.id), ['remote']);
    },
  );
}
