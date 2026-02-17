import 'package:flutter/material.dart';

enum HomeCategory {
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
}

extension HomeCategoryExtension on HomeCategory {
  String get displayName {
    switch (this) {
      case HomeCategory.furniture:
        return 'Furniture';
      case HomeCategory.water:
        return 'Water';
      case HomeCategory.gas:
        return 'Gas';
      case HomeCategory.electricity:
        return 'Electricity';
      case HomeCategory.groceries:
        return 'Groceries';
      case HomeCategory.maintenance:
        return 'Maintenance';
      case HomeCategory.appliances:
        return 'Appliances';
      case HomeCategory.rent:
        return 'Rent';
      case HomeCategory.internet:
        return 'Internet';
      case HomeCategory.cleaning:
        return 'Cleaning';
    }
  }

  IconData get icon {
    switch (this) {
      case HomeCategory.furniture:
        return Icons.chair_rounded;
      case HomeCategory.water:
        return Icons.water_drop_rounded;
      case HomeCategory.gas:
        return Icons.local_fire_department_rounded;
      case HomeCategory.electricity:
        return Icons.bolt_rounded;
      case HomeCategory.groceries:
        return Icons.shopping_cart_rounded;
      case HomeCategory.maintenance:
        return Icons.build_rounded;
      case HomeCategory.appliances:
        return Icons.kitchen_rounded;
      case HomeCategory.rent:
        return Icons.home_rounded;
      case HomeCategory.internet:
        return Icons.wifi_rounded;
      case HomeCategory.cleaning:
        return Icons.cleaning_services_rounded;
    }
  }

  Color get color {
    switch (this) {
      case HomeCategory.furniture:
        return Colors.brown;
      case HomeCategory.water:
        return Colors.blue;
      case HomeCategory.gas:
        return Colors.orange;
      case HomeCategory.electricity:
        return Colors.amber;
      case HomeCategory.groceries:
        return Colors.green;
      case HomeCategory.maintenance:
        return Colors.grey;
      case HomeCategory.appliances:
        return Colors.teal;
      case HomeCategory.rent:
        return Colors.indigo;
      case HomeCategory.internet:
        return Colors.purple;
      case HomeCategory.cleaning:
        return Colors.cyan;
    }
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
      'category': category.index,
      'amount': amount,
      'date': date.toIso8601String(),
      'description': description,
      'notes': notes,
    };
  }

  factory HomeRecord.fromJson(Map<String, dynamic> json) {
    return HomeRecord(
      id: json['id'] as String,
      title: json['title'] as String,
      category: HomeCategory.values[json['category'] as int],
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      description: json['description'] as String?,
      notes: json['notes'] as String?,
    );
  }
}
