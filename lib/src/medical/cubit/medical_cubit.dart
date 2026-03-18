import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_data_app/src/medical/model/medical_model.dart';
import 'package:my_data_app/src/medical/repository/medical_repository.dart';
import 'package:my_data_app/src/medical/cubit/medical_state.dart';

class MedicalCubit extends Cubit<MedicalState> {
  final MedicalRepository _repository;

  MedicalCubit(this._repository)
      : super(MedicalState(
          members: _repository.getAllMembers(),
          records: _repository.getAllRecords(),
        ));

  // ── Members ──────────────────────────────────────────────────────────

  void addMember(FamilyMember member) {
    _repository.addMember(member);
    emit(state.copyWith(members: _repository.getAllMembers()));
  }

  void updateMember(FamilyMember member) {
    _repository.updateMember(member);
    emit(state.copyWith(members: _repository.getAllMembers()));
  }

  void deleteMember(String id) {
    // Also delete all records for this member
    final memberRecords = state.records.where((r) => r.memberId == id).toList();
    for (final r in memberRecords) {
      _repository.deleteRecord(r.id);
    }
    _repository.deleteMember(id);
    emit(state.copyWith(
      members: _repository.getAllMembers(),
      records: _repository.getAllRecords(),
    ));
  }

  FamilyMember? getMemberById(String id) {
    final matches = state.members.where((m) => m.id == id);
    return matches.isNotEmpty ? matches.first : null;
  }

  // ── Records ──────────────────────────────────────────────────────────

  void addRecord(MedicalRecord record) {
    _repository.addRecord(record);
    emit(state.copyWith(records: _repository.getAllRecords()));
  }

  void updateRecord(MedicalRecord record) {
    _repository.updateRecord(record);
    emit(state.copyWith(records: _repository.getAllRecords()));
  }

  void deleteRecord(String id) {
    _repository.deleteRecord(id);
    emit(state.copyWith(records: _repository.getAllRecords()));
  }

  // ── Queries ──────────────────────────────────────────────────────────

  List<MedicalRecord> recordsForMember(String memberId) =>
      state.records.where((r) => r.memberId == memberId).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  List<MedicalRecord> recordsByType(RecordType type) =>
      state.records.where((r) => r.type == type).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  List<MedicalRecord> recordsForMemberByType(String memberId, RecordType type) =>
      state.records.where((r) => r.memberId == memberId && r.type == type).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  /// All active medications across all members
  List<({FamilyMember member, Medication medication, MedicalRecord record})> get activeMedications {
    final result = <({FamilyMember member, Medication medication, MedicalRecord record})>[];
    for (final record in state.records) {
      final member = getMemberById(record.memberId);
      if (member == null) continue;
      for (final med in record.medications) {
        if (med.isActive) {
          result.add((member: member, medication: med, record: record));
        }
      }
    }
    return result;
  }

  /// Upcoming follow-ups
  List<({FamilyMember member, MedicalRecord record})> get upcomingFollowUps {
    final now = DateTime.now();
    final result = <({FamilyMember member, MedicalRecord record})>[];
    for (final record in state.records) {
      if (record.followUpDate != null && record.followUpDate!.isAfter(now)) {
        final member = getMemberById(record.memberId);
        if (member != null) {
          result.add((member: member, record: record));
        }
      }
    }
    result.sort((a, b) => a.record.followUpDate!.compareTo(b.record.followUpDate!));
    return result;
  }

  /// Total medical expenses
  double get totalExpenses =>
      state.records.fold(0.0, (sum, r) => sum + (r.amount ?? 0));

  double expensesForMember(String memberId) =>
      state.records
          .where((r) => r.memberId == memberId)
          .fold(0.0, (sum, r) => sum + (r.amount ?? 0));

  /// Expense by record type
  Map<RecordType, double> get expensesByType {
    final map = <RecordType, double>{};
    for (final r in state.records) {
      if (r.amount != null && r.amount! > 0) {
        map[r.type] = (map[r.type] ?? 0) + r.amount!;
      }
    }
    return map;
  }

  int get totalRecords => state.records.length;
  int get totalMembers => state.members.length;
}
