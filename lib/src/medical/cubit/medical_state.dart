import 'package:my_data_app/src/medical/model/medical_model.dart';

class MedicalState {
  final List<FamilyMember> members;
  final List<MedicalRecord> records;

  const MedicalState({
    required this.members,
    required this.records,
  });

  MedicalState copyWith({
    List<FamilyMember>? members,
    List<MedicalRecord>? records,
  }) => MedicalState(
    members: members ?? this.members,
    records: records ?? this.records,
  );
}
