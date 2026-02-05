import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_data_app/src/vehicle/model/vehicle_model.dart';
import 'package:my_data_app/src/vehicle/repository/vehicle_repository.dart';
import 'package:my_data_app/src/vehicle/cubit/vehicle_state.dart';

class VehicleCubit extends Cubit<VehicleState> {
  final VehicleRepository _repository;

  VehicleCubit(this._repository)
      : super(VehicleState(vehicles: _repository.getAll()));

  void addVehicle(Vehicle vehicle) {
    _repository.add(vehicle);
    emit(state.copyWith(vehicles: _repository.getAll()));
  }

  void updateVehicle(Vehicle vehicle) {
    _repository.update(vehicle);
    emit(state.copyWith(vehicles: _repository.getAll()));
  }

  void deleteVehicle(String vehicleId) {
    _repository.delete(vehicleId);
    emit(state.copyWith(vehicles: _repository.getAll()));
  }

  void addRecord(String vehicleId, VehicleRecord record) {
    final vehicle = state.vehicles.firstWhere((v) => v.id == vehicleId);
    final updatedRecords = List<VehicleRecord>.from(vehicle.records)
      ..add(record);
    _repository.update(vehicle.copyWith(records: updatedRecords));
    emit(state.copyWith(vehicles: _repository.getAll()));
  }

  void updateRecord(String vehicleId, VehicleRecord record) {
    final vehicle = state.vehicles.firstWhere((v) => v.id == vehicleId);
    final updatedRecords = List<VehicleRecord>.from(vehicle.records);
    final index = updatedRecords.indexWhere((r) => r.id == record.id);
    if (index != -1) {
      updatedRecords[index] = record;
    }
    _repository.update(vehicle.copyWith(records: updatedRecords));
    emit(state.copyWith(vehicles: _repository.getAll()));
  }

  void deleteRecord(String vehicleId, String recordId) {
    final vehicle = state.vehicles.firstWhere((v) => v.id == vehicleId);
    final updatedRecords =
        vehicle.records.where((r) => r.id != recordId).toList();
    _repository.update(vehicle.copyWith(records: updatedRecords));
    emit(state.copyWith(vehicles: _repository.getAll()));
  }

  Vehicle? getVehicleById(String vehicleId) {
    final matches = state.vehicles.where((v) => v.id == vehicleId);
    return matches.isNotEmpty ? matches.first : null;
  }
}
