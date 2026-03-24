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
    Icons.chair_rounded, // 0 - furniture
    Icons.water_drop_rounded, // 1 - water
    Icons.local_fire_department_rounded, // 2 - gas
    Icons.bolt_rounded, // 3 - electricity
    Icons.shopping_cart_rounded, // 4 - groceries
    Icons.build_rounded, // 5 - maintenance
    Icons.kitchen_rounded, // 6 - appliances
    Icons.home_rounded, // 7 - rent/home
    Icons.wifi_rounded, // 8 - internet
    Icons.cleaning_services_rounded, // 9 - cleaning
    Icons.category_rounded, // 10 - general
    Icons.pets_rounded, // 11 - pets
    Icons.medical_services_rounded, // 12 - medical
    Icons.school_rounded, // 13 - education
    Icons.sports_esports_rounded, // 14 - entertainment
    Icons.restaurant_rounded, // 15 - food/dining
    Icons.local_gas_station_rounded, // 16 - fuel
    Icons.flight_rounded, // 17 - travel
    Icons.fitness_center_rounded, // 18 - fitness
    Icons.child_care_rounded, // 19 - childcare
    Icons.local_laundry_service_rounded, // 20 - laundry
    Icons.park_rounded, // 21 - garden
    Icons.shopping_bag_rounded, // 22 - shopping
    Icons.phone_android_rounded, // 23 - phone/mobile
    Icons.tv_rounded, // 24 - tv/cable
    Icons.local_drink_rounded, // 25 - milk/drinks
    Icons.rice_bowl_rounded, // 26 - rice/grains
    Icons.egg_rounded, // 27 - eggs/dairy
    Icons.spa_rounded, // 28 - beauty/spa
    Icons.directions_car_rounded, // 29 - vehicle
    Icons.local_pharmacy_rounded, // 30 - pharmacy
    Icons.cake_rounded, // 31 - bakery/snacks
    Icons.coffee_rounded, // 32 - coffee/tea
    Icons.local_grocery_store_rounded, // 33 - supermarket
    Icons.grass_rounded, // 34 - vegetables
    Icons.set_meal_rounded, // 35 - fish/meat
    Icons.blender_rounded, // 36 - batter/mixer
    Icons.newspaper_rounded, // 37 - newspaper
    Icons.checkroom_rounded, // 38 - clothing
    Icons.celebration_rounded, // 39 - festivals
    Icons.card_giftcard_rounded, // 40 - gifts
    Icons.savings_rounded, // 41 - savings
    Icons.account_balance_rounded, // 42 - bank/emi
    Icons.subscriptions_rounded, // 43 - subscriptions
    Icons.local_taxi_rounded, // 44 - taxi/auto
    Icons.temple_hindu_rounded, // 45 - temple/pooja
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
  static final milk = HomeCategory(
      id: 'milk', displayName: 'Milk', iconIndex: 25, colorIndex: 1);
  static final rice = HomeCategory(
      id: 'rice', displayName: 'Rice & Grains', iconIndex: 26, colorIndex: 0);
  static final batter = HomeCategory(
      id: 'batter', displayName: 'Batter', iconIndex: 36, colorIndex: 2);
  static final vegetables = HomeCategory(
      id: 'vegetables', displayName: 'Vegetables', iconIndex: 34, colorIndex: 4);
  static final fish = HomeCategory(
      id: 'fish', displayName: 'Fish & Meat', iconIndex: 35, colorIndex: 10);
  static final medical = HomeCategory(
      id: 'medical', displayName: 'Medical', iconIndex: 12, colorIndex: 10);
  static final education = HomeCategory(
      id: 'education', displayName: 'Education', iconIndex: 13, colorIndex: 13);
  static final clothing = HomeCategory(
      id: 'clothing', displayName: 'Clothing', iconIndex: 38, colorIndex: 8);
  static final pooja = HomeCategory(
      id: 'pooja', displayName: 'Pooja & Temple', iconIndex: 45, colorIndex: 14);
  static final emi = HomeCategory(
      id: 'emi', displayName: 'EMI & Loans', iconIndex: 42, colorIndex: 7);
  static final subscriptions = HomeCategory(
      id: 'subscriptions', displayName: 'Subscriptions', iconIndex: 43, colorIndex: 11);

  static final List<HomeCategory> defaults = [
    groceries,
    milk,
    vegetables,
    rice,
    batter,
    fish,
    water,
    gas,
    electricity,
    rent,
    internet,
    maintenance,
    appliances,
    furniture,
    cleaning,
    medical,
    education,
    clothing,
    pooja,
    emi,
    subscriptions,
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

enum MeasureUnit {
  kg('kg'),
  gram('g'),
  litre('L'),
  ml('ml'),
  piece('pcs'),
  packet('pkt'),
  dozen('doz'),
  bundle('bundle'),
  box('box'),
  bottle('bottle'),
  can('can'),
  bag('bag');

  final String label;
  const MeasureUnit(this.label);

  static MeasureUnit fromName(String? name) {
    if (name == null) return MeasureUnit.piece;
    return MeasureUnit.values.firstWhere(
      (u) => u.name == name,
      orElse: () => MeasureUnit.piece,
    );
  }
}

class HomeRecord {
  final String id;
  final String title;
  final HomeCategory category;
  final double amount;
  final DateTime date;
  final String? description;
  final String? notes;
  final double? quantity;
  final MeasureUnit? unit;

  const HomeRecord({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    this.description,
    this.notes,
    this.quantity,
    this.unit,
  });

  String get quantityLabel {
    if (quantity == null || unit == null) return '';
    final qStr = quantity! % 1 == 0
        ? quantity!.toInt().toString()
        : quantity!.toStringAsFixed(2);
    return '$qStr ${unit!.label}';
  }

  HomeRecord copyWith({
    String? id,
    String? title,
    HomeCategory? category,
    double? amount,
    DateTime? date,
    String? description,
    String? notes,
    double? quantity,
    MeasureUnit? unit,
    bool clearQuantity = false,
  }) {
    return HomeRecord(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      quantity: clearQuantity ? null : (quantity ?? this.quantity),
      unit: clearQuantity ? null : (unit ?? this.unit),
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
      if (quantity != null) 'quantity': quantity,
      if (unit != null) 'unit': unit!.name,
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
      quantity: (json['quantity'] as num?)?.toDouble(),
      unit: json['unit'] != null
          ? MeasureUnit.fromName(json['unit'] as String)
          : null,
    );
  }
}
