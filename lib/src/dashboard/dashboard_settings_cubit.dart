import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_data_app/src/core/sync/firestore_document_source.dart';
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

/// The four bottom tabs, by role rather than index.
enum ShellTab {
  notes('Quick Notes'),
  module('Second tab module'),
  dashboard('Dashboard'),
  groups('Groups');

  final String label;
  const ShellTab(this.label);

  static ShellTab fromName(String? name) => ShellTab.values.firstWhere(
    (t) => t.name == name,
    orElse: () => ShellTab.dashboard,
  );
}

class DashboardSettingsState {
  final List<FeatureItem> features;
  final bool isGridView;

  /// Feature id shown on the second bottom tab. Monthly Stats by default.
  final String secondTabFeatureId;

  /// Which tab the app opens on.
  final ShellTab landingTab;

  /// Monthly Stats ledger lines the user has switched off, by item id
  /// ('salary', 'bills', …). Hidden lines are left out of the tally too.
  final Set<String> hiddenMonthlyStatItems;

  /// Whether Monthly Stats keeps lines with a zero amount on the board.
  final bool showZeroMonthlyStatItems;

  const DashboardSettingsState({
    required this.features,
    this.isGridView = true,
    this.secondTabFeatureId = 'monthly_stats',
    this.landingTab = ShellTab.dashboard,
    this.hiddenMonthlyStatItems = const {},
    this.showZeroMonthlyStatItems = true,
  });

  FeatureItem? featureById(String id) {
    for (final f in features) {
      if (f.id == id) return f;
    }
    return null;
  }

  List<FeatureItem> get visibleFeatures =>
      features.where((f) => f.visible).toList()
        ..sort((a, b) => a.order.compareTo(b.order));

  DashboardSettingsState copyWith({
    List<FeatureItem>? features,
    bool? isGridView,
    String? secondTabFeatureId,
    ShellTab? landingTab,
    Set<String>? hiddenMonthlyStatItems,
    bool? showZeroMonthlyStatItems,
  }) => DashboardSettingsState(
    features: features ?? this.features,
    isGridView: isGridView ?? this.isGridView,
    secondTabFeatureId: secondTabFeatureId ?? this.secondTabFeatureId,
    landingTab: landingTab ?? this.landingTab,
    hiddenMonthlyStatItems:
        hiddenMonthlyStatItems ?? this.hiddenMonthlyStatItems,
    showZeroMonthlyStatItems:
        showZeroMonthlyStatItems ?? this.showZeroMonthlyStatItems,
  );
}

class DashboardSettingsCubit extends Cubit<DashboardSettingsState> {
  final String uid;
  final FirebaseFirestore _firestore;
  late final FirestoreDocumentSource<Map<String, dynamic>?> _source;
  StreamSubscription<void>? _sub;

  DashboardSettingsCubit({required this.uid, FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      super(DashboardSettingsState(features: _defaultFeatures())) {
    _source = FirestoreDocumentSource<Map<String, dynamic>?>(
      ref: _settingsDoc,
      fromDoc: (json) => json,
      initial: null,
      debugLabel: 'dashboard_settings',
    );
    _sub = _source.stream.listen((snap) => _apply(snap.data));
  }

  DocumentReference<Map<String, dynamic>> get _settingsDoc => _firestore
      .collection('users')
      .doc(uid)
      .collection('settings')
      .doc('dashboard');

  /// Attaches the realtime listener: the cached layout applies at once and
  /// changes made on another device follow. Idempotent.
  void start() => _source.start();

  @override
  Future<void> close() async {
    await _sub?.cancel();
    await _source.dispose();
    return super.close();
  }

  static List<FeatureItem> _defaultFeatures() => [
    FeatureItem(
      id: 'monthly_stats',
      title: 'Monthly Stats',
      icon: Icons.query_stats_rounded,
      gradient: [Colors.teal, Colors.green],
      order: 0,
    ),
    FeatureItem(
      id: 'bills',
      title: 'Bills',
      icon: Icons.receipt_long_rounded,
      gradient: [Colors.orange, Colors.deepOrange],
      order: 1,
    ),
    FeatureItem(
      id: 'vehicles',
      title: 'Vehicles',
      icon: Icons.directions_car_rounded,
      gradient: [Colors.blue, Colors.indigo],
      order: 2,
    ),
    FeatureItem(
      id: 'chits',
      title: 'Chit Funds',
      icon: Icons.group_work_rounded,
      gradient: [Colors.purple, Colors.deepPurple],
      order: 3,
    ),
    FeatureItem(
      id: 'checklists',
      title: 'Checklists',
      icon: Icons.checklist_rounded,
      gradient: [Colors.teal, Colors.green],
      order: 4,
    ),
    FeatureItem(
      id: 'periods',
      title: 'Period Tracker',
      icon: Icons.favorite_rounded,
      gradient: [Colors.pink, Colors.pink],
      order: 5,
    ),
    FeatureItem(
      id: 'home',
      title: 'Expense Tracker',
      icon: Icons.account_balance_wallet_rounded,
      gradient: [Colors.green, Colors.green],
      order: 6,
    ),
    FeatureItem(
      id: 'schedules',
      title: 'Schedules',
      icon: Icons.calendar_month_rounded,
      gradient: [Colors.cyan, Colors.blue],
      order: 7,
    ),
    FeatureItem(
      id: 'food_menu',
      title: 'Food Menu',
      icon: Icons.restaurant_menu_rounded,
      gradient: [Colors.deepOrange, Colors.red],
      order: 8,
    ),
    FeatureItem(
      id: 'loans',
      title: 'Loans',
      icon: Icons.account_balance_rounded,
      gradient: [Colors.blueGrey, Colors.indigo],
      order: 9,
    ),
    FeatureItem(
      id: 'goals',
      title: 'Goal Tracker',
      icon: Icons.track_changes_rounded,
      gradient: [Colors.teal, Colors.green],
      order: 10,
    ),
    FeatureItem(
      id: 'money_owe',
      title: 'Lend & Owe',
      icon: Icons.handshake_rounded,
      gradient: [Colors.amber, Colors.orange],
      order: 11,
    ),
    FeatureItem(
      id: 'medical',
      title: 'Medical',
      icon: Icons.medical_services_rounded,
      gradient: [Colors.red, Colors.pink],
      order: 12,
    ),
    FeatureItem(
      id: 'vault',
      title: 'Profile Vault',
      icon: Icons.folder_special_rounded,
      gradient: [Colors.indigo, Colors.deepPurple],
      order: 13,
    ),
    FeatureItem(
      id: 'land',
      title: 'My Lands',
      icon: Icons.landscape_rounded,
      gradient: [Colors.green, Colors.brown],
      order: 14,
    ),
    FeatureItem(
      id: 'interest',
      title: 'Interest',
      icon: Icons.percent_rounded,
      gradient: [Colors.amber, Colors.orange],
      order: 15,
    ),
    FeatureItem(
      id: 'activities',
      title: 'Activity Log',
      icon: Icons.history_rounded,
      gradient: [Colors.blue, Colors.indigo],
      order: 16,
    ),
    FeatureItem(
      id: 'diet',
      title: 'Diet Tracker',
      icon: Icons.restaurant_menu_rounded,
      gradient: [Colors.green, Colors.teal],
      order: 17,
    ),
    FeatureItem(
      id: 'days_counter',
      title: 'Days Counter',
      icon: Icons.hourglass_top_rounded,
      gradient: [Colors.pink, Colors.deepPurple],
      order: 18,
    ),
    FeatureItem(
      id: 'pregnancy',
      title: 'Pregnancy Assist',
      icon: Icons.pregnant_woman_rounded,
      gradient: [Colors.pink, Colors.purple],
      order: 19,
    ),
  ];

  void _apply(Map<String, dynamic>? data) {
    if (data == null) return;

    final features = List<FeatureItem>.from(state.features);
    if (data['features'] != null) {
      final saved = (data['features'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
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
    }

    final isGridView = data['isGridView'] as bool? ?? state.isGridView;
    emit(
      state.copyWith(
        features: features,
        isGridView: isGridView,
        secondTabFeatureId:
            data['secondTabFeatureId'] as String? ?? state.secondTabFeatureId,
        landingTab: data['landingTab'] == null
            ? state.landingTab
            : ShellTab.fromName(data['landingTab'] as String?),
        hiddenMonthlyStatItems: data['hiddenMonthlyStatItems'] == null
            ? state.hiddenMonthlyStatItems
            : (data['hiddenMonthlyStatItems'] as List<dynamic>)
                  .cast<String>()
                  .toSet(),
        showZeroMonthlyStatItems:
            data['showZeroMonthlyStatItems'] as bool? ??
            state.showZeroMonthlyStatItems,
      ),
    );
  }

  void toggleMonthlyStatItem(String id) {
    final hidden = Set<String>.from(state.hiddenMonthlyStatItems);
    if (!hidden.remove(id)) hidden.add(id);
    emit(state.copyWith(hiddenMonthlyStatItems: hidden));
    _settingsDoc.set({
      'hiddenMonthlyStatItems': hidden.toList(),
    }, SetOptions(merge: true));
  }

  void setShowZeroMonthlyStatItems(bool value) {
    emit(state.copyWith(showZeroMonthlyStatItems: value));
    _settingsDoc.set({
      'showZeroMonthlyStatItems': value,
    }, SetOptions(merge: true));
  }

  void setSecondTab(String featureId) {
    emit(state.copyWith(secondTabFeatureId: featureId));
    _settingsDoc.set({
      'secondTabFeatureId': featureId,
    }, SetOptions(merge: true));
  }

  void setLandingTab(ShellTab tab) {
    emit(state.copyWith(landingTab: tab));
    _settingsDoc.set({'landingTab': tab.name}, SetOptions(merge: true));
  }

  void toggleViewMode() {
    final next = !state.isGridView;
    emit(state.copyWith(isGridView: next));
    _settingsDoc.set({'isGridView': next}, SetOptions(merge: true));
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
    }, SetOptions(merge: true));
  }
}
