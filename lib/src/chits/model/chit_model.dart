enum ChitStatus { active, completed, upcoming }

class ChitFund {
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

  ChitFund({
    required this.id,
    required this.name,
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
  });

  ChitFund copyWith({
    String? id,
    String? name,
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
  }) {
    return ChitFund(
      id: id ?? this.id,
      name: name ?? this.name,
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
}
