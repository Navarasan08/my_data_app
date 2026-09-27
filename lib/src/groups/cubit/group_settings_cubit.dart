import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_data_app/src/core/sync/firestore_document_source.dart';
import 'package:my_data_app/src/core/sync/sync_node.dart';

/// Per-user UI preferences for the Groups feature. Persisted to
/// `users/{uid}/settings/groups` (same pattern as DashboardSettingsCubit) —
/// preferences sync across the user's devices but are private to the user
/// even when they belong to shared groups.
class GroupSettingsState {
  /// When true, the Expenses tab renders month headers with per-month
  /// subtotals instead of a flat date-sorted list.
  final bool monthwiseListView;

  const GroupSettingsState({this.monthwiseListView = false});

  GroupSettingsState copyWith({bool? monthwiseListView}) => GroupSettingsState(
    monthwiseListView: monthwiseListView ?? this.monthwiseListView,
  );

  Map<String, dynamic> toJson() => {'monthwiseListView': monthwiseListView};

  factory GroupSettingsState.fromJson(Map<String, dynamic> json) =>
      GroupSettingsState(
        monthwiseListView: json['monthwiseListView'] as bool? ?? false,
      );
}

class GroupSettingsCubit extends Cubit<GroupSettingsState> {
  final String uid;
  final FirebaseFirestore _firestore;
  late final FirestoreDocumentSource<GroupSettingsState> _source;
  StreamSubscription<void>? _sub;

  GroupSettingsCubit({required this.uid, FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      super(const GroupSettingsState()) {
    _source = FirestoreDocumentSource<GroupSettingsState>(
      ref: _doc,
      fromDoc: (json) => json == null
          ? const GroupSettingsState()
          : GroupSettingsState.fromJson(json),
      initial: const GroupSettingsState(),
      debugLabel: 'group_settings',
    );
    _sub = _source.stream.listen((snap) => emit(snap.data));
  }

  DocumentReference<Map<String, dynamic>> get _doc => _firestore
      .collection('users')
      .doc(uid)
      .collection('settings')
      .doc('groups');

  /// Attaches the realtime listener. Idempotent.
  void start() => _source.start();

  @override
  Future<void> close() async {
    await _sub?.cancel();
    await _source.dispose();
    return super.close();
  }

  void setMonthwiseListView(bool enabled) {
    final next = state.copyWith(monthwiseListView: enabled);
    emit(next);
    fireAndForget(
      _doc.set(next.toJson(), SetOptions(merge: true)),
      label: 'group_settings',
    );
  }
}
