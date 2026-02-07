import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_data_app/src/vehicle/model/vehicle_model.dart';

abstract class VehicleRepository {
  List<Vehicle> getAll();
  void add(Vehicle vehicle);
  void update(Vehicle vehicle);
  void delete(String vehicleId);
  Future<void> init();
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
  Future<void> init() async {}

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

class LocalStorageVehicleRepository implements VehicleRepository {
  static const String _storageKey = 'vehicles_data';
  final SharedPreferences _prefs;
  List<Vehicle> _vehicles = [];

  LocalStorageVehicleRepository(this._prefs);

  @override
  Future<void> init() async {
    await _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    final jsonString = _prefs.getString(_storageKey);
    if (jsonString != null) {
      final List<dynamic> jsonList = json.decode(jsonString);
      _vehicles = jsonList
          .map((item) => Vehicle.fromJson(item as Map<String, dynamic>))
          .toList();
    } else {
      // Initialize with seed data if empty
      _vehicles = [
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
      await _saveToStorage();
    }
  }

  Future<void> _saveToStorage() async {
    final jsonList = _vehicles.map((vehicle) => vehicle.toJson()).toList();
    await _prefs.setString(_storageKey, json.encode(jsonList));
  }

  @override
  List<Vehicle> getAll() => List.unmodifiable(_vehicles);

  @override
  void add(Vehicle vehicle) {
    _vehicles.add(vehicle);
    _saveToStorage();
  }

  @override
  void update(Vehicle vehicle) {
    final index = _vehicles.indexWhere((v) => v.id == vehicle.id);
    if (index != -1) {
      _vehicles[index] = vehicle;
      _saveToStorage();
    }
  }

  @override
  void delete(String vehicleId) {
    _vehicles.removeWhere((v) => v.id == vehicleId);
    _saveToStorage();
  }
}

class FirestoreVehicleRepository implements VehicleRepository {
  final String uid;
  final FirebaseFirestore _firestore;
  List<Vehicle> _vehicles = [];

  FirestoreVehicleRepository({required this.uid, FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('users').doc(uid).collection('vehicles');

  @override
  Future<void> init() async {
    final snapshot = await _collection.get();
    _vehicles = snapshot.docs
        .map((doc) => Vehicle.fromJson(doc.data()))
        .toList();
  }

  @override
  List<Vehicle> getAll() => List.unmodifiable(_vehicles);

  @override
  void add(Vehicle vehicle) {
    _vehicles.add(vehicle);
    _collection.doc(vehicle.id).set(vehicle.toJson());
  }

  @override
  void update(Vehicle vehicle) {
    final index = _vehicles.indexWhere((v) => v.id == vehicle.id);
    if (index != -1) {
      _vehicles[index] = vehicle;
      _collection.doc(vehicle.id).set(vehicle.toJson());
    }
  }

  @override
  void delete(String vehicleId) {
    _vehicles.removeWhere((v) => v.id == vehicleId);
    _collection.doc(vehicleId).delete();
  }
}
