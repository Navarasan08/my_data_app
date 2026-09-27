import 'package:my_data_app/src/core/sync/sync_snapshot.dart';
import 'package:my_data_app/src/vehicle/model/vehicle_model.dart';

class VehicleState {
  final List<Vehicle> vehicles;

  /// Where [vehicles] came from: `loading` before the first snapshot,
  /// `cached` until the server confirms, `live` after.
  final SyncStatus syncStatus;

  const VehicleState({
    required this.vehicles,
    this.syncStatus = SyncStatus.loading,
  });

  bool get isLive => syncStatus.isLive;

  VehicleState copyWith({List<Vehicle>? vehicles, SyncStatus? syncStatus}) {
    return VehicleState(
      vehicles: vehicles ?? this.vehicles,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
