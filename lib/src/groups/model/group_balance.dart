import 'package:my_data_app/src/groups/model/group_model.dart';

/// One person-to-person transfer that, when paid, moves both members closer
/// to a zero balance. Computed by [computeSettlementPlan].
class SettlementTransfer {
  final String fromUid;
  final String toUid;
  final double amount;

  const SettlementTransfer({
    required this.fromUid,
    required this.toUid,
    required this.amount,
  });

  @override
  String toString() => '$fromUid → $toUid : ${amount.toStringAsFixed(2)}';
}

/// Resolves raw user input ([GroupSplit.value], interpreted per [mode]) into
/// concrete `owed` amounts that sum to [amount]. Rounding error from
/// fractional splits is absorbed into the first split so the total reconciles
/// exactly.
///
/// Throws [ArgumentError] when input is invalid (empty participants, zero
/// total weight in share mode, exact amounts not summing to [amount], etc).
List<GroupSplit> resolveSplits({
  required double amount,
  required SplitMode mode,
  required List<GroupSplit> rawSplits,
}) {
  if (rawSplits.isEmpty) {
    throw ArgumentError('At least one participant is required.');
  }

  switch (mode) {
    case SplitMode.equal:
      final per = amount / rawSplits.length;
      final rounded =
          rawSplits.map((s) => s.copyWith(value: per, owed: per)).toList();
      return _absorbRounding(rounded, amount);

    case SplitMode.exact:
      final sum = rawSplits.fold<double>(0, (s, x) => s + x.value);
      if ((sum - amount).abs() > 0.01) {
        throw ArgumentError(
            'Exact splits sum to ${sum.toStringAsFixed(2)} but total is ${amount.toStringAsFixed(2)}.');
      }
      return rawSplits.map((s) => s.copyWith(owed: s.value)).toList();

    case SplitMode.share:
      final totalWeight = rawSplits.fold<double>(0, (s, x) => s + x.value);
      if (totalWeight <= 0) {
        throw ArgumentError('Shares must sum to a positive number.');
      }
      final mapped = rawSplits
          .map((s) =>
              s.copyWith(owed: amount * (s.value / totalWeight)))
          .toList();
      return _absorbRounding(mapped, amount);

    case SplitMode.percent:
      final totalPct = rawSplits.fold<double>(0, (s, x) => s + x.value);
      if ((totalPct - 100).abs() > 0.01) {
        throw ArgumentError(
            'Percentages must sum to 100 (got ${totalPct.toStringAsFixed(2)}).');
      }
      final mapped = rawSplits
          .map((s) => s.copyWith(owed: amount * (s.value / 100)))
          .toList();
      return _absorbRounding(mapped, amount);
  }
}

List<GroupSplit> _absorbRounding(List<GroupSplit> splits, double target) {
  if (splits.isEmpty) return splits;
  final sum = splits.fold<double>(0, (s, x) => s + x.owed);
  final diff = target - sum;
  if (diff.abs() < 0.005) return splits;
  final first = splits.first;
  return [
    first.copyWith(owed: first.owed + diff),
    ...splits.skip(1),
  ];
}

/// Net balance per member uid after all [expenses] and recorded [settlements]
/// are applied.
///
/// Convention:
/// - **positive** balance ⇒ this member is owed money (creditor).
/// - **negative** balance ⇒ this member owes money (debtor).
///
/// All uids in [memberIds] are guaranteed a key in the result (defaulting to
/// 0) so the caller can iterate without null checks.
Map<String, double> computeNetBalances({
  required List<String> memberIds,
  required List<GroupExpense> expenses,
  required List<GroupSettlement> settlements,
}) {
  final balance = <String, double>{for (final uid in memberIds) uid: 0.0};

  for (final exp in expenses) {
    balance[exp.paidByUid] = (balance[exp.paidByUid] ?? 0) + exp.amount;
    for (final split in exp.splits) {
      balance[split.uid] = (balance[split.uid] ?? 0) - split.owed;
    }
  }

  for (final s in settlements) {
    balance[s.fromUid] = (balance[s.fromUid] ?? 0) + s.amount;
    balance[s.toUid] = (balance[s.toUid] ?? 0) - s.amount;
  }

  return balance;
}

/// Greedy "who owes whom" reduction. Repeatedly matches the biggest creditor
/// with the biggest debtor — for N members produces at most N-1 transfers.
/// Not provably optimal (the true min-transfer problem is NP-hard), but in
/// practice within one transfer of optimal and matches Splitwise's output.
///
/// [epsilon] swallows floating-point dust so members within ±1 paisa are
/// treated as settled.
List<SettlementTransfer> computeSettlementPlan(
  Map<String, double> netBalances, {
  double epsilon = 0.01,
}) {
  final creditors = <MapEntry<String, double>>[];
  final debtors = <MapEntry<String, double>>[];
  for (final e in netBalances.entries) {
    if (e.value > epsilon) {
      creditors.add(MapEntry(e.key, e.value));
    } else if (e.value < -epsilon) {
      debtors.add(MapEntry(e.key, -e.value));
    }
  }

  creditors.sort((a, b) => b.value.compareTo(a.value));
  debtors.sort((a, b) => b.value.compareTo(a.value));

  final transfers = <SettlementTransfer>[];
  var i = 0;
  var j = 0;
  final cAmt = creditors.map((e) => e.value).toList();
  final dAmt = debtors.map((e) => e.value).toList();

  while (i < creditors.length && j < debtors.length) {
    final pay = cAmt[i] < dAmt[j] ? cAmt[i] : dAmt[j];
    transfers.add(SettlementTransfer(
      fromUid: debtors[j].key,
      toUid: creditors[i].key,
      amount: double.parse(pay.toStringAsFixed(2)),
    ));
    cAmt[i] -= pay;
    dAmt[j] -= pay;
    if (cAmt[i] < epsilon) i++;
    if (dAmt[j] < epsilon) j++;
  }

  return transfers;
}
