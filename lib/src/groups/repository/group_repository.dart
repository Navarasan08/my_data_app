import 'dart:async';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_data_app/src/groups/model/group_model.dart';

/// Repository for Splitwise-style shared groups. Unlike the other repositories
/// in this app (which load once into memory from `users/{uid}/...`), groups
/// live in shared top-level collections and need **realtime listeners** so a
/// member sees another member's edits without a manual refresh.
///
/// Layout:
///   groups/{groupId}                      — the group doc itself
///   groups/{groupId}/expenses/{id}
///   groups/{groupId}/settlements/{id}
///   users/{uid}/groupMemberships/{groupId}  — per-user index (lightweight)
///   groupInvitations/{id}                 — top-level, queryable by email
abstract class GroupRepository {
  Future<void> init();
  Future<void> dispose();

  /// Latest cached snapshot of groups the current user is a member of.
  List<GroupFund> getAllGroups();
  List<GroupExpense> getExpensesFor(String groupId);
  List<GroupSettlement> getSettlementsFor(String groupId);
  List<GroupInvitation> getPendingInvitations();

  /// Fires when ANY of the cached lists above change. The cubit listens to
  /// this to know when to re-emit state. Keeps the API surface small (one
  /// stream rather than four).
  Stream<void> get changes;

  /// Push [newDisplayName] into the current user's [GroupMember] entry in
  /// every group they belong to, but only where the cached name is stale.
  /// No-op when the name already matches — keeps app startup cheap.
  Future<void> syncCurrentUserDisplayName(String? newDisplayName);

  // ── Group lifecycle ──────────────────────────────────────────────────────
  Future<GroupFund> createGroup({
    required String name,
    String? description,
    int iconIndex,
    int colorIndex,
    String currency,
  });
  Future<void> updateGroup(GroupFund group);
  Future<void> deleteGroup(String groupId);
  Future<void> leaveGroup(String groupId);

  // ── Invitations ──────────────────────────────────────────────────────────
  Future<GroupInvitation> inviteByEmail({
    required String groupId,
    required String email,
  });
  Future<void> cancelInvitation(String invitationId);
  Future<void> acceptInvitation(GroupInvitation invitation);
  Future<void> declineInvitation(GroupInvitation invitation);

  // ── Expenses ─────────────────────────────────────────────────────────────
  Future<void> addExpense(GroupExpense expense);
  Future<void> updateExpense(GroupExpense expense);
  Future<void> deleteExpense(String groupId, String expenseId);

  // ── Settlements ──────────────────────────────────────────────────────────
  Future<void> addSettlement(GroupSettlement settlement);
  Future<void> deleteSettlement(String groupId, String settlementId);
}

class FirestoreGroupRepository implements GroupRepository {
  final String uid;
  final String email;
  final String? displayName;
  final FirebaseFirestore _firestore;

  FirestoreGroupRepository({
    required this.uid,
    required this.email,
    this.displayName,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final _changes = StreamController<void>.broadcast();

  /// Subscriptions we need to tear down on dispose. `_groupSubs` is per-group
  /// because we add/remove groups dynamically as the user joins/leaves.
  StreamSubscription? _membershipSub;
  StreamSubscription? _invitationSub;
  final Map<String, _GroupSubs> _groupSubs = {};

  final Map<String, GroupFund> _groups = {};
  final Map<String, List<GroupExpense>> _expenses = {};
  final Map<String, List<GroupSettlement>> _settlements = {};
  List<GroupInvitation> _invitations = [];

  String get _normalizedEmail => email.trim().toLowerCase();

  CollectionReference<Map<String, dynamic>> get _groupsCol =>
      _firestore.collection('groups');
  CollectionReference<Map<String, dynamic>> get _invitationsCol =>
      _firestore.collection('groupInvitations');
  CollectionReference<Map<String, dynamic>> get _membershipsCol => _firestore
      .collection('users')
      .doc(uid)
      .collection('groupMemberships');

  @override
  Stream<void> get changes => _changes.stream;

  @override
  List<GroupFund> getAllGroups() {
    final list = _groups.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return List.unmodifiable(list);
  }

  @override
  List<GroupExpense> getExpensesFor(String groupId) =>
      List.unmodifiable(_expenses[groupId] ?? const []);

  @override
  List<GroupSettlement> getSettlementsFor(String groupId) =>
      List.unmodifiable(_settlements[groupId] ?? const []);

  @override
  List<GroupInvitation> getPendingInvitations() =>
      List.unmodifiable(_invitations);

  @override
  Future<void> init() async {
    // Listen for groups this user belongs to. The membership doc is what tells
    // us which groups to subscribe to — the group doc itself we never query by
    // membership (security rules + cost reasons).
    _membershipSub = _membershipsCol.snapshots().listen(_onMembershipsChanged);

    // Listen for pending invitations sent to this user's email.
    _invitationSub = _invitationsCol
        .where('inviteeEmail', isEqualTo: _normalizedEmail)
        .where('status', isEqualTo: GroupInvitationStatus.pending.index)
        .snapshots()
        .listen(_onInvitationsChanged);

    // Wait for first snapshot of each so callers see a populated cache.
    // Each read is wrapped so a permission-denied on ONE collection doesn't
    // mask which one it was — Firestore's combined Future.wait error elides
    // the failing call.
    await Future.wait([
      _membershipsCol.get().then(_onMembershipsSnapshot).catchError((e, st) {
        developer.log(
          'groups: failed to read users/$uid/groupMemberships',
          name: 'GroupRepository',
          error: e,
          stackTrace: st as StackTrace?,
        );
        throw e;
      }),
      _invitationsCol
          .where('inviteeEmail', isEqualTo: _normalizedEmail)
          .where('status', isEqualTo: GroupInvitationStatus.pending.index)
          .get()
          .then(_onInvitationsSnapshot)
          .catchError((e, st) {
        developer.log(
          'groups: failed to query groupInvitations for $_normalizedEmail',
          name: 'GroupRepository',
          error: e,
          stackTrace: st as StackTrace?,
        );
        throw e;
      }),
    ]);

    // Self-heal: if the user updated their displayName outside the app (or in
    // a prior session before groups existed), push the latest value into each
    // group's members map. The method no-ops when nothing's stale.
    unawaited(syncCurrentUserDisplayName(displayName).catchError((e, st) {
      developer.log(
        'groups: displayName sync failed (non-fatal)',
        name: 'GroupRepository',
        error: e,
        stackTrace: st as StackTrace?,
      );
    }));
  }

  @override
  Future<void> dispose() async {
    await _membershipSub?.cancel();
    await _invitationSub?.cancel();
    for (final subs in _groupSubs.values) {
      await subs.dispose();
    }
    _groupSubs.clear();
    await _changes.close();
  }

  // ── Stream wiring ────────────────────────────────────────────────────────

  void _onMembershipsChanged(QuerySnapshot<Map<String, dynamic>> snap) {
    final ids = snap.docs.map((d) => d.id).toSet();
    // Stop watching groups we left
    for (final gid in _groupSubs.keys.toList()) {
      if (!ids.contains(gid)) {
        _groupSubs.remove(gid)?.dispose();
        _groups.remove(gid);
        _expenses.remove(gid);
        _settlements.remove(gid);
      }
    }
    // Start watching new groups
    for (final gid in ids) {
      _groupSubs.putIfAbsent(gid, () => _subscribeToGroup(gid));
    }
    _changes.add(null);
  }

  Future<void> _onMembershipsSnapshot(
      QuerySnapshot<Map<String, dynamic>> snap) async {
    // For initial load we also want the group docs themselves to be present
    // before init() resolves. Fetch them in parallel with one-shot reads, then
    // let the listener take over.
    final ids = snap.docs.map((d) => d.id).toList();
    await Future.wait(ids.map((gid) async {
      final groupDoc = await _groupsCol.doc(gid).get();
      final data = groupDoc.data();
      if (data != null) _groups[gid] = GroupFund.fromJson(data);
      final exp = await _groupsCol.doc(gid).collection('expenses').get();
      _expenses[gid] = exp.docs
          .map((d) => GroupExpense.fromJson(d.data()))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      final settled = await _groupsCol.doc(gid).collection('settlements').get();
      _settlements[gid] = settled.docs
          .map((d) => GroupSettlement.fromJson(d.data()))
          .toList()
        ..sort((a, b) => b.settledAt.compareTo(a.settledAt));
    }));
    // Now hook up live listeners for the same set.
    for (final gid in ids) {
      _groupSubs.putIfAbsent(gid, () => _subscribeToGroup(gid));
    }
  }

  _GroupSubs _subscribeToGroup(String groupId) {
    final groupSub = _groupsCol.doc(groupId).snapshots().listen((doc) {
      final data = doc.data();
      if (data == null) {
        _groups.remove(groupId);
      } else {
        _groups[groupId] = GroupFund.fromJson(data);
      }
      _changes.add(null);
    });
    final expensesSub =
        _groupsCol.doc(groupId).collection('expenses').snapshots().listen(
      (snap) {
        _expenses[groupId] = snap.docs
            .map((d) => GroupExpense.fromJson(d.data()))
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
        _changes.add(null);
      },
    );
    final settlementsSub = _groupsCol
        .doc(groupId)
        .collection('settlements')
        .snapshots()
        .listen((snap) {
      _settlements[groupId] = snap.docs
          .map((d) => GroupSettlement.fromJson(d.data()))
          .toList()
        ..sort((a, b) => b.settledAt.compareTo(a.settledAt));
      _changes.add(null);
    });
    return _GroupSubs(groupSub, expensesSub, settlementsSub);
  }

  void _onInvitationsChanged(QuerySnapshot<Map<String, dynamic>> snap) {
    _invitations = snap.docs
        .map((d) => GroupInvitation.fromJson(d.data()))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _changes.add(null);
  }

  void _onInvitationsSnapshot(QuerySnapshot<Map<String, dynamic>> snap) {
    _onInvitationsChanged(snap);
  }

  // ── Group lifecycle ──────────────────────────────────────────────────────

  @override
  Future<GroupFund> createGroup({
    required String name,
    String? description,
    int iconIndex = 18,
    int colorIndex = 0,
    String currency = 'INR',
  }) async {
    final now = DateTime.now();
    final groupId = _firestore.collection('groups').doc().id;
    final creator = GroupMember(
      uid: uid,
      email: _normalizedEmail,
      displayName: displayName,
      joinedAt: now,
      role: GroupMemberRole.owner,
    );
    final group = GroupFund(
      id: groupId,
      name: name.trim(),
      description: description?.trim().isEmpty == true ? null : description?.trim(),
      iconIndex: iconIndex,
      colorIndex: colorIndex,
      createdBy: uid,
      createdAt: now,
      updatedAt: now,
      memberIds: [uid],
      members: {uid: creator},
      currency: currency,
    );

    final batch = _firestore.batch();
    batch.set(_groupsCol.doc(groupId), group.toJson());
    batch.set(_membershipsCol.doc(groupId), {
      'groupId': groupId,
      'joinedAt': now.toIso8601String(),
      'role': GroupMemberRole.owner.index,
    });
    await batch.commit();

    // Cache eagerly so the UI sees the new group immediately, without waiting
    // for the snapshot listener to fire.
    _groups[groupId] = group;
    _expenses[groupId] = [];
    _settlements[groupId] = [];
    _changes.add(null);
    return group;
  }

  @override
  Future<void> syncCurrentUserDisplayName(String? newDisplayName) async {
    final normalized =
        (newDisplayName == null || newDisplayName.trim().isEmpty)
            ? null
            : newDisplayName.trim();
    final stale = _groups.values.where((g) {
      final me = g.members[uid];
      return me != null && me.displayName != normalized;
    }).toList();
    if (stale.isEmpty) return;
    final batch = _firestore.batch();
    for (final g in stale) {
      // Update only my entry in the nested members map. Avoids overwriting
      // other members' info and stays inside what the security rules permit
      // (a member editing their own slot).
      batch.update(_groupsCol.doc(g.id), {
        'members.$uid.displayName': normalized,
      });
    }
    await batch.commit();
  }

  @override
  Future<void> updateGroup(GroupFund group) async {
    final updated = group.copyWith(updatedAt: DateTime.now());
    await _groupsCol.doc(group.id).set(updated.toJson());
    _groups[group.id] = updated;
    _changes.add(null);
  }

  @override
  Future<void> deleteGroup(String groupId) async {
    // Only the creator should call this. Best-effort cleanup of subcollections;
    // a Cloud Function would do this properly, but we don't have one here.
    final group = _groups[groupId];
    final expensesSnap =
        await _groupsCol.doc(groupId).collection('expenses').get();
    final settlementsSnap =
        await _groupsCol.doc(groupId).collection('settlements').get();
    final batch = _firestore.batch();
    for (final d in expensesSnap.docs) {
      batch.delete(d.reference);
    }
    for (final d in settlementsSnap.docs) {
      batch.delete(d.reference);
    }
    batch.delete(_groupsCol.doc(groupId));
    // Remove every member's membership index doc.
    if (group != null) {
      for (final memberUid in group.memberIds) {
        batch.delete(_firestore
            .collection('users')
            .doc(memberUid)
            .collection('groupMemberships')
            .doc(groupId));
      }
    } else {
      batch.delete(_membershipsCol.doc(groupId));
    }
    await batch.commit();
  }

  @override
  Future<void> leaveGroup(String groupId) async {
    final group = _groups[groupId];
    if (group == null) return;
    final newMemberIds =
        group.memberIds.where((id) => id != uid).toList();
    final newMembers = Map<String, GroupMember>.from(group.members)
      ..remove(uid);
    final batch = _firestore.batch();
    batch.update(_groupsCol.doc(groupId), {
      'memberIds': newMemberIds,
      'members': newMembers.map((k, v) => MapEntry(k, v.toJson())),
      'updatedAt': DateTime.now().toIso8601String(),
    });
    batch.delete(_membershipsCol.doc(groupId));
    await batch.commit();
  }

  // ── Invitations ──────────────────────────────────────────────────────────

  @override
  Future<GroupInvitation> inviteByEmail({
    required String groupId,
    required String email,
  }) async {
    final group = _groups[groupId];
    if (group == null) {
      throw StateError('Group not found.');
    }
    final invitee = email.trim().toLowerCase();
    if (invitee.isEmpty) {
      throw ArgumentError('Email cannot be empty.');
    }
    if (group.members.values.any((m) => m.email == invitee)) {
      throw StateError('That person is already a member.');
    }
    // Deterministic ID so Firestore security rules can verify "a pending
    // invitation for this user + this group exists" by constructing the path,
    // without needing a query (rules can't run queries). One pending invite
    // per (group, email) is enforced as a natural side effect.
    final invitationId = '${groupId}_$invitee';
    final existing = await _invitationsCol.doc(invitationId).get();
    if (existing.exists) {
      final data = GroupInvitation.fromJson(existing.data()!);
      if (data.status == GroupInvitationStatus.pending) return data;
      // Re-send: overwrite the cancelled/declined record with a fresh pending.
    }

    final invitation = GroupInvitation(
      id: invitationId,
      groupId: groupId,
      groupName: group.name,
      groupIconIndex: group.iconIndex,
      groupColorIndex: group.colorIndex,
      invitedByUid: uid,
      invitedByName: displayName ?? email,
      inviteeEmail: invitee,
      createdAt: DateTime.now(),
    );
    await _invitationsCol.doc(invitation.id).set(invitation.toJson());
    return invitation;
  }

  @override
  Future<void> cancelInvitation(String invitationId) async {
    await _invitationsCol.doc(invitationId).update({
      'status': GroupInvitationStatus.cancelled.index,
      'respondedAt': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> acceptInvitation(GroupInvitation invitation) async {
    final now = DateTime.now();
    final groupRef = _groupsCol.doc(invitation.groupId);

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(groupRef);
      if (!snap.exists) {
        throw StateError('Group no longer exists.');
      }
      final group = GroupFund.fromJson(snap.data()!);
      if (group.memberIds.contains(uid)) {
        // Already a member — just mark the invite accepted.
        tx.update(_invitationsCol.doc(invitation.id), {
          'status': GroupInvitationStatus.accepted.index,
          'inviteeUid': uid,
          'respondedAt': now.toIso8601String(),
        });
        return;
      }
      final newMember = GroupMember(
        uid: uid,
        email: _normalizedEmail,
        displayName: displayName,
        joinedAt: now,
      );
      tx.update(groupRef, {
        'memberIds': FieldValue.arrayUnion([uid]),
        'members.$uid': newMember.toJson(),
        'updatedAt': now.toIso8601String(),
      });
      tx.set(_membershipsCol.doc(invitation.groupId), {
        'groupId': invitation.groupId,
        'joinedAt': now.toIso8601String(),
        'role': GroupMemberRole.member.index,
      });
      tx.update(_invitationsCol.doc(invitation.id), {
        'status': GroupInvitationStatus.accepted.index,
        'inviteeUid': uid,
        'respondedAt': now.toIso8601String(),
      });
    });
  }

  @override
  Future<void> declineInvitation(GroupInvitation invitation) async {
    await _invitationsCol.doc(invitation.id).update({
      'status': GroupInvitationStatus.declined.index,
      'inviteeUid': uid,
      'respondedAt': DateTime.now().toIso8601String(),
    });
  }

  // ── Expenses ─────────────────────────────────────────────────────────────

  @override
  Future<void> addExpense(GroupExpense expense) async {
    await _groupsCol
        .doc(expense.groupId)
        .collection('expenses')
        .doc(expense.id)
        .set(expense.toJson());
    await _groupsCol.doc(expense.groupId).update({
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> updateExpense(GroupExpense expense) async {
    await _groupsCol
        .doc(expense.groupId)
        .collection('expenses')
        .doc(expense.id)
        .set(expense.toJson());
    await _groupsCol.doc(expense.groupId).update({
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> deleteExpense(String groupId, String expenseId) async {
    await _groupsCol
        .doc(groupId)
        .collection('expenses')
        .doc(expenseId)
        .delete();
    await _groupsCol.doc(groupId).update({
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  // ── Settlements ──────────────────────────────────────────────────────────

  @override
  Future<void> addSettlement(GroupSettlement settlement) async {
    await _groupsCol
        .doc(settlement.groupId)
        .collection('settlements')
        .doc(settlement.id)
        .set(settlement.toJson());
    await _groupsCol.doc(settlement.groupId).update({
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> deleteSettlement(String groupId, String settlementId) async {
    await _groupsCol
        .doc(groupId)
        .collection('settlements')
        .doc(settlementId)
        .delete();
    await _groupsCol.doc(groupId).update({
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }
}

class _GroupSubs {
  final StreamSubscription groupSub;
  final StreamSubscription expensesSub;
  final StreamSubscription settlementsSub;

  _GroupSubs(this.groupSub, this.expensesSub, this.settlementsSub);

  Future<void> dispose() async {
    await groupSub.cancel();
    await expensesSub.cancel();
    await settlementsSub.cancel();
  }
}
