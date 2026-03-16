import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FeatureItem {
  final String id;
  final String title;
  final IconData icon;
  final List<Color> gradient;
  bool visible;
  int order;

  FeatureItem({
    required this.id,
    required this.title,
    required this.icon,
    required this.gradient,
    this.visible = true,
    required this.order,
  });

  FeatureItem copyWith({bool? visible, int? order}) => FeatureItem(
        id: id,
        title: title,
        icon: icon,
        gradient: gradient,
        visible: visible ?? this.visible,
        order: order ?? this.order,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'visible': visible,
        'order': order,
      };
}

class DashboardSettingsState {
  final List<FeatureItem> features;

  const DashboardSettingsState({required this.features});

  List<FeatureItem> get visibleFeatures =>
      features.where((f) => f.visible).toList()
        ..sort((a, b) => a.order.compareTo(b.order));

  DashboardSettingsState copyWith({List<FeatureItem>? features}) =>
      DashboardSettingsState(features: features ?? this.features);
}

class DashboardSettingsCubit extends Cubit<DashboardSettingsState> {
  final String uid;
  final FirebaseFirestore _firestore;

  DashboardSettingsCubit({
    required this.uid,
    FirebaseFirestore? firestore,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        super(DashboardSettingsState(features: _defaultFeatures()));

  DocumentReference<Map<String, dynamic>> get _settingsDoc =>
      _firestore.collection('users').doc(uid).collection('settings').doc('dashboard');

  static List<FeatureItem> _defaultFeatures() => [
        FeatureItem(
          id: 'bills',
          title: 'Bills & Tasks',
          icon: Icons.receipt_long_rounded,
          gradient: [Colors.orange, Colors.deepOrange],
          order: 0,
        ),
        FeatureItem(
          id: 'vehicles',
          title: 'Vehicles',
          icon: Icons.directions_car_rounded,
          gradient: [Colors.blue, Colors.indigo],
          order: 1,
        ),
        FeatureItem(
          id: 'chits',
          title: 'Chit Funds',
          icon: Icons.group_work_rounded,
          gradient: [Colors.purple, Colors.deepPurple],
          order: 2,
        ),
        FeatureItem(
          id: 'checklists',
          title: 'Checklists',
          icon: Icons.checklist_rounded,
          gradient: [Colors.teal, Colors.green],
          order: 3,
        ),
        FeatureItem(
          id: 'periods',
          title: 'Period Tracker',
          icon: Icons.favorite_rounded,
          gradient: [Colors.pink, Colors.pink],
          order: 4,
        ),
        FeatureItem(
          id: 'home',
          title: 'Home Records',
          icon: Icons.home_rounded,
          gradient: [Colors.green, Colors.green],
          order: 5,
        ),
        FeatureItem(
          id: 'schedules',
          title: 'Schedules',
          icon: Icons.calendar_month_rounded,
          gradient: [Colors.cyan, Colors.blue],
          order: 6,
        ),
        FeatureItem(
          id: 'food_menu',
          title: 'Food Menu',
          icon: Icons.restaurant_menu_rounded,
          gradient: [Colors.deepOrange, Colors.red],
          order: 7,
        ),
        FeatureItem(
          id: 'loans',
          title: 'Loans',
          icon: Icons.account_balance_rounded,
          gradient: [Colors.blueGrey, Colors.indigo],
          order: 8,
        ),
        FeatureItem(
          id: 'goals',
          title: 'Goal Tracker',
          icon: Icons.track_changes_rounded,
          gradient: [Colors.teal, Colors.green],
          order: 9,
        ),
        FeatureItem(
          id: 'money_owe',
          title: 'Lend & Owe',
          icon: Icons.handshake_rounded,
          gradient: [Colors.amber, Colors.orange],
          order: 10,
        ),
      ];

  Future<void> load() async {
    final snap = await _settingsDoc.get();
    if (!snap.exists) return;

    final data = snap.data();
    if (data == null || data['features'] == null) return;

    final saved = (data['features'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    final features = List<FeatureItem>.from(state.features);

    for (final s in saved) {
      final idx = features.indexWhere((f) => f.id == s['id']);
      if (idx != -1) {
        features[idx] = features[idx].copyWith(
          visible: s['visible'] as bool? ?? true,
          order: s['order'] as int? ?? idx,
        );
      }
    }

    features.sort((a, b) => a.order.compareTo(b.order));
    emit(state.copyWith(features: features));
  }

  void toggleVisibility(String id) {
    final features = state.features.map((f) {
      if (f.id == id) return f.copyWith(visible: !f.visible);
      return f;
    }).toList();
    emit(state.copyWith(features: features));
    _save(features);
  }

  void reorder(int oldIndex, int newIndex) {
    final features = List<FeatureItem>.from(state.features);
    if (newIndex > oldIndex) newIndex--;
    final item = features.removeAt(oldIndex);
    features.insert(newIndex, item);
    for (int i = 0; i < features.length; i++) {
      features[i] = features[i].copyWith(order: i);
    }
    emit(state.copyWith(features: features));
    _save(features);
  }

  void _save(List<FeatureItem> features) {
    _settingsDoc.set({
      'features': features.map((f) => f.toJson()).toList(),
    });
  }
}
