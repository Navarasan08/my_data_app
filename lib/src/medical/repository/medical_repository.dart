import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_data_app/src/medical/model/medical_model.dart';

abstract class MedicalRepository {
  List<FamilyMember> getAllMembers();
  List<MedicalRecord> getAllRecords();
  void addMember(FamilyMember member);
  void updateMember(FamilyMember member);
  void deleteMember(String id);
  void addRecord(MedicalRecord record);
  void updateRecord(MedicalRecord record);
  void deleteRecord(String id);
  Future<void> init();
}

class FirestoreMedicalRepository implements MedicalRepository {
  final String uid;
  final FirebaseFirestore _firestore;
  List<FamilyMember> _members = [];
  List<MedicalRecord> _records = [];

  FirestoreMedicalRepository({
    required this.uid,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _membersCollection =>
      _firestore.collection('users').doc(uid).collection('family_members');

  CollectionReference<Map<String, dynamic>> get _recordsCollection =>
      _firestore.collection('users').doc(uid).collection('medical_records');

  @override
  Future<void> init() async {
    final memberSnapshot = await _membersCollection.get();
    _members = memberSnapshot.docs
        .map((doc) => FamilyMember.fromJson(doc.data()))
        .toList();
    final recordSnapshot = await _recordsCollection.get();
    _records = recordSnapshot.docs
        .map((doc) => MedicalRecord.fromJson(doc.data()))
        .toList();
  }

  @override
  List<FamilyMember> getAllMembers() => List.unmodifiable(_members);

  @override
  List<MedicalRecord> getAllRecords() => List.unmodifiable(_records);

  @override
  void addMember(FamilyMember member) {
    _members.add(member);
    _membersCollection.doc(member.id).set(member.toJson());
  }

  @override
  void updateMember(FamilyMember member) {
    final index = _members.indexWhere((m) => m.id == member.id);
    if (index != -1) {
      _members[index] = member;
      _membersCollection.doc(member.id).set(member.toJson());
    }
  }

  @override
  void deleteMember(String id) {
    _members.removeWhere((m) => m.id == id);
    _membersCollection.doc(id).delete();
  }

  @override
  void addRecord(MedicalRecord record) {
    _records.add(record);
    _recordsCollection.doc(record.id).set(record.toJson());
  }

  @override
  void updateRecord(MedicalRecord record) {
    final index = _records.indexWhere((r) => r.id == record.id);
    if (index != -1) {
      _records[index] = record;
      _recordsCollection.doc(record.id).set(record.toJson());
    }
  }

  @override
  void deleteRecord(String id) {
    _records.removeWhere((r) => r.id == id);
    _recordsCollection.doc(id).delete();
  }
}
