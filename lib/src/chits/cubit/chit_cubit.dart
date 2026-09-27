import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_data_app/src/chits/model/chit_model.dart';
import 'package:my_data_app/src/chits/repository/chit_repository.dart';
import 'package:my_data_app/src/chits/cubit/chit_state.dart';

class ChitCubit extends Cubit<ChitState> {
  final ChitRepository _repository;
  StreamSubscription<void>? _sub;

  ChitCubit(this._repository)
    : super(
        ChitState(
          chitFunds: _repository.getAll(),
          syncStatus: _repository.syncStatus,
        ),
      ) {
    _sub = _repository.changes.listen((_) => _sync());
  }

  /// Pulls the repository's current list and sync status into state. Runs
  /// on every realtime change and after each local write.
  void _sync() {
    emit(
      state.copyWith(
        chitFunds: _repository.getAll(),
        syncStatus: _repository.syncStatus,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }

  void addChitFund(ChitFund chitFund) {
    _repository.add(chitFund);
    _sync();
  }

  void updateChitFund(ChitFund chitFund) {
    _repository.update(chitFund);
    _sync();
  }

  void deleteChitFund(String chitFundId) {
    _repository.delete(chitFundId);
    _sync();
  }

  void addMember(String chitFundId, Member member) {
    final chitFund = state.chitFunds.firstWhere((c) => c.id == chitFundId);
    final updatedMembers = List<Member>.from(chitFund.members)..add(member);
    _repository.update(chitFund.copyWith(members: updatedMembers));
    _sync();
  }

  void updateMember(String chitFundId, Member member) {
    final chitFund = state.chitFunds.firstWhere((c) => c.id == chitFundId);
    final updatedMembers = List<Member>.from(chitFund.members);
    final index = updatedMembers.indexWhere((m) => m.id == member.id);
    if (index != -1) {
      updatedMembers[index] = member;
    }
    _repository.update(chitFund.copyWith(members: updatedMembers));
    _sync();
  }

  void addAuction(String chitFundId, Auction auction) {
    final chitFund = state.chitFunds.firstWhere((c) => c.id == chitFundId);
    final updatedAuctions = List<Auction>.from(chitFund.auctions)..add(auction);
    _repository.update(chitFund.copyWith(auctions: updatedAuctions));
    _sync();
  }

  void updateAuction(String chitFundId, Auction auction) {
    final chitFund = state.chitFunds.firstWhere((c) => c.id == chitFundId);
    final updatedAuctions = List<Auction>.from(chitFund.auctions);
    final index = updatedAuctions.indexWhere((a) => a.id == auction.id);
    if (index != -1) {
      updatedAuctions[index] = auction;
    }
    _repository.update(chitFund.copyWith(auctions: updatedAuctions));
    _sync();
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
      chitFund.copyWith(members: [updatedMember, ...chitFund.members.skip(1)]),
    );
    _sync();
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
      totalMembers: chitFund.totalMembers > 0
          ? chitFund.totalMembers
          : chitFund.durationMonths,
    );
    final updatedMember = member.copyWith(payments: payments);
    _repository.update(
      chitFund.copyWith(members: [updatedMember, ...chitFund.members.skip(1)]),
    );
    _sync();
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
      chitFund.copyWith(members: [updatedMember, ...chitFund.members.skip(1)]),
    );
    _sync();
  }

  /// Update auction discount for a specific payment month
  void updatePaymentDiscount(
    String chitFundId,
    String paymentId,
    double auctionDiscount,
  ) {
    final chitFund = state.chitFunds.firstWhere((c) => c.id == chitFundId);
    if (chitFund.members.isEmpty) return;
    final member = chitFund.members.first;
    final payments = List<Payment>.from(member.payments);
    final idx = payments.indexWhere((p) => p.id == paymentId);
    if (idx == -1) return;
    payments[idx] = payments[idx].copyWith(
      auctionDiscount: auctionDiscount,
      totalMembers: chitFund.totalMembers > 0
          ? chitFund.totalMembers
          : chitFund.durationMonths,
    );
    final updatedMember = member.copyWith(payments: payments);
    _repository.update(
      chitFund.copyWith(members: [updatedMember, ...chitFund.members.skip(1)]),
    );
    _sync();
  }

  ChitFund? getChitFundById(String chitFundId) {
    final matches = state.chitFunds.where((c) => c.id == chitFundId);
    return matches.isNotEmpty ? matches.first : null;
  }
}
