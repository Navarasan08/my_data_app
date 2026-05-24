import 'package:my_data_app/src/groups/model/group_model.dart';

class GroupState {
  final List<GroupFund> groups;
  final Map<String, List<GroupExpense>> expensesByGroup;
  final Map<String, List<GroupSettlement>> settlementsByGroup;
  final List<GroupInvitation> pendingInvitations;

  const GroupState({
    this.groups = const [],
    this.expensesByGroup = const {},
    this.settlementsByGroup = const {},
    this.pendingInvitations = const [],
  });

  GroupState copyWith({
    List<GroupFund>? groups,
    Map<String, List<GroupExpense>>? expensesByGroup,
    Map<String, List<GroupSettlement>>? settlementsByGroup,
    List<GroupInvitation>? pendingInvitations,
  }) {
    return GroupState(
      groups: groups ?? this.groups,
      expensesByGroup: expensesByGroup ?? this.expensesByGroup,
      settlementsByGroup: settlementsByGroup ?? this.settlementsByGroup,
      pendingInvitations: pendingInvitations ?? this.pendingInvitations,
    );
  }
}
