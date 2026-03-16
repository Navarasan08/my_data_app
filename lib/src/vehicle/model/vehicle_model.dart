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
  final DateTime? nextServiceDate;

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
    this.nextServiceDate,
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
      'nextServiceDate': nextServiceDate?.toIso8601String(),
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
      nextServiceDate: json['nextServiceDate'] != null
          ? DateTime.parse(json['nextServiceDate'] as String)
          : null,
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

  /// Returns the nearest upcoming next-service-date from all service records,
  /// or null if none is set.
  DateTime? get nextServiceDate {
    DateTime? nearest;
    for (final r in records) {
      if (r.type == RecordType.service && r.nextServiceDate != null) {
        if (nearest == null || r.nextServiceDate!.isAfter(nearest)) {
          nearest = r.nextServiceDate;
        }
      }
    }
    return nearest;
  }

  /// Days left until the next service. Negative means overdue.
  int? get daysLeftForService {
    final nsd = nextServiceDate;
    if (nsd == null) return null;
    final now = DateTime.now();
    return DateTime(nsd.year, nsd.month, nsd.day)
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
  }

  // ── Computed stats ──────────────────────────────────────────────────────

  /// Latest odometer reading across all records
  double? get currentOdometer {
    double? max;
    for (final r in records) {
      if (r.odometer != null && (max == null || r.odometer! > max)) {
        max = r.odometer;
      }
    }
    return max;
  }

  /// Odometer at last service
  double? get lastServiceOdometer {
    VehicleRecord? latest;
    for (final r in records) {
      if (r.type == RecordType.service &&
          r.odometer != null &&
          (latest == null || r.date.isAfter(latest.date))) {
        latest = r;
      }
    }
    return latest?.odometer;
  }

  /// Date of last service
  DateTime? get lastServiceDate {
    DateTime? latest;
    for (final r in records) {
      if (r.type == RecordType.service &&
          (latest == null || r.date.isAfter(latest))) {
        latest = r.date;
      }
    }
    return latest;
  }

  /// Km driven since last service
  double? get kmSinceLastService {
    final current = currentOdometer;
    final lastSvc = lastServiceOdometer;
    if (current == null || lastSvc == null) return null;
    return current - lastSvc;
  }

  /// Last fuel fill record
  VehicleRecord? get lastFuelRecord {
    VehicleRecord? latest;
    for (final r in records) {
      if (r.type == RecordType.fuel &&
          (latest == null || r.date.isAfter(latest.date))) {
        latest = r;
      }
    }
    return latest;
  }

  /// Km driven since last fuel fill
  double? get kmSinceLastFuel {
    final current = currentOdometer;
    final lastFuel = lastFuelRecord?.odometer;
    if (current == null || lastFuel == null) return null;
    return current - lastFuel;
  }

  /// Total fuel expense
  double get totalFuelExpense {
    return records
        .where((r) => r.type == RecordType.fuel && r.amount != null)
        .fold(0.0, (sum, r) => sum + r.amount!);
  }

  /// Total service expense
  double get totalServiceExpense {
    return records
        .where((r) => r.type == RecordType.service && r.amount != null)
        .fold(0.0, (sum, r) => sum + r.amount!);
  }

  /// Total all expenses
  double get totalExpense {
    return records
        .where((r) => r.amount != null)
        .fold(0.0, (sum, r) => sum + r.amount!);
  }

  /// Ownership duration in days
  int get ownershipDays {
    return DateTime.now().difference(purchaseDate).inDays;
  }

  /// Total km driven (current odometer or 0)
  double get totalKmDriven => currentOdometer ?? 0;

  /// Average monthly expense
  double get avgMonthlyExpense {
    final months = ownershipDays / 30;
    if (months <= 0) return 0;
    return totalExpense / months;
  }

  /// Number of fuel fills
  int get fuelFillCount =>
      records.where((r) => r.type == RecordType.fuel).length;

  /// Number of services done
  int get serviceCount =>
      records.where((r) => r.type == RecordType.service).length;

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
