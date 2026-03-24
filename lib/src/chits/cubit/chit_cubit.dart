import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_data_app/src/chits/model/chit_model.dart';
import 'package:my_data_app/src/chits/repository/chit_repository.dart';
import 'package:my_data_app/src/chits/cubit/chit_state.dart';

class ChitCubit extends Cubit<ChitState> {
  final ChitRepository _repository;

  ChitCubit(this._repository)
      : super(ChitState(chitFunds: _repository.getAll()));

  void addChitFund(ChitFund chitFund) {
    _repository.add(chitFund);
    emit(state.copyWith(chitFunds: _repository.getAll()));
  }

  void updateChitFund(ChitFund chitFund) {
    _repository.update(chitFund);
    emit(state.copyWith(chitFunds: _repository.getAll()));
  }

  void deleteChitFund(String chitFundId) {
    _repository.delete(chitFundId);
    emit(state.copyWith(chitFunds: _repository.getAll()));
  }

  void addMember(String chitFundId, Member member) {
    final chitFund = state.chitFunds.firstWhere((c) => c.id == chitFundId);
    final updatedMembers = List<Member>.from(chitFund.members)..add(member);
    _repository.update(chitFund.copyWith(members: updatedMembers));
    emit(state.copyWith(chitFunds: _repository.getAll()));
  }

  void updateMember(String chitFundId, Member member) {
    final chitFund = state.chitFunds.firstWhere((c) => c.id == chitFundId);
    final updatedMembers = List<Member>.from(chitFund.members);
    final index = updatedMembers.indexWhere((m) => m.id == member.id);
    if (index != -1) {
      updatedMembers[index] = member;
    }
    _repository.update(chitFund.copyWith(members: updatedMembers));
    emit(state.copyWith(chitFunds: _repository.getAll()));
  }

  void addAuction(String chitFundId, Auction auction) {
    final chitFund = state.chitFunds.firstWhere((c) => c.id == chitFundId);
    final updatedAuctions = List<Auction>.from(chitFund.auctions)
      ..add(auction);
    _repository.update(chitFund.copyWith(auctions: updatedAuctions));
    emit(state.copyWith(chitFunds: _repository.getAll()));
  }

  void updateAuction(String chitFundId, Auction auction) {
    final chitFund = state.chitFunds.firstWhere((c) => c.id == chitFundId);
    final updatedAuctions = List<Auction>.from(chitFund.auctions);
    final index = updatedAuctions.indexWhere((a) => a.id == auction.id);
    if (index != -1) {
      updatedAuctions[index] = auction;
    }
    _repository.update(chitFund.copyWith(auctions: updatedAuctions));
    emit(state.copyWith(chitFunds: _repository.getAll()));
  }

  List<ChitFund> getByStatus(ChitStatus status) {
    return state.chitFunds.where((c) => c.status == status).toList();
  }

  List<ChitFund> getByRole(ChitRole role) {
    return state.chitFunds.where((c) => c.role == role).toList();
  }

  void togglePayment(String chitFundId, String paymentId) {
    final chitFund = state.chitFunds.firstWhere((c) => c.id == chitFundId);
    if (chitFund.members.isEmpty) return;
    final member = chitFund.members.first;
    final payments = List<Payment>.from(member.payments);
    final idx = payments.indexWhere((p) => p.id == paymentId);
    if (idx == -1) return;
    final p = payments[idx];
    payments[idx] = p.copyWith(
      paidDate: p.isPaid ? null : DateTime.now(),
      isPaid: !p.isPaid,
    );
    final updatedMember = member.copyWith(payments: payments);
    _repository.update(
        chitFund.copyWith(members: [updatedMember, ...chitFund.members.skip(1)]));
    emit(state.copyWith(chitFunds: _repository.getAll()));
  }

  /// Mark payment as paid with auction details (for participant view)
  void markPaymentWithAuction({
    required String chitFundId,
    required String paymentId,
    required double auctionDiscount,
    required bool isWonByMe,
    String? auctionWinner,
  }) {
    final chitFund = state.chitFunds.firstWhere((c) => c.id == chitFundId);
    if (chitFund.members.isEmpty) return;
    final member = chitFund.members.first;
    final payments = List<Payment>.from(member.payments);
    final idx = payments.indexWhere((p) => p.id == paymentId);
    if (idx == -1) return;
    final p = payments[idx];
    payments[idx] = p.copyWith(
      isPaid: true,
      paidDate: DateTime.now(),
      auctionValue: auctionDiscount,
      auctionDiscount: auctionDiscount,
      isWonByMe: isWonByMe,
      auctionWinner: auctionWinner,
      totalMembers: chitFund.totalMembers > 0 ? chitFund.totalMembers : chitFund.durationMonths,
    );
    final updatedMember = member.copyWith(payments: payments);
    _repository.update(
        chitFund.copyWith(members: [updatedMember, ...chitFund.members.skip(1)]));
    emit(state.copyWith(chitFunds: _repository.getAll()));
  }

  /// Mark payment as unpaid (undo)
  void markPaymentUnpaid(String chitFundId, String paymentId) {
    final chitFund = state.chitFunds.firstWhere((c) => c.id == chitFundId);
    if (chitFund.members.isEmpty) return;
    final member = chitFund.members.first;
    final payments = List<Payment>.from(member.payments);
    final idx = payments.indexWhere((p) => p.id == paymentId);
    if (idx == -1) return;
    payments[idx] = payments[idx].copyWith(
      isPaid: false,
      paidDate: null,
      clearAuctionDiscount: true,
      clearAuctionWinner: true,
      isWonByMe: false,
    );
    final updatedMember = member.copyWith(payments: payments);
    _repository.update(
        chitFund.copyWith(members: [updatedMember, ...chitFund.members.skip(1)]));
    emit(state.copyWith(chitFunds: _repository.getAll()));
  }

  /// Update auction discount for a specific payment month
  void updatePaymentDiscount(String chitFundId, String paymentId, double auctionDiscount) {
    final chitFund = state.chitFunds.firstWhere((c) => c.id == chitFundId);
    if (chitFund.members.isEmpty) return;
    final member = chitFund.members.first;
    final payments = List<Payment>.from(member.payments);
    final idx = payments.indexWhere((p) => p.id == paymentId);
    if (idx == -1) return;
    payments[idx] = payments[idx].copyWith(
      auctionDiscount: auctionDiscount,
      totalMembers: chitFund.totalMembers > 0 ? chitFund.totalMembers : chitFund.durationMonths,
    );
    final updatedMember = member.copyWith(payments: payments);
    _repository.update(
        chitFund.copyWith(members: [updatedMember, ...chitFund.members.skip(1)]));
    emit(state.copyWith(chitFunds: _repository.getAll()));
  }

  ChitFund? getChitFundById(String chitFundId) {
    final matches = state.chitFunds.where((c) => c.id == chitFundId);
    return matches.isNotEmpty ? matches.first : null;
  }
}
