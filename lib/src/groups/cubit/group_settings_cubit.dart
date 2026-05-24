import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Per-user UI preferences for the Groups feature. Persisted to
/// `users/{uid}/settings/groups` (same pattern as DashboardSettingsCubit) —
/// preferences sync across the user's devices but are private to the user
/// even when they belong to shared groups.
class GroupSettingsState {
  /// When true, the Expenses tab renders month headers with per-month
  /// subtotals instead of a flat date-sorted list.
  final bool monthwiseListView;

  const GroupSettingsState({
    this.monthwiseListView = false,
  });

  GroupSettingsState copyWith({bool? monthwiseListView}) =>
      GroupSettingsState(
        monthwiseListView: monthwiseListView ?? this.monthwiseListView,
      );

  Map<String, dynamic> toJson() => {
        'monthwiseListView': monthwiseListView,
      };

  factory GroupSettingsState.fromJson(Map<String, dynamic> json) =>
      GroupSettingsState(
        monthwiseListView: json['monthwiseListView'] as bool? ?? false,
      );
}

class GroupSettingsCubit extends Cubit<GroupSettingsState> {
  final String uid;
  final FirebaseFirestore _firestore;

  GroupSettingsCubit({
    required this.uid,
    FirebaseFirestore? firestore,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        super(const GroupSettingsState());

  DocumentReference<Map<String, dynamic>> get _doc => _firestore
      .collection('users')
      .doc(uid)
      .collection('settings')
      .doc('groups');

  Future<void> load() async {
    final snap = await _doc.get();
    final data = snap.data();
    if (data != null) emit(GroupSettingsState.fromJson(data));
  }

  Future<void> setMonthwiseListView(bool enabled) async {
    emit(state.copyWith(monthwiseListView: enabled));
    await _doc.set(state.toJson(), SetOptions(merge: true));
  }
}
