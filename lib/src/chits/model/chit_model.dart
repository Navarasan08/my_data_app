enum ChitStatus { active, completed, upcoming }
enum ChitRole { owner, participant }

class ChitFund {
  final ChitRole role;
  final String id;
  final String name;
  final double totalAmount;
  final int totalMembers;
  final int durationMonths;
  final double monthlyContribution;
  final DateTime startDate;
  final DateTime? endDate;
  final ChitStatus status;
  final List<Member> members;
  final List<Auction> auctions;
  final String? description;

  // Participant-only fields
  final int? myMonthNumber; // which month I won the auction
  final double? myAuctionAmount; // amount I received
  final String? organizerName; // who runs this chit
  final String? organizerPhone;

  ChitFund({
    required this.id,
    required this.name,
    this.role = ChitRole.owner,
    required this.totalAmount,
    required this.totalMembers,
    required this.durationMonths,
    required this.monthlyContribution,
    required this.startDate,
    this.endDate,
    required this.status,
    this.members = const [],
    this.auctions = const [],
    this.description,
    this.myMonthNumber,
    this.myAuctionAmount,
    this.organizerName,
    this.organizerPhone,
  });

  // Participant computed helpers
  double get myTotalPaid {
    if (role != ChitRole.participant || members.isEmpty) return 0;
    return members.first.payments
        .where((p) => p.isPaid)
        .fold(0.0, (sum, p) => sum + p.amount);
  }

  double get myTotalPending {
    if (role != ChitRole.participant || members.isEmpty) return 0;
    return members.first.payments
        .where((p) => !p.isPaid)
        .fold(0.0, (sum, p) => sum + p.amount);
  }

  int get myPaidCount {
    if (role != ChitRole.participant || members.isEmpty) return 0;
    return members.first.payments.where((p) => p.isPaid).length;
  }

  Payment? get myNextPayment {
    if (role != ChitRole.participant || members.isEmpty) return null;
    final pending = members.first.payments
        .where((p) => !p.isPaid)
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return pending.isNotEmpty ? pending.first : null;
  }

  int get currentMonth {
    final now = DateTime.now();
    final diff = DateTime(now.year, now.month)
        .difference(DateTime(startDate.year, startDate.month));
    return (diff.inDays / 30).floor() + 1;
  }

  ChitFund copyWith({
    String? id,
    String? name,
    ChitRole? role,
    double? totalAmount,
    int? totalMembers,
    int? durationMonths,
    double? monthlyContribution,
    DateTime? startDate,
    DateTime? endDate,
    ChitStatus? status,
    List<Member>? members,
    List<Auction>? auctions,
    String? description,
    int? myMonthNumber,
    double? myAuctionAmount,
    String? organizerName,
    String? organizerPhone,
  }) {
    return ChitFund(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      totalAmount: totalAmount ?? this.totalAmount,
      totalMembers: totalMembers ?? this.totalMembers,
      durationMonths: durationMonths ?? this.durationMonths,
      monthlyContribution: monthlyContribution ?? this.monthlyContribution,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      members: members ?? this.members,
      auctions: auctions ?? this.auctions,
      description: description ?? this.description,
      myMonthNumber: myMonthNumber ?? this.myMonthNumber,
      myAuctionAmount: myAuctionAmount ?? this.myAuctionAmount,
      organizerName: organizerName ?? this.organizerName,
      organizerPhone: organizerPhone ?? this.organizerPhone,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role.index,
      'totalAmount': totalAmount,
      'totalMembers': totalMembers,
      'durationMonths': durationMonths,
      'monthlyContribution': monthlyContribution,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'status': status.index,
      'members': members.map((m) => m.toJson()).toList(),
      'auctions': auctions.map((a) => a.toJson()).toList(),
      'description': description,
      'myMonthNumber': myMonthNumber,
      'myAuctionAmount': myAuctionAmount,
      'organizerName': organizerName,
      'organizerPhone': organizerPhone,
    };
  }

  factory ChitFund.fromJson(Map<String, dynamic> json) {
    return ChitFund(
      id: json['id'] as String,
      name: json['name'] as String,
      role: json['role'] != null
          ? ChitRole.values[(json['role'] as int).clamp(0, 1)]
          : ChitRole.owner,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      totalMembers: json['totalMembers'] as int,
      durationMonths: json['durationMonths'] as int,
      monthlyContribution: (json['monthlyContribution'] as num).toDouble(),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      status: ChitStatus.values[json['status'] as int],
      members: (json['members'] as List<dynamic>?)
              ?.map((m) => Member.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
      auctions: (json['auctions'] as List<dynamic>?)
              ?.map((a) => Auction.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
      description: json['description'] as String?,
      myMonthNumber: json['myMonthNumber'] as int?,
      myAuctionAmount: (json['myAuctionAmount'] as num?)?.toDouble(),
      organizerName: json['organizerName'] as String?,
      organizerPhone: json['organizerPhone'] as String?,
    );
  }
}

class Member {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final bool isOrganizer;
  final List<Payment> payments;
  final DateTime joinedDate;

  Member({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.isOrganizer = false,
    this.payments = const [],
    required this.joinedDate,
  });

  Member copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    bool? isOrganizer,
    List<Payment>? payments,
    DateTime? joinedDate,
  }) {
    return Member(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      isOrganizer: isOrganizer ?? this.isOrganizer,
      payments: payments ?? this.payments,
      joinedDate: joinedDate ?? this.joinedDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'isOrganizer': isOrganizer,
      'payments': payments.map((p) => p.toJson()).toList(),
      'joinedDate': joinedDate.toIso8601String(),
    };
  }

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      isOrganizer: json['isOrganizer'] as bool? ?? false,
      payments: (json['payments'] as List<dynamic>?)
              ?.map((p) => Payment.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      joinedDate: DateTime.parse(json['joinedDate'] as String),
    );
  }
}

class Payment {
  final String id;
  final String memberId;
  final int monthNumber;
  final double amount;
  final DateTime dueDate;
  final DateTime? paidDate;
  final bool isPaid;
  final String? notes;

  Payment({
    required this.id,
    required this.memberId,
    required this.monthNumber,
    required this.amount,
    required this.dueDate,
    this.paidDate,
    this.isPaid = false,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'memberId': memberId,
      'monthNumber': monthNumber,
      'amount': amount,
      'dueDate': dueDate.toIso8601String(),
      'paidDate': paidDate?.toIso8601String(),
      'isPaid': isPaid,
      'notes': notes,
    };
  }

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as String,
      memberId: json['memberId'] as String,
      monthNumber: json['monthNumber'] as int,
      amount: (json['amount'] as num).toDouble(),
      dueDate: DateTime.parse(json['dueDate'] as String),
      paidDate: json['paidDate'] != null
          ? DateTime.parse(json['paidDate'] as String)
          : null,
      isPaid: json['isPaid'] as bool? ?? false,
      notes: json['notes'] as String?,
    );
  }
}

class Auction {
  final String id;
  final int monthNumber;
  final DateTime auctionDate;
  final String winnerId;
  final String winnerName;
  final double bidAmount;
  final double discountAmount;
  final double amountReceived;
  final String? notes;

  Auction({
    required this.id,
    required this.monthNumber,
    required this.auctionDate,
    required this.winnerId,
    required this.winnerName,
    required this.bidAmount,
    required this.discountAmount,
    required this.amountReceived,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'monthNumber': monthNumber,
      'auctionDate': auctionDate.toIso8601String(),
      'winnerId': winnerId,
      'winnerName': winnerName,
      'bidAmount': bidAmount,
      'discountAmount': discountAmount,
      'amountReceived': amountReceived,
      'notes': notes,
    };
  }

  factory Auction.fromJson(Map<String, dynamic> json) {
    return Auction(
      id: json['id'] as String,
      monthNumber: json['monthNumber'] as int,
      auctionDate: DateTime.parse(json['auctionDate'] as String),
      winnerId: json['winnerId'] as String,
      winnerName: json['winnerName'] as String,
      bidAmount: (json['bidAmount'] as num).toDouble(),
      discountAmount: (json['discountAmount'] as num).toDouble(),
      amountReceived: (json['amountReceived'] as num).toDouble(),
      notes: json['notes'] as String?,
    );
  }
}
