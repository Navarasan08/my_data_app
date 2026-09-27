import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_data_app/src/vehicle/model/vehicle_model.dart';
import 'package:my_data_app/src/vehicle/repository/vehicle_repository.dart';
import 'package:my_data_app/src/vehicle/cubit/vehicle_state.dart';

class VehicleCubit extends Cubit<VehicleState> {
  final VehicleRepository _repository;
  StreamSubscription<void>? _sub;

  VehicleCubit(this._repository)
    : super(
        VehicleState(
          vehicles: _repository.getAll(),
          syncStatus: _repository.syncStatus,
        ),
      ) {
    _sub = _repository.changes.listen((_) => _sync());
  }

  /// Pulls the repository's current list and sync status into state. Runs
  /// on every realtime change and after each local write.
  void _sync() {
    emit(
      state.copyWith(
        vehicles: _repository.getAll(),
        syncStatus: _repository.syncStatus,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }

  void addVehicle(Vehicle vehicle) {
    _repository.add(vehicle);
    _sync();
  }

  void updateVehicle(Vehicle vehicle) {
    _repository.update(vehicle);
    _sync();
  }

  void deleteVehicle(String vehicleId) {
    _repository.delete(vehicleId);
    _sync();
  }

  void addRecord(String vehicleId, VehicleRecord record) {
    final vehicle = state.vehicles.firstWhere((v) => v.id == vehicleId);
    final updatedRecords = List<VehicleRecord>.from(vehicle.records)
      ..add(record);
    _repository.update(vehicle.copyWith(records: updatedRecords));
    _sync();
  }

  void updateRecord(String vehicleId, VehicleRecord record) {
    final vehicle = state.vehicles.firstWhere((v) => v.id == vehicleId);
    final updatedRecords = List<VehicleRecord>.from(vehicle.records);
    final index = updatedRecords.indexWhere((r) => r.id == record.id);
    if (index != -1) {
      updatedRecords[index] = record;
    }
    _repository.update(vehicle.copyWith(records: updatedRecords));
    _sync();
  }

  void deleteRecord(String vehicleId, String recordId) {
    final vehicle = state.vehicles.firstWhere((v) => v.id == vehicleId);
    final updatedRecords = vehicle.records
        .where((r) => r.id != recordId)
        .toList();
    _repository.update(vehicle.copyWith(records: updatedRecords));
    _sync();
  }

  Vehicle? getVehicleById(String vehicleId) {
    final matches = state.vehicles.where((v) => v.id == vehicleId);
    return matches.isNotEmpty ? matches.first : null;
  }
}
