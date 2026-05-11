import 'package:flutter/material.dart';

/// A food / drink item the user wants to track. Each item carries optional
/// metadata so the consumption page can render it nicely:
///   * [iconIndex] / [colorIndex] map to fixed lookup tables on this class
///     (same pattern used by `HomeCategory` and `PaymentType`).
///   * [unitLabel] is what each "1 quantity" represents — `null` means
///     "count" (so a quantity of 3 reads as "3 times").
///   * [monthlyLimit] drives the "X left" indicator on the list. `null`
///     means no limit — the item just shows the consumed count.
class FoodItem {
  final String id;
  final String name;
  final int iconIndex;
  final int colorIndex;
  final String? unitLabel;
  final double? monthlyLimit;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FoodItem({
    required this.id,
    required this.name,
    required this.iconIndex,
    required this.colorIndex,
    this.unitLabel,
    this.monthlyLimit,
    required this.createdAt,
    required this.updatedAt,
  });

  IconData get icon =>
      availableIcons[iconIndex.clamp(0, availableIcons.length - 1)];
  Color get color =>
      availableColors[colorIndex.clamp(0, availableColors.length - 1)];

  /// How a quantity reads ("3 cups" vs "3 times"). Used by the list and
  /// analysis labels.
  String quantityLabel(double q) {
    final qStr = q % 1 == 0 ? q.toInt().toString() : q.toStringAsFixed(1);
    if (unitLabel == null || unitLabel!.isEmpty) {
      return '$qStr ${q == 1 ? 'time' : 'times'}';
    }
    return '$qStr ${unitLabel!}';
  }

  // IMPORTANT: existing records store an `iconIndex` into this list — only
  // append new entries at the end; never reorder.
  static final List<IconData> availableIcons = [
    Icons.local_cafe_rounded,             // 0 coffee/tea
    Icons.local_drink_rounded,            // 1 drink
    Icons.water_drop_rounded,             // 2 water
    Icons.fastfood_rounded,               // 3 fast food
    Icons.lunch_dining_rounded,           // 4 lunch
    Icons.dinner_dining_rounded,          // 5 dinner
    Icons.breakfast_dining_rounded,       // 6 breakfast
    Icons.ramen_dining_rounded,           // 7 noodles
    Icons.local_pizza_rounded,            // 8 pizza
    Icons.cake_rounded,                   // 9 cake / dessert
    Icons.icecream_rounded,               // 10 ice cream
    Icons.cookie_rounded,                 // 11 cookie / snack
    Icons.egg_rounded,                    // 12 egg
    Icons.set_meal_rounded,               // 13 meal / fish
    Icons.kebab_dining_rounded,           // 14 kebab / meat
    Icons.rice_bowl_rounded,              // 15 rice bowl
    Icons.bakery_dining_rounded,          // 16 bakery
    Icons.brunch_dining_rounded,          // 17 brunch
    Icons.local_bar_rounded,              // 18 cocktail
    Icons.wine_bar_rounded,               // 19 wine
    Icons.sports_bar_rounded,             // 20 beer
    Icons.emoji_food_beverage_rounded,    // 21 hot drink
    Icons.local_dining_rounded,           // 22 cutlery
    Icons.restaurant_rounded,             // 23 dining
    Icons.coffee_rounded,                 // 24 coffee cup
    Icons.coffee_maker_rounded,           // 25 coffee machine
    Icons.free_breakfast_rounded,         // 26 breakfast cup
    Icons.liquor_rounded,                 // 27 spirits / bottle
    Icons.bento_rounded,                  // 28 bento box
    Icons.dining_rounded,                 // 29 plate & cutlery
    Icons.restaurant_menu_rounded,        // 30 menu
    Icons.food_bank_rounded,              // 31 food bank
    Icons.takeout_dining_rounded,         // 32 takeout
    Icons.tapas_rounded,                  // 33 tapas
    Icons.kitchen_rounded,                // 34 fridge
    Icons.microwave_rounded,              // 35 microwave
    Icons.blender_rounded,                // 36 blender / juice
    Icons.outdoor_grill_rounded,          // 37 grill / bbq
    Icons.no_food_rounded,                // 38 skip food
    Icons.no_drinks_rounded,              // 39 skip drink
    Icons.no_meals_rounded,               // 40 fasting
    Icons.spa_rounded,                    // 41 wellness
    Icons.eco_rounded,                    // 42 organic / leaf
    Icons.grass_rounded,                  // 43 greens / herbs
    Icons.local_florist_rounded,          // 44 flower / petal
    Icons.agriculture_rounded,            // 45 farm produce
    Icons.medication_rounded,             // 46 pills / supplement
    Icons.medication_liquid_rounded,      // 47 syrup
    Icons.vaccines_rounded,               // 48 injection
    Icons.healing_rounded,                // 49 plaster / heal
    Icons.monitor_heart_rounded,          // 50 heart rate
    Icons.fitness_center_rounded,         // 51 gym / workout
    Icons.directions_run_rounded,         // 52 running
    Icons.directions_walk_rounded,        // 53 walking
    Icons.directions_bike_rounded,        // 54 cycling
    Icons.pool_rounded,                   // 55 swimming
    Icons.self_improvement_rounded,       // 56 meditation / yoga
    Icons.bedtime_rounded,                // 57 sleep
    Icons.smoking_rooms_rounded,          // 58 smoking
    Icons.smoke_free_rounded,             // 59 quit smoking
    Icons.opacity_rounded,                // 60 hydration drop
    Icons.bubble_chart_rounded,           // 61 candy / sweets
    Icons.energy_savings_leaf_rounded,    // 62 vegetarian / energy
    Icons.spa_outlined,                   // 63 light wellness
    Icons.local_pharmacy_rounded,         // 64 pharmacy
    Icons.psychology_rounded,             // 65 mental / mood
    Icons.favorite_rounded,               // 66 love / treat
    Icons.savings_rounded,                // 67 saving (cheat day)
    Icons.celebration_rounded,            // 68 indulgence / treat
    Icons.warning_amber_rounded,          // 69 caution / cheat
    Icons.local_grocery_store_rounded,    // 70 grocery
    Icons.shopping_basket_rounded,        // 71 basket
    Icons.scale_rounded,                  // 72 weight / portion
  ];

  static final List<Color> availableColors = [
    Colors.brown,
    Colors.green,
    Colors.blue,
    Colors.orange,
    Colors.red,
    Colors.amber,
    Colors.teal,
    Colors.purple,
    Colors.pink,
    Colors.indigo,
    Colors.cyan,
    Colors.deepOrange,
    Colors.lime,
    Colors.deepPurple,
  ];

  FoodItem copyWith({
    String? name,
    int? iconIndex,
    int? colorIndex,
    String? unitLabel,
    bool clearUnitLabel = false,
    double? monthlyLimit,
    bool clearMonthlyLimit = false,
    DateTime? updatedAt,
  }) =>
      FoodItem(
        id: id,
        name: name ?? this.name,
        iconIndex: iconIndex ?? this.iconIndex,
        colorIndex: colorIndex ?? this.colorIndex,
        unitLabel: clearUnitLabel ? null : (unitLabel ?? this.unitLabel),
        monthlyLimit:
            clearMonthlyLimit ? null : (monthlyLimit ?? this.monthlyLimit),
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'iconIndex': iconIndex,
        'colorIndex': colorIndex,
        'unitLabel': unitLabel,
        'monthlyLimit': monthlyLimit,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory FoodItem.fromJson(Map<String, dynamic> json) => FoodItem(
        id: json['id'] as String,
        name: json['name'] as String,
        iconIndex: (json['iconIndex'] as int? ?? 0),
        colorIndex: (json['colorIndex'] as int? ?? 0),
        unitLabel: json['unitLabel'] as String?,
        monthlyLimit: (json['monthlyLimit'] as num?)?.toDouble(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}

/// A single eating event — links to a [FoodItem] and records the quantity.
class FoodEntry {
  final String id;
  final String foodItemId;
  final double quantity;
  final DateTime date;
  final String? description;
  final DateTime createdAt;

  const FoodEntry({
    required this.id,
    required this.foodItemId,
    required this.quantity,
    required this.date,
    this.description,
    required this.createdAt,
  });

  FoodEntry copyWith({
    String? foodItemId,
    double? quantity,
    DateTime? date,
    String? description,
    bool clearDescription = false,
  }) =>
      FoodEntry(
        id: id,
        foodItemId: foodItemId ?? this.foodItemId,
        quantity: quantity ?? this.quantity,
        date: date ?? this.date,
        description:
            clearDescription ? null : (description ?? this.description),
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'foodItemId': foodItemId,
        'quantity': quantity,
        'date': date.toIso8601String(),
        'description': description,
        'createdAt': createdAt.toIso8601String(),
      };

  factory FoodEntry.fromJson(Map<String, dynamic> json) => FoodEntry(
        id: json['id'] as String,
        foodItemId: json['foodItemId'] as String,
        quantity: (json['quantity'] as num).toDouble(),
        date: DateTime.parse(json['date'] as String),
        description: json['description'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
