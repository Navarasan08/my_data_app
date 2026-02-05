import 'package:my_data_app/src/vehicle/model/vehicle_model.dart';

abstract class VehicleRepository {
  List<Vehicle> getAll();
  void add(Vehicle vehicle);
  void update(Vehicle vehicle);
  void delete(String vehicleId);
}

class InMemoryVehicleRepository implements VehicleRepository {
  final List<Vehicle> _vehicles;

  InMemoryVehicleRepository()
      : _vehicles = [
          Vehicle(
            id: '1',
            name: 'My Honda',
            brand: 'Honda',
            model: 'Civic',
            year: '2020',
            registrationNumber: 'ABC-1234',
            color: 'Silver',
            purchaseDate: DateTime(2020, 3, 15),
            purchasePrice: 25000,
            records: [
              VehicleRecord(
                id: '1',
                type: RecordType.fuel,
                date: DateTime.now().subtract(const Duration(days: 2)),
                title: 'Gas Fill-up',
                amount: 45.50,
                odometer: 45230,
                location: 'Shell Station',
              ),
              VehicleRecord(
                id: '2',
                type: RecordType.service,
                date: DateTime.now().subtract(const Duration(days: 30)),
                title: 'Oil Change',
                description: 'Regular maintenance - oil and filter change',
                amount: 75.00,
                odometer: 44800,
              ),
            ],
          ),
        ];

  @override
  List<Vehicle> getAll() => List.unmodifiable(_vehicles);

  @override
  void add(Vehicle vehicle) {
    _vehicles.add(vehicle);
  }

  @override
  void update(Vehicle vehicle) {
    final index = _vehicles.indexWhere((v) => v.id == vehicle.id);
    if (index != -1) {
      _vehicles[index] = vehicle;
    }
  }

  @override
  void delete(String vehicleId) {
    _vehicles.removeWhere((v) => v.id == vehicleId);
  }
}
