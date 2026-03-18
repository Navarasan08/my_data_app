import 'package:flutter/material.dart';

// ── Family Member ──────────────────────────────────────────────────────────

enum Gender { male, female, other }

extension GenderExt on Gender {
  String get label {
    switch (this) {
      case Gender.male: return 'Male';
      case Gender.female: return 'Female';
      case Gender.other: return 'Other';
    }
  }
  IconData get icon {
    switch (this) {
      case Gender.male: return Icons.male_rounded;
      case Gender.female: return Icons.female_rounded;
      case Gender.other: return Icons.person_rounded;
    }
  }
}

enum BloodGroup { aPos, aNeg, bPos, bNeg, abPos, abNeg, oPos, oNeg, unknown }

extension BloodGroupExt on BloodGroup {
  String get label {
    switch (this) {
      case BloodGroup.aPos: return 'A+';
      case BloodGroup.aNeg: return 'A-';
      case BloodGroup.bPos: return 'B+';
      case BloodGroup.bNeg: return 'B-';
      case BloodGroup.abPos: return 'AB+';
      case BloodGroup.abNeg: return 'AB-';
      case BloodGroup.oPos: return 'O+';
      case BloodGroup.oNeg: return 'O-';
      case BloodGroup.unknown: return 'Unknown';
    }
  }
}

enum Relation { self, spouse, child, parent, sibling, other }

extension RelationExt on Relation {
  String get label {
    switch (this) {
      case Relation.self: return 'Self';
      case Relation.spouse: return 'Spouse';
      case Relation.child: return 'Child';
      case Relation.parent: return 'Parent';
      case Relation.sibling: return 'Sibling';
      case Relation.other: return 'Other';
    }
  }
  IconData get icon {
    switch (this) {
      case Relation.self: return Icons.person_rounded;
      case Relation.spouse: return Icons.favorite_rounded;
      case Relation.child: return Icons.child_care_rounded;
      case Relation.parent: return Icons.elderly_rounded;
      case Relation.sibling: return Icons.group_rounded;
      case Relation.other: return Icons.person_outline_rounded;
    }
  }
}

class FamilyMember {
  final String id;
  final String name;
  final Relation relation;
  final Gender gender;
  final DateTime? dateOfBirth;
  final BloodGroup bloodGroup;
  final double? height; // in cm
  final double? weight; // in kg
  final List<String> allergies;
  final List<String> chronicConditions;
  final String? emergencyContact;
  final String? insuranceInfo;
  final String? notes;

  const FamilyMember({
    required this.id,
    required this.name,
    required this.relation,
    this.gender = Gender.other,
    this.dateOfBirth,
    this.bloodGroup = BloodGroup.unknown,
    this.height,
    this.weight,
    this.allergies = const [],
    this.chronicConditions = const [],
    this.emergencyContact,
    this.insuranceInfo,
    this.notes,
  });

  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  FamilyMember copyWith({
    String? id, String? name, Relation? relation, Gender? gender,
    DateTime? dateOfBirth, BloodGroup? bloodGroup,
    double? height, double? weight,
    List<String>? allergies, List<String>? chronicConditions,
    String? emergencyContact, String? insuranceInfo, String? notes,
  }) => FamilyMember(
    id: id ?? this.id, name: name ?? this.name,
    relation: relation ?? this.relation, gender: gender ?? this.gender,
    dateOfBirth: dateOfBirth ?? this.dateOfBirth,
    bloodGroup: bloodGroup ?? this.bloodGroup,
    height: height ?? this.height, weight: weight ?? this.weight,
    allergies: allergies ?? this.allergies,
    chronicConditions: chronicConditions ?? this.chronicConditions,
    emergencyContact: emergencyContact ?? this.emergencyContact,
    insuranceInfo: insuranceInfo ?? this.insuranceInfo,
    notes: notes ?? this.notes,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name,
    'relation': relation.index, 'gender': gender.index,
    'dateOfBirth': dateOfBirth?.toIso8601String(),
    'bloodGroup': bloodGroup.index,
    'height': height, 'weight': weight,
    'allergies': allergies, 'chronicConditions': chronicConditions,
    'emergencyContact': emergencyContact,
    'insuranceInfo': insuranceInfo, 'notes': notes,
  };

  factory FamilyMember.fromJson(Map<String, dynamic> json) => FamilyMember(
    id: json['id'] as String, name: json['name'] as String,
    relation: Relation.values[(json['relation'] as int).clamp(0, Relation.values.length - 1)],
    gender: json['gender'] != null ? Gender.values[(json['gender'] as int).clamp(0, Gender.values.length - 1)] : Gender.other,
    dateOfBirth: json['dateOfBirth'] != null ? DateTime.parse(json['dateOfBirth'] as String) : null,
    bloodGroup: json['bloodGroup'] != null ? BloodGroup.values[(json['bloodGroup'] as int).clamp(0, BloodGroup.values.length - 1)] : BloodGroup.unknown,
    height: (json['height'] as num?)?.toDouble(),
    weight: (json['weight'] as num?)?.toDouble(),
    allergies: (json['allergies'] as List<dynamic>?)?.cast<String>() ?? [],
    chronicConditions: (json['chronicConditions'] as List<dynamic>?)?.cast<String>() ?? [],
    emergencyContact: json['emergencyContact'] as String?,
    insuranceInfo: json['insuranceInfo'] as String?,
    notes: json['notes'] as String?,
  );
}

// ── Medical Record ─────────────────────────────────────────────────────────

enum RecordType { consultation, labReport, prescription, vaccination, surgery, hospitalization, dental, eyeCheckup, other }

extension RecordTypeExt on RecordType {
  String get label {
    switch (this) {
      case RecordType.consultation: return 'Consultation';
      case RecordType.labReport: return 'Lab Report';
      case RecordType.prescription: return 'Prescription';
      case RecordType.vaccination: return 'Vaccination';
      case RecordType.surgery: return 'Surgery';
      case RecordType.hospitalization: return 'Hospitalization';
      case RecordType.dental: return 'Dental';
      case RecordType.eyeCheckup: return 'Eye Checkup';
      case RecordType.other: return 'Other';
    }
  }
  IconData get icon {
    switch (this) {
      case RecordType.consultation: return Icons.medical_services_rounded;
      case RecordType.labReport: return Icons.science_rounded;
      case RecordType.prescription: return Icons.medication_rounded;
      case RecordType.vaccination: return Icons.vaccines_rounded;
      case RecordType.surgery: return Icons.local_hospital_rounded;
      case RecordType.hospitalization: return Icons.hotel_rounded;
      case RecordType.dental: return Icons.health_and_safety_rounded;
      case RecordType.eyeCheckup: return Icons.visibility_rounded;
      case RecordType.other: return Icons.note_alt_rounded;
    }
  }
  Color get color {
    switch (this) {
      case RecordType.consultation: return Colors.blue;
      case RecordType.labReport: return Colors.purple;
      case RecordType.prescription: return Colors.teal;
      case RecordType.vaccination: return Colors.green;
      case RecordType.surgery: return Colors.red;
      case RecordType.hospitalization: return Colors.orange;
      case RecordType.dental: return Colors.cyan;
      case RecordType.eyeCheckup: return Colors.indigo;
      case RecordType.other: return Colors.grey;
    }
  }
}

class MedicalRecord {
  final String id;
  final String memberId;
  final RecordType type;
  final String title;
  final String? doctorName;
  final String? hospitalName;
  final String? speciality; // e.g. Cardiologist, Dermatologist
  final DateTime date;
  final DateTime? followUpDate;
  final String? diagnosis;
  final String? notes;
  final List<Medication> medications;
  final List<String> symptoms;
  final List<LabResult> labResults;
  final double? amount;
  final bool isCovered; // by insurance

  const MedicalRecord({
    required this.id,
    required this.memberId,
    required this.type,
    required this.title,
    this.doctorName,
    this.hospitalName,
    this.speciality,
    required this.date,
    this.followUpDate,
    this.diagnosis,
    this.notes,
    this.medications = const [],
    this.symptoms = const [],
    this.labResults = const [],
    this.amount,
    this.isCovered = false,
  });

  MedicalRecord copyWith({
    String? id, String? memberId, RecordType? type, String? title,
    String? doctorName, String? hospitalName, String? speciality,
    DateTime? date, DateTime? followUpDate,
    String? diagnosis, String? notes,
    List<Medication>? medications, List<String>? symptoms,
    List<LabResult>? labResults, double? amount, bool? isCovered,
  }) => MedicalRecord(
    id: id ?? this.id, memberId: memberId ?? this.memberId,
    type: type ?? this.type, title: title ?? this.title,
    doctorName: doctorName ?? this.doctorName,
    hospitalName: hospitalName ?? this.hospitalName,
    speciality: speciality ?? this.speciality,
    date: date ?? this.date, followUpDate: followUpDate ?? this.followUpDate,
    diagnosis: diagnosis ?? this.diagnosis, notes: notes ?? this.notes,
    medications: medications ?? this.medications,
    symptoms: symptoms ?? this.symptoms,
    labResults: labResults ?? this.labResults,
    amount: amount ?? this.amount, isCovered: isCovered ?? this.isCovered,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'memberId': memberId, 'type': type.index,
    'title': title, 'doctorName': doctorName,
    'hospitalName': hospitalName, 'speciality': speciality,
    'date': date.toIso8601String(),
    'followUpDate': followUpDate?.toIso8601String(),
    'diagnosis': diagnosis, 'notes': notes,
    'medications': medications.map((m) => m.toJson()).toList(),
    'symptoms': symptoms,
    'labResults': labResults.map((l) => l.toJson()).toList(),
    'amount': amount, 'isCovered': isCovered,
  };

  factory MedicalRecord.fromJson(Map<String, dynamic> json) => MedicalRecord(
    id: json['id'] as String,
    memberId: json['memberId'] as String,
    type: RecordType.values[(json['type'] as int).clamp(0, RecordType.values.length - 1)],
    title: json['title'] as String,
    doctorName: json['doctorName'] as String?,
    hospitalName: json['hospitalName'] as String?,
    speciality: json['speciality'] as String?,
    date: DateTime.parse(json['date'] as String),
    followUpDate: json['followUpDate'] != null ? DateTime.parse(json['followUpDate'] as String) : null,
    diagnosis: json['diagnosis'] as String?,
    notes: json['notes'] as String?,
    medications: (json['medications'] as List<dynamic>?)?.map((m) => Medication.fromJson(m as Map<String, dynamic>)).toList() ?? [],
    symptoms: (json['symptoms'] as List<dynamic>?)?.cast<String>() ?? [],
    labResults: (json['labResults'] as List<dynamic>?)?.map((l) => LabResult.fromJson(l as Map<String, dynamic>)).toList() ?? [],
    amount: (json['amount'] as num?)?.toDouble(),
    isCovered: json['isCovered'] as bool? ?? false,
  );
}

// ── Medication ─────────────────────────────────────────────────────────────

enum MedicationFrequency { onceDaily, twiceDaily, thriceDaily, asNeeded, weekly, custom }

extension MedicationFrequencyExt on MedicationFrequency {
  String get label {
    switch (this) {
      case MedicationFrequency.onceDaily: return 'Once daily';
      case MedicationFrequency.twiceDaily: return 'Twice daily';
      case MedicationFrequency.thriceDaily: return 'Thrice daily';
      case MedicationFrequency.asNeeded: return 'As needed';
      case MedicationFrequency.weekly: return 'Weekly';
      case MedicationFrequency.custom: return 'Custom';
    }
  }
}

enum MealTiming { beforeFood, afterFood, withFood, anytime }

extension MealTimingExt on MealTiming {
  String get label {
    switch (this) {
      case MealTiming.beforeFood: return 'Before food';
      case MealTiming.afterFood: return 'After food';
      case MealTiming.withFood: return 'With food';
      case MealTiming.anytime: return 'Anytime';
    }
  }
}

class Medication {
  final String name;
  final String? dosage; // e.g. "500mg"
  final MedicationFrequency frequency;
  final MealTiming mealTiming;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;
  final String? notes;
  final bool morning;
  final bool afternoon;
  final bool evening;
  final bool night;

  const Medication({
    required this.name,
    this.dosage,
    this.frequency = MedicationFrequency.onceDaily,
    this.mealTiming = MealTiming.afterFood,
    this.startDate,
    this.endDate,
    this.isActive = true,
    this.notes,
    this.morning = false,
    this.afternoon = false,
    this.evening = false,
    this.night = false,
  });

  int get durationDays {
    if (startDate == null || endDate == null) return 0;
    return endDate!.difference(startDate!).inDays;
  }

  String get timingLabel {
    final times = <String>[];
    if (morning) times.add('Morning');
    if (afternoon) times.add('Afternoon');
    if (evening) times.add('Evening');
    if (night) times.add('Night');
    return times.isEmpty ? frequency.label : times.join(', ');
  }

  Medication copyWith({
    String? name, String? dosage, MedicationFrequency? frequency,
    MealTiming? mealTiming, DateTime? startDate, DateTime? endDate,
    bool? isActive, String? notes,
    bool? morning, bool? afternoon, bool? evening, bool? night,
  }) => Medication(
    name: name ?? this.name, dosage: dosage ?? this.dosage,
    frequency: frequency ?? this.frequency,
    mealTiming: mealTiming ?? this.mealTiming,
    startDate: startDate ?? this.startDate, endDate: endDate ?? this.endDate,
    isActive: isActive ?? this.isActive, notes: notes ?? this.notes,
    morning: morning ?? this.morning, afternoon: afternoon ?? this.afternoon,
    evening: evening ?? this.evening, night: night ?? this.night,
  );

  Map<String, dynamic> toJson() => {
    'name': name, 'dosage': dosage,
    'frequency': frequency.index, 'mealTiming': mealTiming.index,
    'startDate': startDate?.toIso8601String(),
    'endDate': endDate?.toIso8601String(),
    'isActive': isActive, 'notes': notes,
    'morning': morning, 'afternoon': afternoon,
    'evening': evening, 'night': night,
  };

  factory Medication.fromJson(Map<String, dynamic> json) => Medication(
    name: json['name'] as String,
    dosage: json['dosage'] as String?,
    frequency: json['frequency'] != null ? MedicationFrequency.values[(json['frequency'] as int).clamp(0, MedicationFrequency.values.length - 1)] : MedicationFrequency.onceDaily,
    mealTiming: json['mealTiming'] != null ? MealTiming.values[(json['mealTiming'] as int).clamp(0, MealTiming.values.length - 1)] : MealTiming.afterFood,
    startDate: json['startDate'] != null ? DateTime.parse(json['startDate'] as String) : null,
    endDate: json['endDate'] != null ? DateTime.parse(json['endDate'] as String) : null,
    isActive: json['isActive'] as bool? ?? true,
    notes: json['notes'] as String?,
    morning: json['morning'] as bool? ?? false,
    afternoon: json['afternoon'] as bool? ?? false,
    evening: json['evening'] as bool? ?? false,
    night: json['night'] as bool? ?? false,
  );
}

// ── Lab Result ─────────────────────────────────────────────────────────────

class LabResult {
  final String testName;
  final String? value;
  final String? unit;
  final String? normalRange;
  final bool isAbnormal;

  const LabResult({
    required this.testName,
    this.value,
    this.unit,
    this.normalRange,
    this.isAbnormal = false,
  });

  LabResult copyWith({
    String? testName, String? value, String? unit,
    String? normalRange, bool? isAbnormal,
  }) => LabResult(
    testName: testName ?? this.testName,
    value: value ?? this.value,
    unit: unit ?? this.unit,
    normalRange: normalRange ?? this.normalRange,
    isAbnormal: isAbnormal ?? this.isAbnormal,
  );

  Map<String, dynamic> toJson() => {
    'testName': testName, 'value': value, 'unit': unit,
    'normalRange': normalRange, 'isAbnormal': isAbnormal,
  };

  factory LabResult.fromJson(Map<String, dynamic> json) => LabResult(
    testName: json['testName'] as String,
    value: json['value'] as String?,
    unit: json['unit'] as String?,
    normalRange: json['normalRange'] as String?,
    isAbnormal: json['isAbnormal'] as bool? ?? false,
  );
}
