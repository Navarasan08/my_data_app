import 'package:my_data_app/src/chits/model/chit_model.dart';

abstract class ChitRepository {
  List<ChitFund> getAll();
  void add(ChitFund chitFund);
  void update(ChitFund chitFund);
  void delete(String chitFundId);
}

class InMemoryChitRepository implements ChitRepository {
  final List<ChitFund> _chitFunds;

  InMemoryChitRepository()
      : _chitFunds = [
          ChitFund(
            id: '1',
            name: 'Family Chit Group',
            totalAmount: 100000,
            totalMembers: 20,
            durationMonths: 20,
            monthlyContribution: 5000,
            startDate: DateTime(2024, 1, 1),
            status: ChitStatus.active,
            description: 'Monthly family chit fund group',
            members: [
              Member(
                id: '1',
                name: 'John Doe',
                phone: '+1234567890',
                isOrganizer: true,
                joinedDate: DateTime(2024, 1, 1),
              ),
              Member(
                id: '2',
                name: 'Jane Smith',
                phone: '+1234567891',
                joinedDate: DateTime(2024, 1, 1),
              ),
            ],
            auctions: [
              Auction(
                id: '1',
                monthNumber: 1,
                auctionDate: DateTime(2024, 1, 15),
                winnerId: '1',
                winnerName: 'John Doe',
                bidAmount: 8000,
                discountAmount: 2000,
                amountReceived: 98000,
              ),
            ],
          ),
        ];

  @override
  List<ChitFund> getAll() => List.unmodifiable(_chitFunds);

  @override
  void add(ChitFund chitFund) {
    _chitFunds.add(chitFund);
  }

  @override
  void update(ChitFund chitFund) {
    final index = _chitFunds.indexWhere((c) => c.id == chitFund.id);
    if (index != -1) {
      _chitFunds[index] = chitFund;
    }
  }

  @override
  void delete(String chitFundId) {
    _chitFunds.removeWhere((c) => c.id == chitFundId);
  }
}
