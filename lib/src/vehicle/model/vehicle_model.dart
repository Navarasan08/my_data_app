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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.index,
      'date': date.toIso8601String(),
      'title': title,
      'description': description,
      'amount': amount,
      'odometer': odometer,
      'location': location,
      'isImportant': isImportant,
    };
  }

  factory VehicleRecord.fromJson(Map<String, dynamic> json) {
    return VehicleRecord(
      id: json['id'] as String,
      type: RecordType.values[json['type'] as int],
      date: DateTime.parse(json['date'] as String),
      title: json['title'] as String,
      description: json['description'] as String?,
      amount: (json['amount'] as num?)?.toDouble(),
      odometer: (json['odometer'] as num?)?.toDouble(),
      location: json['location'] as String?,
      isImportant: json['isImportant'] as bool? ?? false,
    );
  }
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'model': model,
      'year': year,
      'registrationNumber': registrationNumber,
      'vinNumber': vinNumber,
      'color': color,
      'purchaseDate': purchaseDate.toIso8601String(),
      'purchasePrice': purchasePrice,
      'records': records.map((r) => r.toJson()).toList(),
    };
  }

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] as String,
      name: json['name'] as String,
      brand: json['brand'] as String,
      model: json['model'] as String,
      year: json['year'] as String,
      registrationNumber: json['registrationNumber'] as String,
      vinNumber: json['vinNumber'] as String?,
      color: json['color'] as String?,
      purchaseDate: DateTime.parse(json['purchaseDate'] as String),
      purchasePrice: (json['purchasePrice'] as num?)?.toDouble(),
      records: (json['records'] as List<dynamic>?)
              ?.map((r) => VehicleRecord.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
