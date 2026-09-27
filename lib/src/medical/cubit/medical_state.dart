import 'package:my_data_app/src/core/sync/sync_snapshot.dart';
import 'package:my_data_app/src/medical/model/medical_model.dart';

class MedicalState {
  final List<FamilyMember> members;
  final List<MedicalRecord> records;

  /// Where the lists came from: `loading` before the first snapshot,
  /// `cached` until the server confirms, `live` after.
  final SyncStatus syncStatus;

  const MedicalState({
    required this.members,
    required this.records,
    this.syncStatus = SyncStatus.loading,
  });

  bool get isLive => syncStatus.isLive;

  MedicalState copyWith({
    List<FamilyMember>? members,
    List<MedicalRecord>? records,
    SyncStatus? syncStatus,
  }) => MedicalState(
    members: members ?? this.members,
    records: records ?? this.records,
    syncStatus: syncStatus ?? this.syncStatus,
  );
}
