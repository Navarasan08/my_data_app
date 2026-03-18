import 'package:flutter/material.dart';

// ── Section Types ──────────────────────────────────────────────────────────

enum VaultSection {
  basicDetails, address, govtId, bankAccount, card, credential, vehicle, education, employment, insurance, socialMedia, emergencyContact, hobby
}

extension VaultSectionExt on VaultSection {
  String get label {
    switch (this) {
      case VaultSection.basicDetails: return 'Basic Details';
      case VaultSection.address: return 'Addresses';
      case VaultSection.govtId: return 'Government IDs';
      case VaultSection.bankAccount: return 'Bank Accounts';
      case VaultSection.card: return 'Cards';
      case VaultSection.credential: return 'Accounts & Passwords';
      case VaultSection.vehicle: return 'Vehicles';
      case VaultSection.education: return 'Education';
      case VaultSection.employment: return 'Employment';
      case VaultSection.insurance: return 'Insurance';
      case VaultSection.socialMedia: return 'Social Media';
      case VaultSection.emergencyContact: return 'Emergency Contacts';
      case VaultSection.hobby: return 'Hobbies & Interests';
    }
  }
  IconData get icon {
    switch (this) {
      case VaultSection.basicDetails: return Icons.person_rounded;
      case VaultSection.address: return Icons.location_on_rounded;
      case VaultSection.govtId: return Icons.badge_rounded;
      case VaultSection.bankAccount: return Icons.account_balance_rounded;
      case VaultSection.card: return Icons.credit_card_rounded;
      case VaultSection.credential: return Icons.lock_rounded;
      case VaultSection.vehicle: return Icons.directions_car_rounded;
      case VaultSection.education: return Icons.school_rounded;
      case VaultSection.employment: return Icons.work_rounded;
      case VaultSection.insurance: return Icons.health_and_safety_rounded;
      case VaultSection.socialMedia: return Icons.share_rounded;
      case VaultSection.emergencyContact: return Icons.emergency_rounded;
      case VaultSection.hobby: return Icons.sports_esports_rounded;
    }
  }
  Color get color {
    switch (this) {
      case VaultSection.basicDetails: return Colors.blue;
      case VaultSection.address: return Colors.green;
      case VaultSection.govtId: return Colors.indigo;
      case VaultSection.bankAccount: return Colors.teal;
      case VaultSection.card: return Colors.purple;
      case VaultSection.credential: return Colors.red;
      case VaultSection.vehicle: return Colors.orange;
      case VaultSection.education: return Colors.cyan;
      case VaultSection.employment: return Colors.brown;
      case VaultSection.insurance: return Colors.pink;
      case VaultSection.socialMedia: return Colors.deepPurple;
      case VaultSection.emergencyContact: return Colors.redAccent;
      case VaultSection.hobby: return Colors.amber;
    }
  }
}

// ── VaultEntry - generic container for any section data ────────────────────

class VaultEntry {
  final String id;
  final VaultSection section;
  final String title; // display title for this entry
  final Map<String, String> fields; // key-value pairs for all data
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isFavorite; // pin important entries

  const VaultEntry({
    required this.id,
    required this.section,
    required this.title,
    required this.fields,
    required this.createdAt,
    required this.updatedAt,
    this.isFavorite = false,
  });

  /// Get shareable text for this entry
  String toShareableText({List<String>? selectedKeys}) {
    final buffer = StringBuffer();
    buffer.writeln('── $title ──');
    final keys = selectedKeys ?? fields.keys.toList();
    for (final key in keys) {
      if (fields.containsKey(key) && fields[key]!.isNotEmpty) {
        buffer.writeln('$key: ${fields[key]}');
      }
    }
    return buffer.toString().trim();
  }

  VaultEntry copyWith({
    String? id, VaultSection? section, String? title,
    Map<String, String>? fields, DateTime? createdAt,
    DateTime? updatedAt, bool? isFavorite,
  }) => VaultEntry(
    id: id ?? this.id, section: section ?? this.section,
    title: title ?? this.title, fields: fields ?? this.fields,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    isFavorite: isFavorite ?? this.isFavorite,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'section': section.index,
    'title': title, 'fields': fields,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'isFavorite': isFavorite,
  };

  factory VaultEntry.fromJson(Map<String, dynamic> json) => VaultEntry(
    id: json['id'] as String,
    section: VaultSection.values[(json['section'] as int).clamp(0, VaultSection.values.length - 1)],
    title: json['title'] as String,
    fields: (json['fields'] as Map<String, dynamic>).map((k, v) => MapEntry(k, v.toString())),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    isFavorite: json['isFavorite'] as bool? ?? false,
  );
}

// ── Template definitions for each section ──────────────────────────────────
// These define what fields each section type should have

class VaultTemplate {
  static List<String> fieldsFor(VaultSection section) {
    switch (section) {
      case VaultSection.basicDetails:
        return ['Full Name', 'Date of Birth', 'Gender', 'Blood Group', 'Phone', 'Alt Phone', 'Email', 'Alt Email', 'Nationality', 'Religion', 'Languages', 'Marital Status'];
      case VaultSection.address:
        return ['Label', 'Door/Flat No', 'Street', 'Area/Locality', 'City', 'District', 'State', 'PIN Code', 'Country', 'Landmark'];
      case VaultSection.govtId:
        return ['ID Type', 'ID Number', 'Name on ID', 'Issue Date', 'Expiry Date', 'Issued By', 'Notes'];
      case VaultSection.bankAccount:
        return ['Bank Name', 'Branch', 'Account Number', 'IFSC Code', 'Account Type', 'Account Holder', 'UPI ID', 'Net Banking ID', 'Nominee', 'Notes'];
      case VaultSection.card:
        return ['Card Type', 'Bank/Issuer', 'Card Number (Last 4)', 'Card Holder Name', 'Expiry', 'Billing Address', 'Credit Limit', 'Notes'];
      case VaultSection.credential:
        return ['Service/Website', 'Username/Email', 'Password', 'PIN', 'Security Question', 'Security Answer', 'Recovery Email', 'Recovery Phone', '2FA Method', 'Notes'];
      case VaultSection.vehicle:
        return ['Vehicle Type', 'Make', 'Model', 'Year', 'Registration No', 'Chassis No', 'Engine No', 'Color', 'Fuel Type', 'Insurance Provider', 'Insurance Expiry', 'PUC Expiry', 'Notes'];
      case VaultSection.education:
        return ['Degree/Course', 'Institution', 'University', 'Year of Passing', 'Percentage/CGPA', 'Roll Number', 'Specialization', 'Notes'];
      case VaultSection.employment:
        return ['Company', 'Designation', 'Employee ID', 'Department', 'Join Date', 'End Date', 'Work Location', 'Manager', 'HR Contact', 'PF Number', 'UAN', 'Notes'];
      case VaultSection.insurance:
        return ['Policy Type', 'Provider', 'Policy Number', 'Policy Holder', 'Premium Amount', 'Premium Frequency', 'Start Date', 'End Date', 'Sum Assured', 'Nominee', 'Agent Name', 'Agent Phone', 'Notes'];
      case VaultSection.socialMedia:
        return ['Platform', 'Profile Name', 'Username/Handle', 'Email Used', 'Phone Used', 'Profile URL', 'Notes'];
      case VaultSection.emergencyContact:
        return ['Name', 'Relation', 'Phone', 'Alt Phone', 'Email', 'Address', 'Notes'];
      case VaultSection.hobby:
        return ['Hobby/Interest', 'Category', 'Level', 'Since', 'Notes'];
    }
  }

  /// Common ID types for govt IDs (Indian context)
  static List<String> get govtIdTypes => [
    'Aadhaar Card', 'PAN Card', 'Passport', 'Driving License',
    'Voter ID', 'Ration Card', 'Birth Certificate', 'Other',
  ];

  /// Common card types
  static List<String> get cardTypes => [
    'Debit Card', 'Credit Card', 'Prepaid Card', 'Forex Card', 'Other',
  ];

  /// Common account types
  static List<String> get accountTypes => [
    'Savings', 'Current', 'Salary', 'Fixed Deposit', 'NRI', 'Other',
  ];

  /// Common insurance types
  static List<String> get insuranceTypes => [
    'Health', 'Life', 'Term', 'Vehicle', 'Home', 'Travel', 'Other',
  ];
}
