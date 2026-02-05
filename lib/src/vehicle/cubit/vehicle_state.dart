import 'package:my_data_app/src/vehicle/model/vehicle_model.dart';

class VehicleState {
  final List<Vehicle> vehicles;

  const VehicleState({required this.vehicles});

  VehicleState copyWith({List<Vehicle>? vehicles}) {
    return VehicleState(vehicles: vehicles ?? this.vehicles);
  }
}
