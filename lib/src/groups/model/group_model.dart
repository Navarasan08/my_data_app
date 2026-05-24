import 'package:flutter/material.dart';

/// Splitwise-style shared expense group. Lives in top-level `groups/{id}`
/// (NOT under `users/{uid}/`) because it is shared across multiple users.
/// `memberIds` is duplicated as a flat list so Firestore security rules can
/// gate read/write with a simple `request.auth.uid in memberIds` check.
class GroupFund {
  final String id;
  final String name;
  final String? description;
  final int iconIndex;
  final int colorIndex;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> memberIds;
  final Map<String, GroupMember> members;
  final bool isArchived;
  final String currency;

  const GroupFund({
    required this.id,
    required this.name,
    this.description,
    this.iconIndex = 18,
    this.colorIndex = 0,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.memberIds,
    required this.members,
    this.isArchived = false,
    this.currency = 'INR',
  });

  IconData get icon =>
      availableIcons[iconIndex.clamp(0, availableIcons.length - 1)];
  Color get color =>
      availableColors[colorIndex.clamp(0, availableColors.length - 1)];

  static final List<IconData> availableIcons = [
    Icons.celebration_rounded,
    Icons.flight_rounded,
    Icons.home_repair_service_rounded,
    Icons.construction_rounded,
    Icons.school_rounded,
    Icons.cake_rounded,
    Icons.health_and_safety_rounded,
    Icons.shopping_bag_rounded,
    Icons.baby_changing_station_rounded,
    Icons.business_center_rounded,
    Icons.house_rounded,
    Icons.directions_car_rounded,
    Icons.movie_rounded,
    Icons.card_giftcard_rounded,
    Icons.restaurant_rounded,
    Icons.temple_hindu_rounded,
    Icons.event_rounded,
    Icons.favorite_rounded,
    Icons.groups_rounded,
    Icons.beach_access_rounded,
  ];

  static final List<Color> availableColors = [
    Colors.deepPurple,
    Colors.pink,
    Colors.orange,
    Colors.brown,
    Colors.teal,
    Colors.amber,
    Colors.red,
    Colors.blue,
    Colors.cyan,
    Colors.indigo,
    Colors.green,
    Colors.deepOrange,
    Colors.purple,
    Colors.lightBlue,
  ];

  GroupFund copyWith({
    String? id,
    String? name,
    String? description,
    int? iconIndex,
    int? colorIndex,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? memberIds,
    Map<String, GroupMember>? members,
    bool? isArchived,
    String? currency,
    bool clearDescription = false,
  }) {
    return GroupFund(
      id: id ?? this.id,
      name: name ?? this.name,
      description: clearDescription ? null : (description ?? this.description),
      iconIndex: iconIndex ?? this.iconIndex,
      colorIndex: colorIndex ?? this.colorIndex,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      memberIds: memberIds ?? this.memberIds,
      members: members ?? this.members,
      isArchived: isArchived ?? this.isArchived,
      currency: currency ?? this.currency,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'iconIndex': iconIndex,
        'colorIndex': colorIndex,
        'createdBy': createdBy,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'memberIds': memberIds,
        'members': members.map((k, v) => MapEntry(k, v.toJson())),
        'isArchived': isArchived,
        'currency': currency,
      };

  factory GroupFund.fromJson(Map<String, dynamic> json) {
    final rawMembers = (json['members'] as Map?) ?? const {};
    return GroupFund(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      iconIndex: json['iconIndex'] as int? ?? 18,
      colorIndex: json['colorIndex'] as int? ?? 0,
      createdBy: json['createdBy'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      memberIds: (json['memberIds'] as List).cast<String>(),
      members: rawMembers.map(
        (k, v) => MapEntry(
          k as String,
          GroupMember.fromJson(Map<String, dynamic>.from(v as Map)),
        ),
      ),
      isArchived: json['isArchived'] as bool? ?? false,
      currency: json['currency'] as String? ?? 'INR',
    );
  }
}

enum GroupMemberRole { owner, member }

class GroupMember {
  final String uid;
  final String email;
  final String? displayName;
  final DateTime joinedAt;
  final GroupMemberRole role;

  const GroupMember({
    required this.uid,
    required this.email,
    this.displayName,
    required this.joinedAt,
    this.role = GroupMemberRole.member,
  });

  String get label =>
      (displayName != null && displayName!.trim().isNotEmpty)
          ? displayName!
          : email;

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'joinedAt': joinedAt.toIso8601String(),
        'role': role.index,
      };

  factory GroupMember.fromJson(Map<String, dynamic> json) => GroupMember(
        uid: json['uid'] as String,
        email: json['email'] as String,
        displayName: json['displayName'] as String?,
        joinedAt: DateTime.parse(json['joinedAt'] as String),
        role: GroupMemberRole.values[
            (json['role'] as int? ?? GroupMemberRole.member.index)
                .clamp(0, GroupMemberRole.values.length - 1)],
      );
}

/// How a [GroupExpense]'s amount is divided among participants.
///
/// - [equal]: every participant owes `amount / participants.length`.
/// - [exact]: each split's [GroupSplit.value] is the absolute amount owed.
/// - [share]: [GroupSplit.value] is a weight; owed = amount * weight / sumOfWeights.
/// - [percent]: [GroupSplit.value] is a percentage 0..100; owed = amount * value / 100.
enum SplitMode { equal, exact, share, percent }

/// One participant's slice of a [GroupExpense]. The persisted shape stores
/// the user's raw input ([value], interpreted per [SplitMode]) AND the
/// resolved [owed] amount so reads don't need to re-derive splits.
class GroupSplit {
  final String uid;
  final double value;
  final double owed;

  const GroupSplit({
    required this.uid,
    required this.value,
    required this.owed,
  });

  GroupSplit copyWith({String? uid, double? value, double? owed}) =>
      GroupSplit(
        uid: uid ?? this.uid,
        value: value ?? this.value,
        owed: owed ?? this.owed,
      );

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'value': value,
        'owed': owed,
      };

  factory GroupSplit.fromJson(Map<String, dynamic> json) => GroupSplit(
        uid: json['uid'] as String,
        value: (json['value'] as num).toDouble(),
        owed: (json['owed'] as num).toDouble(),
      );
}

class GroupExpense {
  final String id;
  final String groupId;
  final String title;
  final double amount;
  final String paidByUid;
  final DateTime date;
  final SplitMode splitMode;
  final List<GroupSplit> splits;
  final String? category;
  final String? notes;
  final String createdByUid;
  final DateTime createdAt;

  /// Lightweight audit trail. Null when the expense has never been edited.
  /// Stamped by [GroupCubit.updateExpense]. Deletes are NOT tracked here
  /// because the doc is gone — would need a soft-delete or a separate
  /// activity log for that.
  final String? lastEditedByUid;
  final DateTime? lastEditedAt;

  const GroupExpense({
    required this.id,
    required this.groupId,
    required this.title,
    required this.amount,
    required this.paidByUid,
    required this.date,
    required this.splitMode,
    required this.splits,
    this.category,
    this.notes,
    required this.createdByUid,
    required this.createdAt,
    this.lastEditedByUid,
    this.lastEditedAt,
  });

  GroupExpense copyWith({
    String? title,
    double? amount,
    String? paidByUid,
    DateTime? date,
    SplitMode? splitMode,
    List<GroupSplit>? splits,
    String? category,
    String? notes,
    String? lastEditedByUid,
    DateTime? lastEditedAt,
  }) {
    return GroupExpense(
      id: id,
      groupId: groupId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      paidByUid: paidByUid ?? this.paidByUid,
      date: date ?? this.date,
      splitMode: splitMode ?? this.splitMode,
      splits: splits ?? this.splits,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      createdByUid: createdByUid,
      createdAt: createdAt,
      lastEditedByUid: lastEditedByUid ?? this.lastEditedByUid,
      lastEditedAt: lastEditedAt ?? this.lastEditedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'groupId': groupId,
        'title': title,
        'amount': amount,
        'paidByUid': paidByUid,
        'date': date.toIso8601String(),
        'splitMode': splitMode.index,
        'splits': splits.map((s) => s.toJson()).toList(),
        'category': category,
        'notes': notes,
        'createdByUid': createdByUid,
        'createdAt': createdAt.toIso8601String(),
        'lastEditedByUid': lastEditedByUid,
        'lastEditedAt': lastEditedAt?.toIso8601String(),
      };

  factory GroupExpense.fromJson(Map<String, dynamic> json) => GroupExpense(
        id: json['id'] as String,
        groupId: json['groupId'] as String,
        title: json['title'] as String,
        amount: (json['amount'] as num).toDouble(),
        paidByUid: json['paidByUid'] as String,
        date: DateTime.parse(json['date'] as String),
        splitMode: SplitMode.values[(json['splitMode'] as int? ?? 0)
            .clamp(0, SplitMode.values.length - 1)],
        splits: (json['splits'] as List)
            .map((e) => GroupSplit.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        category: json['category'] as String?,
        notes: json['notes'] as String?,
        createdByUid: json['createdByUid'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        lastEditedByUid: json['lastEditedByUid'] as String?,
        lastEditedAt: json['lastEditedAt'] != null
            ? DateTime.parse(json['lastEditedAt'] as String)
            : null,
      );
}

/// A recorded payment from one member to another, marking part of the
/// owed balance as settled outside the app (cash, UPI, etc).
class GroupSettlement {
  final String id;
  final String groupId;
  final String fromUid;
  final String toUid;
  final double amount;
  final DateTime settledAt;
  final String recordedByUid;
  final String? notes;

  const GroupSettlement({
    required this.id,
    required this.groupId,
    required this.fromUid,
    required this.toUid,
    required this.amount,
    required this.settledAt,
    required this.recordedByUid,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'groupId': groupId,
        'fromUid': fromUid,
        'toUid': toUid,
        'amount': amount,
        'settledAt': settledAt.toIso8601String(),
        'recordedByUid': recordedByUid,
        'notes': notes,
      };

  factory GroupSettlement.fromJson(Map<String, dynamic> json) =>
      GroupSettlement(
        id: json['id'] as String,
        groupId: json['groupId'] as String,
        fromUid: json['fromUid'] as String,
        toUid: json['toUid'] as String,
        amount: (json['amount'] as num).toDouble(),
        settledAt: DateTime.parse(json['settledAt'] as String),
        recordedByUid: json['recordedByUid'] as String,
        notes: json['notes'] as String?,
      );
}

enum GroupInvitationStatus { pending, accepted, declined, cancelled }

/// Top-level invitation doc. Lives in `groupInvitations/{id}` so the invitee
/// can query by their email before they're a member of the group. Once
/// accepted, the invitee is added to `groups/{groupId}.memberIds` AND the
/// invitation is marked `accepted` (the membership is the source of truth;
/// the invitation is a historical record).
class GroupInvitation {
  final String id;
  final String groupId;
  final String groupName;
  final int groupIconIndex;
  final int groupColorIndex;
  final String invitedByUid;
  final String invitedByName;
  final String inviteeEmail;
  final String? inviteeUid;
  final GroupInvitationStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;

  const GroupInvitation({
    required this.id,
    required this.groupId,
    required this.groupName,
    required this.groupIconIndex,
    required this.groupColorIndex,
    required this.invitedByUid,
    required this.invitedByName,
    required this.inviteeEmail,
    this.inviteeUid,
    this.status = GroupInvitationStatus.pending,
    required this.createdAt,
    this.respondedAt,
  });

  GroupInvitation copyWith({
    GroupInvitationStatus? status,
    String? inviteeUid,
    DateTime? respondedAt,
  }) {
    return GroupInvitation(
      id: id,
      groupId: groupId,
      groupName: groupName,
      groupIconIndex: groupIconIndex,
      groupColorIndex: groupColorIndex,
      invitedByUid: invitedByUid,
      invitedByName: invitedByName,
      inviteeEmail: inviteeEmail,
      inviteeUid: inviteeUid ?? this.inviteeUid,
      status: status ?? this.status,
      createdAt: createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'groupId': groupId,
        'groupName': groupName,
        'groupIconIndex': groupIconIndex,
        'groupColorIndex': groupColorIndex,
        'invitedByUid': invitedByUid,
        'invitedByName': invitedByName,
        'inviteeEmail': inviteeEmail,
        'inviteeUid': inviteeUid,
        'status': status.index,
        'createdAt': createdAt.toIso8601String(),
        'respondedAt': respondedAt?.toIso8601String(),
      };

  factory GroupInvitation.fromJson(Map<String, dynamic> json) =>
      GroupInvitation(
        id: json['id'] as String,
        groupId: json['groupId'] as String,
        groupName: json['groupName'] as String,
        groupIconIndex: json['groupIconIndex'] as int? ?? 18,
        groupColorIndex: json['groupColorIndex'] as int? ?? 0,
        invitedByUid: json['invitedByUid'] as String,
        invitedByName: json['invitedByName'] as String,
        inviteeEmail: json['inviteeEmail'] as String,
        inviteeUid: json['inviteeUid'] as String?,
        status: GroupInvitationStatus.values[(json['status'] as int? ?? 0)
            .clamp(0, GroupInvitationStatus.values.length - 1)],
        createdAt: DateTime.parse(json['createdAt'] as String),
        respondedAt: json['respondedAt'] != null
            ? DateTime.parse(json['respondedAt'] as String)
            : null,
      );
}
