import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_data_app/src/core/sync/firestore_list_store.dart';
import 'package:my_data_app/src/core/sync/sync_node.dart';
import 'package:my_data_app/src/medical/model/medical_model.dart';

abstract class MedicalRepository implements SyncNode {
  List<FamilyMember> getAllMembers();
  List<MedicalRecord> getAllRecords();
  void addMember(FamilyMember member);
  void updateMember(FamilyMember member);
  void deleteMember(String id);
  void addRecord(MedicalRecord record);
  void updateRecord(MedicalRecord record);
  void deleteRecord(String id);
}

/// Realtime Firestore implementation over the family-members and
/// medical-records collections.
class FirestoreMedicalRepository extends CompositeSyncNode
    implements MedicalRepository {
  final String uid;
  final FirestoreListStore<FamilyMember> _members;
  final FirestoreListStore<MedicalRecord> _records;

  factory FirestoreMedicalRepository({
    required String uid,
    FirebaseFirestore? firestore,
  }) {
    final user = (firestore ?? FirebaseFirestore.instance)
        .collection('users')
        .doc(uid);
    return FirestoreMedicalRepository._(
      uid,
      FirestoreListStore<FamilyMember>(
        collection: user.collection('family_members'),
        fromDoc: (json, _) => FamilyMember.fromJson(json),
        toJson: (m) => m.toJson(),
        idOf: (m) => m.id,
        debugLabel: 'family_members',
      ),
      FirestoreListStore<MedicalRecord>(
        collection: user.collection('medical_records'),
        fromDoc: (json, _) => MedicalRecord.fromJson(json),
        toJson: (r) => r.toJson(),
        idOf: (r) => r.id,
        debugLabel: 'medical_records',
      ),
    );
  }

  FirestoreMedicalRepository._(this.uid, this._members, this._records)
    : super([_members, _records]);

  @override
  List<FamilyMember> getAllMembers() => _members.items;

  @override
  List<MedicalRecord> getAllRecords() => _records.items;

  @override
  void addMember(FamilyMember member) => _members.save(member);

  @override
  void updateMember(FamilyMember member) => _members.save(member);

  @override
  void deleteMember(String id) => _members.remove(id);

  @override
  void addRecord(MedicalRecord record) => _records.save(record);

  @override
  void updateRecord(MedicalRecord record) => _records.save(record);

  @override
  void deleteRecord(String id) => _records.remove(id);
}
