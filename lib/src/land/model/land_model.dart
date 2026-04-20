import 'package:flutter/material.dart';

enum LandType {
  residentialPlot,
  agricultural,
  commercial,
  industrial,
  house,
  apartment,
  farmHouse,
  other,
}

extension LandTypeExt on LandType {
  String get label {
    switch (this) {
      case LandType.residentialPlot: return 'Residential Plot';
      case LandType.agricultural: return 'Agricultural';
      case LandType.commercial: return 'Commercial';
      case LandType.industrial: return 'Industrial';
      case LandType.house: return 'House';
      case LandType.apartment: return 'Apartment';
      case LandType.farmHouse: return 'Farm House';
      case LandType.other: return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case LandType.residentialPlot: return Icons.location_on_rounded;
      case LandType.agricultural: return Icons.agriculture_rounded;
      case LandType.commercial: return Icons.store_rounded;
      case LandType.industrial: return Icons.factory_rounded;
      case LandType.house: return Icons.home_rounded;
      case LandType.apartment: return Icons.apartment_rounded;
      case LandType.farmHouse: return Icons.holiday_village_rounded;
      case LandType.other: return Icons.map_rounded;
    }
  }

  Color get color {
    switch (this) {
      case LandType.residentialPlot: return Colors.blue;
      case LandType.agricultural: return Colors.green;
      case LandType.commercial: return Colors.orange;
      case LandType.industrial: return Colors.brown;
      case LandType.house: return Colors.indigo;
      case LandType.apartment: return Colors.purple;
      case LandType.farmHouse: return Colors.teal;
      case LandType.other: return Colors.grey;
    }
  }
}

enum AreaUnit { sqft, sqm, acres, cents, guntha, bigha, hectare }

extension AreaUnitExt on AreaUnit {
  String get label {
    switch (this) {
      case AreaUnit.sqft: return 'sq.ft';
      case AreaUnit.sqm: return 'sq.m';
      case AreaUnit.acres: return 'acres';
      case AreaUnit.cents: return 'cents';
      case AreaUnit.guntha: return 'guntha';
      case AreaUnit.bigha: return 'bigha';
      case AreaUnit.hectare: return 'hectare';
    }
  }
}

class LandRecord {
  final String id;
  final String name;                // nickname / label
  final LandType type;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Listing info
  final String? description;        // long-form description
  final List<String> photoUrls;     // uploaded photo URLs
  final double? askingPrice;        // optional "for sale" price

  // Core
  final String? surveyNumber;       // survey no / sub-division
  final String? subDivision;
  final String? pattaNumber;        // patta / title deed number
  final double? areaValue;
  final AreaUnit areaUnit;

  // Location
  final String? addressLine;
  final String? village;
  final String? taluka;
  final String? district;
  final String? state;
  final String? pincode;
  final String? country;
  final String? landmark;
  final String? latitude;
  final String? longitude;

  // Owner
  final String? ownerName;
  final String? ownerContact;
  final String? coOwners;           // free text

  // Purchase
  final DateTime? purchaseDate;
  final double? purchasePrice;
  final String? sellerName;
  final String? registrationNumber;
  final DateTime? registrationDate;
  final String? registrarOffice;
  final double? stampDuty;
  final double? registrationFee;

  // Valuation
  final double? currentMarketValue;
  final double? guidelineValue;

  // Boundaries
  final String? boundaryNorth;
  final String? boundarySouth;
  final String? boundaryEast;
  final String? boundaryWest;

  // Tax / legal
  final String? propertyTaxNumber;
  final DateTime? lastTaxPaidDate;
  final String? encumbranceStatus;  // free text e.g. "Clear / EC up to 2024"
  final String? ecNumber;

  // Documents available (comma separated)
  final String? documentsAvailable;

  // Notes
  final String? notes;

  const LandRecord({
    required this.id,
    required this.name,
    required this.type,
    this.isFavorite = false,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.photoUrls = const [],
    this.askingPrice,
    this.surveyNumber,
    this.subDivision,
    this.pattaNumber,
    this.areaValue,
    this.areaUnit = AreaUnit.sqft,
    this.addressLine,
    this.village,
    this.taluka,
    this.district,
    this.state,
    this.pincode,
    this.country,
    this.landmark,
    this.latitude,
    this.longitude,
    this.ownerName,
    this.ownerContact,
    this.coOwners,
    this.purchaseDate,
    this.purchasePrice,
    this.sellerName,
    this.registrationNumber,
    this.registrationDate,
    this.registrarOffice,
    this.stampDuty,
    this.registrationFee,
    this.currentMarketValue,
    this.guidelineValue,
    this.boundaryNorth,
    this.boundarySouth,
    this.boundaryEast,
    this.boundaryWest,
    this.propertyTaxNumber,
    this.lastTaxPaidDate,
    this.encumbranceStatus,
    this.ecNumber,
    this.documentsAvailable,
    this.notes,
  });

  String get areaDisplay {
    if (areaValue == null) return '';
    final v = areaValue!;
    final vStr = v == v.roundToDouble() ? v.toInt().toString() : v.toString();
    return '$vStr ${areaUnit.label}';
  }

  String get locationShort {
    final parts = <String>[];
    if (village != null && village!.isNotEmpty) parts.add(village!);
    if (district != null && district!.isNotEmpty) parts.add(district!);
    if (state != null && state!.isNotEmpty) parts.add(state!);
    return parts.join(', ');
  }

  String get mapsUrl {
    if (latitude == null || longitude == null) return '';
    return 'https://www.google.com/maps?q=$latitude,$longitude';
  }

  /// Produces a list of (section, key, value) for display and share.
  /// Empty values are omitted.
  List<MapEntry<String, Map<String, String>>> asShareSections() {
    String f(String? v) => v == null || v.isEmpty ? '' : v;
    String d(DateTime? v) =>
        v == null ? '' : '${v.day}/${v.month}/${v.year}';
    String n(num? v) => v == null ? '' : v.toString();

    final core = <String, String>{
      'Name': name,
      'Type': type.label,
      'Asking Price': n(askingPrice),
      'Description': f(description),
      'Survey No': f(surveyNumber),
      'Sub-division': f(subDivision),
      'Patta No': f(pattaNumber),
      'Area': areaDisplay,
    };

    final location = <String, String>{
      'Address': f(addressLine),
      'Village': f(village),
      'Taluka': f(taluka),
      'District': f(district),
      'State': f(state),
      'PIN Code': f(pincode),
      'Country': f(country),
      'Landmark': f(landmark),
      'Latitude': f(latitude),
      'Longitude': f(longitude),
      if (mapsUrl.isNotEmpty) 'Maps Link': mapsUrl,
    };

    final owner = <String, String>{
      'Owner Name': f(ownerName),
      'Owner Contact': f(ownerContact),
      'Co-owners': f(coOwners),
    };

    final purchase = <String, String>{
      'Purchase Date': d(purchaseDate),
      'Purchase Price': n(purchasePrice),
      'Seller Name': f(sellerName),
      'Registration No': f(registrationNumber),
      'Registration Date': d(registrationDate),
      'Registrar Office': f(registrarOffice),
      'Stamp Duty': n(stampDuty),
      'Registration Fee': n(registrationFee),
    };

    final valuation = <String, String>{
      'Current Market Value': n(currentMarketValue),
      'Guideline Value': n(guidelineValue),
    };

    final boundaries = <String, String>{
      'North': f(boundaryNorth),
      'South': f(boundarySouth),
      'East': f(boundaryEast),
      'West': f(boundaryWest),
    };

    final legal = <String, String>{
      'Property Tax No': f(propertyTaxNumber),
      'Last Tax Paid': d(lastTaxPaidDate),
      'Encumbrance': f(encumbranceStatus),
      'EC Number': f(ecNumber),
      'Documents': f(documentsAvailable),
    };

    final other = <String, String>{
      'Notes': f(notes),
    };

    Map<String, String> nonEmpty(Map<String, String> m) {
      final out = <String, String>{};
      m.forEach((k, v) {
        if (v.isNotEmpty) out[k] = v;
      });
      return out;
    }

    final result = <MapEntry<String, Map<String, String>>>[
      MapEntry('Basic', nonEmpty(core)),
      MapEntry('Location', nonEmpty(location)),
      MapEntry('Owner', nonEmpty(owner)),
      MapEntry('Purchase & Registration', nonEmpty(purchase)),
      MapEntry('Valuation', nonEmpty(valuation)),
      MapEntry('Boundaries', nonEmpty(boundaries)),
      MapEntry('Tax & Legal', nonEmpty(legal)),
      MapEntry('Other', nonEmpty(other)),
    ];

    // drop empty sections
    return result.where((e) => e.value.isNotEmpty).toList();
  }

  /// Produce shareable text. If [selectedKeys] is provided, only those fields
  /// are included (flat "Section : Key" keys). Otherwise all non-empty fields.
  String toShareableText({Set<String>? selectedKeys}) {
    final buffer = StringBuffer();
    buffer.writeln('── $name ──');
    if (locationShort.isNotEmpty) buffer.writeln(locationShort);
    buffer.writeln();

    for (final section in asShareSections()) {
      final sectionLines = <String>[];
      section.value.forEach((k, v) {
        final flatKey = '${section.key} : $k';
        if (selectedKeys == null || selectedKeys.contains(flatKey)) {
          sectionLines.add('$k: $v');
        }
      });
      if (sectionLines.isNotEmpty) {
        buffer.writeln('[${section.key}]');
        for (final line in sectionLines) {
          buffer.writeln(line);
        }
        buffer.writeln();
      }
    }
    return buffer.toString().trim();
  }

  LandRecord copyWith({
    String? id,
    String? name,
    LandType? type,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? description,
    List<String>? photoUrls,
    double? askingPrice,
    String? surveyNumber,
    String? subDivision,
    String? pattaNumber,
    double? areaValue,
    AreaUnit? areaUnit,
    String? addressLine,
    String? village,
    String? taluka,
    String? district,
    String? state,
    String? pincode,
    String? country,
    String? landmark,
    String? latitude,
    String? longitude,
    String? ownerName,
    String? ownerContact,
    String? coOwners,
    DateTime? purchaseDate,
    double? purchasePrice,
    String? sellerName,
    String? registrationNumber,
    DateTime? registrationDate,
    String? registrarOffice,
    double? stampDuty,
    double? registrationFee,
    double? currentMarketValue,
    double? guidelineValue,
    String? boundaryNorth,
    String? boundarySouth,
    String? boundaryEast,
    String? boundaryWest,
    String? propertyTaxNumber,
    DateTime? lastTaxPaidDate,
    String? encumbranceStatus,
    String? ecNumber,
    String? documentsAvailable,
    String? notes,
  }) {
    return LandRecord(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      description: description ?? this.description,
      photoUrls: photoUrls ?? this.photoUrls,
      askingPrice: askingPrice ?? this.askingPrice,
      surveyNumber: surveyNumber ?? this.surveyNumber,
      subDivision: subDivision ?? this.subDivision,
      pattaNumber: pattaNumber ?? this.pattaNumber,
      areaValue: areaValue ?? this.areaValue,
      areaUnit: areaUnit ?? this.areaUnit,
      addressLine: addressLine ?? this.addressLine,
      village: village ?? this.village,
      taluka: taluka ?? this.taluka,
      district: district ?? this.district,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      country: country ?? this.country,
      landmark: landmark ?? this.landmark,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      ownerName: ownerName ?? this.ownerName,
      ownerContact: ownerContact ?? this.ownerContact,
      coOwners: coOwners ?? this.coOwners,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellerName: sellerName ?? this.sellerName,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      registrationDate: registrationDate ?? this.registrationDate,
      registrarOffice: registrarOffice ?? this.registrarOffice,
      stampDuty: stampDuty ?? this.stampDuty,
      registrationFee: registrationFee ?? this.registrationFee,
      currentMarketValue: currentMarketValue ?? this.currentMarketValue,
      guidelineValue: guidelineValue ?? this.guidelineValue,
      boundaryNorth: boundaryNorth ?? this.boundaryNorth,
      boundarySouth: boundarySouth ?? this.boundarySouth,
      boundaryEast: boundaryEast ?? this.boundaryEast,
      boundaryWest: boundaryWest ?? this.boundaryWest,
      propertyTaxNumber: propertyTaxNumber ?? this.propertyTaxNumber,
      lastTaxPaidDate: lastTaxPaidDate ?? this.lastTaxPaidDate,
      encumbranceStatus: encumbranceStatus ?? this.encumbranceStatus,
      ecNumber: ecNumber ?? this.ecNumber,
      documentsAvailable: documentsAvailable ?? this.documentsAvailable,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.index,
        'isFavorite': isFavorite,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'description': description,
        'photoUrls': photoUrls,
        'askingPrice': askingPrice,
        'surveyNumber': surveyNumber,
        'subDivision': subDivision,
        'pattaNumber': pattaNumber,
        'areaValue': areaValue,
        'areaUnit': areaUnit.index,
        'addressLine': addressLine,
        'village': village,
        'taluka': taluka,
        'district': district,
        'state': state,
        'pincode': pincode,
        'country': country,
        'landmark': landmark,
        'latitude': latitude,
        'longitude': longitude,
        'ownerName': ownerName,
        'ownerContact': ownerContact,
        'coOwners': coOwners,
        'purchaseDate': purchaseDate?.toIso8601String(),
        'purchasePrice': purchasePrice,
        'sellerName': sellerName,
        'registrationNumber': registrationNumber,
        'registrationDate': registrationDate?.toIso8601String(),
        'registrarOffice': registrarOffice,
        'stampDuty': stampDuty,
        'registrationFee': registrationFee,
        'currentMarketValue': currentMarketValue,
        'guidelineValue': guidelineValue,
        'boundaryNorth': boundaryNorth,
        'boundarySouth': boundarySouth,
        'boundaryEast': boundaryEast,
        'boundaryWest': boundaryWest,
        'propertyTaxNumber': propertyTaxNumber,
        'lastTaxPaidDate': lastTaxPaidDate?.toIso8601String(),
        'encumbranceStatus': encumbranceStatus,
        'ecNumber': ecNumber,
        'documentsAvailable': documentsAvailable,
        'notes': notes,
      };

  factory LandRecord.fromJson(Map<String, dynamic> json) {
    DateTime? parse(dynamic v) =>
        v == null ? null : DateTime.parse(v as String);
    double? toDouble(dynamic v) => (v as num?)?.toDouble();

    return LandRecord(
      id: json['id'] as String,
      name: json['name'] as String,
      type: LandType.values[
          (json['type'] as int).clamp(0, LandType.values.length - 1)],
      isFavorite: json['isFavorite'] as bool? ?? false,
      createdAt: parse(json['createdAt']) ?? DateTime.now(),
      updatedAt: parse(json['updatedAt']) ?? DateTime.now(),
      description: json['description'] as String?,
      photoUrls: (json['photoUrls'] as List<dynamic>?)?.cast<String>() ?? const [],
      askingPrice: toDouble(json['askingPrice']),
      surveyNumber: json['surveyNumber'] as String?,
      subDivision: json['subDivision'] as String?,
      pattaNumber: json['pattaNumber'] as String?,
      areaValue: toDouble(json['areaValue']),
      areaUnit: json['areaUnit'] != null
          ? AreaUnit.values[
              (json['areaUnit'] as int).clamp(0, AreaUnit.values.length - 1)]
          : AreaUnit.sqft,
      addressLine: json['addressLine'] as String?,
      village: json['village'] as String?,
      taluka: json['taluka'] as String?,
      district: json['district'] as String?,
      state: json['state'] as String?,
      pincode: json['pincode'] as String?,
      country: json['country'] as String?,
      landmark: json['landmark'] as String?,
      latitude: json['latitude'] as String?,
      longitude: json['longitude'] as String?,
      ownerName: json['ownerName'] as String?,
      ownerContact: json['ownerContact'] as String?,
      coOwners: json['coOwners'] as String?,
      purchaseDate: parse(json['purchaseDate']),
      purchasePrice: toDouble(json['purchasePrice']),
      sellerName: json['sellerName'] as String?,
      registrationNumber: json['registrationNumber'] as String?,
      registrationDate: parse(json['registrationDate']),
      registrarOffice: json['registrarOffice'] as String?,
      stampDuty: toDouble(json['stampDuty']),
      registrationFee: toDouble(json['registrationFee']),
      currentMarketValue: toDouble(json['currentMarketValue']),
      guidelineValue: toDouble(json['guidelineValue']),
      boundaryNorth: json['boundaryNorth'] as String?,
      boundarySouth: json['boundarySouth'] as String?,
      boundaryEast: json['boundaryEast'] as String?,
      boundaryWest: json['boundaryWest'] as String?,
      propertyTaxNumber: json['propertyTaxNumber'] as String?,
      lastTaxPaidDate: parse(json['lastTaxPaidDate']),
      encumbranceStatus: json['encumbranceStatus'] as String?,
      ecNumber: json['ecNumber'] as String?,
      documentsAvailable: json['documentsAvailable'] as String?,
      notes: json['notes'] as String?,
    );
  }
}
