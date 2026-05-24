import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:my_data_app/src/groups/cubit/group_cubit.dart';
import 'package:my_data_app/src/groups/cubit/group_state.dart';
import 'package:my_data_app/src/groups/model/group_balance.dart';
import 'package:my_data_app/src/groups/model/group_model.dart';

final _money = NumberFormat('#,##,###.##', 'en_IN');

/// Shows the greedy "who owes whom" plan plus history of settlements already
/// recorded. Each pending transfer has a "Mark paid" button that creates a
/// [GroupSettlement] — that immediately recomputes balances, so a settled
/// transfer disappears from the plan and shows up in history below.
class SettleUpPage extends StatelessWidget {
  final String groupId;
  const SettleUpPage({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return BlocBuilder<GroupCubit, GroupState>(
      builder: (context, state) {
        final cubit = context.read<GroupCubit>();
        final group = cubit.getGroup(groupId);
        if (group == null) {
          return const Scaffold(
              body: Center(child: Text('Group not found')));
        }

        final plan = cubit.settlementPlan(groupId);
        final history = cubit.settlementsFor(groupId);
        final balances = cubit.netBalances(groupId);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Settle up'),
            elevation: 0,
            backgroundColor: group.color.withValues(alpha: 0.1),
          ),
          body: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              _BalanceSummary(group: group, balances: balances),
              const SizedBox(height: 16),

              Text('Suggested transfers',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface)),
              const SizedBox(height: 6),
              if (plan.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded,
                          color: Colors.green[700]),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text('Everyone is settled up.',
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.green[800],
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                )
              else
                ...plan.map(
                  (t) => _TransferRow(
                    group: group,
                    transfer: t,
                    onMarkPaid: () => _confirmAndRecord(context, group, t),
                  ),
                ),

              const SizedBox(height: 24),
              Text('History',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface)),
              const SizedBox(height: 6),
              if (history.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'No payments recorded yet.',
                    style:
                        TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                )
              else
                ...history.map((s) => _SettlementRow(group: group, s: s)),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmAndRecord(
    BuildContext context,
    GroupFund group,
    SettlementTransfer t,
  ) async {
    final cubit = context.read<GroupCubit>();
    final fromName = group.members[t.fromUid]?.label ?? t.fromUid;
    final toName = group.members[t.toUid]?.label ?? t.toUid;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark as paid'),
        content: Text(
            'Record that $fromName paid $toName ₹${_money.format(t.amount)}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirm')),
        ],
      ),
    );
    if (confirmed != true) return;
    final now = DateTime.now();
    await cubit.recordSettlement(GroupSettlement(
      id: now.microsecondsSinceEpoch.toString(),
      groupId: group.id,
      fromUid: t.fromUid,
      toUid: t.toUid,
      amount: t.amount,
      settledAt: now,
      recordedByUid: cubit.currentUid,
    ));
  }
}

class _BalanceSummary extends StatelessWidget {
  final GroupFund group;
  final Map<String, double> balances;
  const _BalanceSummary({required this.group, required this.balances});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: group.color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Net balances',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface)),
          const SizedBox(height: 8),
          ...group.memberIds.map((uid) {
            final m = group.members[uid];
            final bal = balances[uid] ?? 0;
            final isOwed = bal > 0.01;
            final owes = bal < -0.01;
            final color = isOwed
                ? Colors.green[700]
                : owes
                    ? Colors.red[700]
                    : cs.onSurfaceVariant;
            final label = isOwed
                ? 'gets back ₹${_money.format(bal)}'
                : owes
                    ? 'owes ₹${_money.format(-bal)}'
                    : 'settled';
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Expanded(
                    child: Text(m?.label ?? uid,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500)),
                  ),
                  Text(label,
                      style: TextStyle(
                          fontSize: 12,
                          color: color,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _TransferRow extends StatelessWidget {
  final GroupFund group;
  final SettlementTransfer transfer;
  final VoidCallback onMarkPaid;
  const _TransferRow({
    required this.group,
    required this.transfer,
    required this.onMarkPaid,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final from = group.members[transfer.fromUid]?.label ?? transfer.fromUid;
    final to = group.members[transfer.toUid]?.label ?? transfer.toUid;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: TextStyle(fontSize: 13, color: cs.onSurface),
                    children: [
                      TextSpan(
                          text: from,
                          style:
                              const TextStyle(fontWeight: FontWeight.w700)),
                      const TextSpan(text: '  →  '),
                      TextSpan(
                          text: to,
                          style:
                              const TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text('₹${_money.format(transfer.amount)}',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: group.color)),
              ],
            ),
          ),
          TextButton(
              onPressed: onMarkPaid, child: const Text('Mark paid')),
        ],
      ),
    );
  }
}

class _SettlementRow extends StatelessWidget {
  final GroupFund group;
  final GroupSettlement s;
  const _SettlementRow({required this.group, required this.s});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final from = group.members[s.fromUid]?.label ?? s.fromUid;
    final to = group.members[s.toUid]?.label ?? s.toUid;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline_rounded,
              size: 18, color: Colors.green[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$from  →  $to',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                Text(DateFormat('d MMM yyyy').format(s.settledAt),
                    style: TextStyle(
                        fontSize: 11, color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          Text('₹${_money.format(s.amount)}',
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(Icons.delete_outline_rounded,
                size: 18, color: Colors.red[300]),
            tooltip: 'Undo settlement',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Undo settlement'),
                  content: const Text(
                      'Remove this recorded payment? Balances will be restored.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel')),
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: TextButton.styleFrom(
                            foregroundColor: Colors.red),
                        child: const Text('Remove')),
                  ],
                ),
              );
              if (confirmed == true && context.mounted) {
                await context
                    .read<GroupCubit>()
                    .deleteSettlement(group.id, s.id);
              }
            },
          ),
        ],
      ),
    );
  }
}
