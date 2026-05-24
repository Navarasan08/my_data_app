import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_data_app/src/groups/cubit/group_state.dart';
import 'package:my_data_app/src/groups/model/group_balance.dart';
import 'package:my_data_app/src/groups/model/group_model.dart';
import 'package:my_data_app/src/groups/repository/group_repository.dart';

/// Owns the UI-facing view of [GroupRepository]. The repository pushes change
/// events whenever its realtime listeners fire (or after a local write); the
/// cubit just re-snaps the current cache into a new [GroupState].
///
/// All mutation methods are fire-and-forget from the UI's perspective — the
/// resulting state change arrives via the repository's `changes` stream, NOT
/// synchronously. Methods return `Future` so callers can `await` for error
/// handling.
class GroupCubit extends Cubit<GroupState> {
  final GroupRepository _repository;
  final String currentUid;
  late final StreamSubscription _sub;

  GroupCubit(this._repository, {required this.currentUid})
      : super(const GroupState()) {
    _refresh();
    _sub = _repository.changes.listen((_) => _refresh());
  }

  void _refresh() {
    final groups = _repository.getAllGroups();
    final expensesMap = <String, List<GroupExpense>>{};
    final settlementsMap = <String, List<GroupSettlement>>{};
    for (final g in groups) {
      expensesMap[g.id] = _repository.getExpensesFor(g.id);
      settlementsMap[g.id] = _repository.getSettlementsFor(g.id);
    }
    emit(state.copyWith(
      groups: groups,
      expensesByGroup: expensesMap,
      settlementsByGroup: settlementsMap,
      pendingInvitations: _repository.getPendingInvitations(),
    ));
  }

  // ── Group lifecycle ──────────────────────────────────────────────────────

  Future<GroupFund> createGroup({
    required String name,
    String? description,
    int iconIndex = 18,
    int colorIndex = 0,
    String currency = 'INR',
  }) =>
      _repository.createGroup(
        name: name,
        description: description,
        iconIndex: iconIndex,
        colorIndex: colorIndex,
        currency: currency,
      );

  Future<void> updateGroup(GroupFund group) => _repository.updateGroup(group);

  /// Call after the user updates their auth profile name so every group they
  /// belong to reflects the new label.
  Future<void> syncMyDisplayName(String? newName) =>
      _repository.syncCurrentUserDisplayName(newName);

  Future<void> deleteGroup(String groupId) =>
      _repository.deleteGroup(groupId);
  Future<void> leaveGroup(String groupId) => _repository.leaveGroup(groupId);

  Future<void> toggleArchive(String groupId) async {
    final group = getGroup(groupId);
    if (group == null) return;
    await _repository.updateGroup(group.copyWith(
      isArchived: !group.isArchived,
      updatedAt: DateTime.now(),
    ));
  }

  // ── Invitations ──────────────────────────────────────────────────────────

  Future<GroupInvitation> invite({
    required String groupId,
    required String email,
  }) =>
      _repository.inviteByEmail(groupId: groupId, email: email);

  Future<void> cancelInvitation(String invitationId) =>
      _repository.cancelInvitation(invitationId);
  Future<void> acceptInvitation(GroupInvitation invitation) =>
      _repository.acceptInvitation(invitation);
  Future<void> declineInvitation(GroupInvitation invitation) =>
      _repository.declineInvitation(invitation);

  // ── Expenses ─────────────────────────────────────────────────────────────

  Future<void> addExpense(GroupExpense expense) =>
      _repository.addExpense(expense);

  /// Stamps `lastEditedByUid` / `lastEditedAt` on every edit, so members can
  /// see who last touched a record. The caller doesn't need to set these.
  Future<void> updateExpense(GroupExpense expense) {
    final stamped = expense.copyWith(
      lastEditedByUid: currentUid,
      lastEditedAt: DateTime.now(),
    );
    return _repository.updateExpense(stamped);
  }

  Future<void> deleteExpense(String groupId, String expenseId) =>
      _repository.deleteExpense(groupId, expenseId);

  // ── Settlements ──────────────────────────────────────────────────────────

  Future<void> recordSettlement(GroupSettlement settlement) =>
      _repository.addSettlement(settlement);
  Future<void> deleteSettlement(String groupId, String settlementId) =>
      _repository.deleteSettlement(groupId, settlementId);

  // ── Queries ──────────────────────────────────────────────────────────────

  GroupFund? getGroup(String groupId) {
    final matches = state.groups.where((g) => g.id == groupId);
    return matches.isNotEmpty ? matches.first : null;
  }

  List<GroupFund> get activeGroups =>
      state.groups.where((g) => !g.isArchived).toList();
  List<GroupFund> get archivedGroups =>
      state.groups.where((g) => g.isArchived).toList();

  List<GroupExpense> expensesFor(String groupId) =>
      state.expensesByGroup[groupId] ?? const [];
  List<GroupSettlement> settlementsFor(String groupId) =>
      state.settlementsByGroup[groupId] ?? const [];

  double totalSpentFor(String groupId) =>
      expensesFor(groupId).fold(0.0, (s, e) => s + e.amount);

  /// Net balance per member uid for [groupId]. Positive = owed, negative = owes.
  Map<String, double> netBalances(String groupId) {
    final group = getGroup(groupId);
    if (group == null) return const {};
    return computeNetBalances(
      memberIds: group.memberIds,
      expenses: expensesFor(groupId),
      settlements: settlementsFor(groupId),
    );
  }

  /// What the current user owes (negative) or is owed (positive) in [groupId].
  double myBalanceIn(String groupId) =>
      netBalances(groupId)[currentUid] ?? 0;

  /// Greedy "who owes whom" plan for [groupId]. Empty when the group is
  /// fully settled within ±1 paisa.
  List<SettlementTransfer> settlementPlan(String groupId) =>
      computeSettlementPlan(netBalances(groupId));

  /// Sum of money the current user is owed across ALL active groups.
  /// Useful for a dashboard tile or notification.
  double get totalOwedToMe {
    var total = 0.0;
    for (final g in activeGroups) {
      final bal = netBalances(g.id)[currentUid] ?? 0;
      if (bal > 0) total += bal;
    }
    return total;
  }

  /// Sum of money the current user owes across ALL active groups.
  double get totalIOwe {
    var total = 0.0;
    for (final g in activeGroups) {
      final bal = netBalances(g.id)[currentUid] ?? 0;
      if (bal < 0) total += -bal;
    }
    return total;
  }

  @override
  Future<void> close() async {
    await _sub.cancel();
    return super.close();
  }
}
