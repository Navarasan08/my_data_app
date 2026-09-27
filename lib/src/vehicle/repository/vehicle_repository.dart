import 'package:my_data_app/src/core/sync/single_collection_repository.dart';
import 'package:my_data_app/src/core/sync/sync_node.dart';
import 'package:my_data_app/src/vehicle/model/vehicle_model.dart';

abstract class VehicleRepository implements SyncNode {
  List<Vehicle> getAll();
  void add(Vehicle vehicle);
  void update(Vehicle vehicle);
  void delete(String vehicleId);
}

class FirestoreVehicleRepository extends SingleCollectionRepository<Vehicle>
    implements VehicleRepository {
  FirestoreVehicleRepository({required super.uid, super.firestore})
    : super(
        collectionName: 'vehicles',
        fromDoc: (json, _) => Vehicle.fromJson(json),
        toJson: (v) => v.toJson(),
        idOf: (v) => v.id,
      );

  @override
  void add(Vehicle vehicle) => store.save(vehicle);

  @override
  void update(Vehicle vehicle) => store.save(vehicle);

  @override
  void delete(String vehicleId) => store.remove(vehicleId);
}
