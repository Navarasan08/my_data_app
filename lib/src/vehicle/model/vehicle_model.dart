enum RecordType { fuel, service, purchase, importantDate, note }

class VehicleRecord {
  final String id;
  final RecordType type;
  final DateTime date;
  final String title;
  final String? description;
  final double? amount;
  final double? odometer;
  final String? location;
  final bool isImportant;

  VehicleRecord({
    required this.id,
    required this.type,
    required this.date,
    required this.title,
    this.description,
    this.amount,
    this.odometer,
    this.location,
    this.isImportant = false,
  });
}

class Vehicle {
  final String id;
  final String name;
  final String brand;
  final String model;
  final String year;
  final String registrationNumber;
  final String? vinNumber;
  final String? color;
  final DateTime purchaseDate;
  final double? purchasePrice;
  final List<VehicleRecord> records;

  Vehicle({
    required this.id,
    required this.name,
    required this.brand,
    required this.model,
    required this.year,
    required this.registrationNumber,
    this.vinNumber,
    this.color,
    required this.purchaseDate,
    this.purchasePrice,
    this.records = const [],
  });

  Vehicle copyWith({
    String? id,
    String? name,
    String? brand,
    String? model,
    String? year,
    String? registrationNumber,
    String? vinNumber,
    String? color,
    DateTime? purchaseDate,
    double? purchasePrice,
    List<VehicleRecord>? records,
  }) {
    return Vehicle(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      year: year ?? this.year,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      vinNumber: vinNumber ?? this.vinNumber,
      color: color ?? this.color,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      records: records ?? this.records,
    );
  }
}
