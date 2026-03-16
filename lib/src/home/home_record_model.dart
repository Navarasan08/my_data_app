import 'package:flutter/material.dart';

class HomeCategory {
  final String id;
  final String displayName;
  final int iconIndex;
  final int colorIndex;
  final bool isCustom;

  const HomeCategory({
    required this.id,
    required this.displayName,
    required this.iconIndex,
    required this.colorIndex,
    this.isCustom = false,
  });

  IconData get icon =>
      availableIcons[iconIndex.clamp(0, availableIcons.length - 1)];
  Color get color =>
      availableColors[colorIndex.clamp(0, availableColors.length - 1)];

  static final List<IconData> availableIcons = [
    Icons.chair_rounded, // 0
    Icons.water_drop_rounded, // 1
    Icons.local_fire_department_rounded, // 2
    Icons.bolt_rounded, // 3
    Icons.shopping_cart_rounded, // 4
    Icons.build_rounded, // 5
    Icons.kitchen_rounded, // 6
    Icons.home_rounded, // 7
    Icons.wifi_rounded, // 8
    Icons.cleaning_services_rounded, // 9
    Icons.category_rounded, // 10
    Icons.pets_rounded, // 11
    Icons.medical_services_rounded, // 12
    Icons.school_rounded, // 13
    Icons.sports_esports_rounded, // 14
    Icons.restaurant_rounded, // 15
    Icons.local_gas_station_rounded, // 16
    Icons.flight_rounded, // 17
    Icons.fitness_center_rounded, // 18
    Icons.child_care_rounded, // 19
    Icons.local_laundry_service_rounded, // 20
    Icons.park_rounded, // 21
    Icons.shopping_bag_rounded, // 22
    Icons.phone_android_rounded, // 23
    Icons.tv_rounded, // 24
  ];

  static final List<Color> availableColors = [
    Colors.brown, // 0
    Colors.blue, // 1
    Colors.orange, // 2
    Colors.amber, // 3
    Colors.green, // 4
    Colors.grey, // 5
    Colors.teal, // 6
    Colors.indigo, // 7
    Colors.purple, // 8
    Colors.cyan, // 9
    Colors.red, // 10
    Colors.pink, // 11
    Colors.lime, // 12
    Colors.deepPurple, // 13
    Colors.deepOrange, // 14
  ];

  // Default categories (order matches old enum for backward compat)
  static final furniture = HomeCategory(
      id: 'furniture', displayName: 'Furniture', iconIndex: 0, colorIndex: 0);
  static final water = HomeCategory(
      id: 'water', displayName: 'Water', iconIndex: 1, colorIndex: 1);
  static final gas =
      HomeCategory(id: 'gas', displayName: 'Gas', iconIndex: 2, colorIndex: 2);
  static final electricity = HomeCategory(
      id: 'electricity',
      displayName: 'Electricity',
      iconIndex: 3,
      colorIndex: 3);
  static final groceries = HomeCategory(
      id: 'groceries', displayName: 'Groceries', iconIndex: 4, colorIndex: 4);
  static final maintenance = HomeCategory(
      id: 'maintenance',
      displayName: 'Maintenance',
      iconIndex: 5,
      colorIndex: 5);
  static final appliances = HomeCategory(
      id: 'appliances',
      displayName: 'Appliances',
      iconIndex: 6,
      colorIndex: 6);
  static final rent = HomeCategory(
      id: 'rent', displayName: 'Rent', iconIndex: 7, colorIndex: 7);
  static final internet = HomeCategory(
      id: 'internet', displayName: 'Internet', iconIndex: 8, colorIndex: 8);
  static final cleaning = HomeCategory(
      id: 'cleaning', displayName: 'Cleaning', iconIndex: 9, colorIndex: 9);

  static final List<HomeCategory> defaults = [
    furniture,
    water,
    gas,
    electricity,
    groceries,
    maintenance,
    appliances,
    rent,
    internet,
    cleaning,
  ];

  static HomeCategory findById(
      String id, List<HomeCategory> customCategories) {
    for (final cat in defaults) {
      if (cat.id == id) return cat;
    }
    for (final cat in customCategories) {
      if (cat.id == id) return cat;
    }
    return HomeCategory(
        id: id,
        displayName: id,
        iconIndex: 10,
        colorIndex: 5,
        isCustom: true);
  }

  static HomeCategory fromLegacyIndex(int index) {
    if (index >= 0 && index < defaults.length) return defaults[index];
    return defaults[0];
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        'iconIndex': iconIndex,
        'colorIndex': colorIndex,
        'isCustom': isCustom,
      };

  factory HomeCategory.fromJson(Map<String, dynamic> json) => HomeCategory(
        id: json['id'] as String,
        displayName: json['displayName'] as String,
        iconIndex: json['iconIndex'] as int,
        colorIndex: json['colorIndex'] as int,
        isCustom: json['isCustom'] as bool? ?? false,
      );

  @override
  bool operator ==(Object other) => other is HomeCategory && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

class HomeRecord {
  final String id;
  final String title;
  final HomeCategory category;
  final double amount;
  final DateTime date;
  final String? description;
  final String? notes;

  const HomeRecord({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    this.description,
    this.notes,
  });

  HomeRecord copyWith({
    String? id,
    String? title,
    HomeCategory? category,
    double? amount,
    DateTime? date,
    String? description,
    String? notes,
  }) {
    return HomeRecord(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      description: description ?? this.description,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category.id,
      'amount': amount,
      'date': date.toIso8601String(),
      'description': description,
      'notes': notes,
    };
  }

  factory HomeRecord.fromJson(Map<String, dynamic> json,
      {List<HomeCategory> customCategories = const []}) {
    final categoryValue = json['category'];
    HomeCategory category;
    if (categoryValue is int) {
      category = HomeCategory.fromLegacyIndex(categoryValue);
    } else {
      category =
          HomeCategory.findById(categoryValue as String, customCategories);
    }

    return HomeRecord(
      id: json['id'] as String,
      title: json['title'] as String,
      category: category,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      description: json['description'] as String?,
      notes: json['notes'] as String?,
    );
  }
}
