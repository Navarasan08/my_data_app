import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:my_data_app/src/groups/add_group_expense_page.dart';
import 'package:my_data_app/src/groups/cubit/group_cubit.dart';
import 'package:my_data_app/src/groups/cubit/group_state.dart';
import 'package:my_data_app/src/groups/model/group_model.dart';
import 'package:my_data_app/src/groups/settle_up_page.dart';

final _money = NumberFormat('#,##,###.##', 'en_IN');

/// True when the expense was edited after creation. We require a 2-second gap
/// so a fresh expense (where createdAt and lastEditedAt can be near-identical
/// from the cubit's update-on-save path) doesn't immediately show as edited.
bool _wasEdited(GroupExpense e) =>
    e.lastEditedAt != null &&
    e.lastEditedAt!.difference(e.createdAt).inSeconds > 2;

String _editorLabel(GroupFund group, GroupExpense e) {
  final uid = e.lastEditedByUid;
  if (uid == null) return '?';
  return group.members[uid]?.label ?? uid;
}

String _relativeTime(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'just now';
  if (d.inMinutes < 60) return '${d.inMinutes}m ago';
  if (d.inHours < 24) return '${d.inHours}h ago';
  if (d.inDays < 7) return '${d.inDays}d ago';
  return DateFormat('d MMM').format(t);
}

/// Three-tab view of one group:
///  1. Expenses — chronological list, tap to edit, FAB to add
///  2. Members  — current members + pending invitations + invite input
///  3. Settle   — summary card, settlement plan, history
///
/// The summary card at the top is shared across all tabs so the user always
/// sees "you owe X" / "you are owed Y" without switching contexts.
class GroupDetailPage extends StatelessWidget {
  final String groupId;
  const GroupDetailPage({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: BlocBuilder<GroupCubit, GroupState>(
        builder: (context, state) {
          final cubit = context.read<GroupCubit>();
          final group = cubit.getGroup(groupId);
          if (group == null) {
            return const Scaffold(
              body: Center(child: Text('Group not found')),
            );
          }
          final color = group.color;

          return Scaffold(
            appBar: AppBar(
              title: Text(group.name),
              elevation: 0,
              backgroundColor: color.withValues(alpha: 0.1),
              actions: [
                IconButton(
                  icon: Icon(group.isArchived
                      ? Icons.unarchive_rounded
                      : Icons.archive_rounded),
                  tooltip:
                      group.isArchived ? 'Unarchive' : 'Archive',
                  onPressed: () => cubit.toggleArchive(group.id),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) async {
                    if (v == 'leave') {
                      await _confirmLeave(context, group);
                    } else if (v == 'delete') {
                      await _confirmDelete(context, group);
                    }
                  },
                  itemBuilder: (ctx) {
                    final isOwner = group.createdBy == cubit.currentUid;
                    return [
                      const PopupMenuItem(
                        value: 'leave',
                        child: Text('Leave group'),
                      ),
                      if (isOwner)
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete group',
                              style: TextStyle(color: Colors.red)),
                        ),
                    ];
                  },
                ),
              ],
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'Expenses', icon: Icon(Icons.receipt_long_rounded)),
                  Tab(text: 'Members', icon: Icon(Icons.group_rounded)),
                  Tab(text: 'Settle', icon: Icon(Icons.handshake_rounded)),
                ],
              ),
            ),
            body: Column(
              children: [
                _SummaryCard(group: group, cubit: cubit),
                Expanded(
                  child: TabBarView(
                    children: [
                      _ExpensesTab(group: group),
                      _MembersTab(group: group),
                      // Wrap settle-up inside the tab to avoid double scaffolds.
                      _SettleTab(groupId: group.id),
                    ],
                  ),
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              backgroundColor: color,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Add expense'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: cubit,
                    child: AddGroupExpensePage(group: group),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmLeave(BuildContext context, GroupFund group) async {
    final cubit = context.read<GroupCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave group'),
        content: Text(
            'You will no longer see expenses in "${group.name}". You can be re-invited later.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Leave')),
        ],
      ),
    );
    if (confirmed == true) {
      await cubit.leaveGroup(group.id);
      if (context.mounted) Navigator.pop(context);
    }
  }

  Future<void> _confirmDelete(BuildContext context, GroupFund group) async {
    final cubit = context.read<GroupCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete group'),
        content: Text(
            'Delete "${group.name}" for everyone? All expenses and settlements will be removed permanently.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      await cubit.deleteGroup(group.id);
      if (context.mounted) Navigator.pop(context);
    }
  }
}

// ─── Top summary (shared across tabs) ───────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final GroupFund group;
  final GroupCubit cubit;
  const _SummaryCard({required this.group, required this.cubit});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final total = cubit.totalSpentFor(group.id);
    final myBal = cubit.myBalanceIn(group.id);
    final iAmOwed = myBal > 0.01;
    final iOwe = myBal < -0.01;

    return Container(
      width: double.infinity,
      color: group.color.withValues(alpha: 0.06),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Group spend',
                    style: TextStyle(
                        fontSize: 11, color: cs.onSurfaceVariant)),
                Text('₹${_money.format(total)}',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: group.color)),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: iAmOwed
                  ? Colors.green.withValues(alpha: 0.12)
                  : iOwe
                      ? Colors.red.withValues(alpha: 0.12)
                      : cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  iAmOwed
                      ? 'you get back'
                      : iOwe
                          ? 'you owe'
                          : 'all settled',
                  style:
                      TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
                ),
                Text(
                  iAmOwed
                      ? '₹${_money.format(myBal)}'
                      : iOwe
                          ? '₹${_money.format(-myBal)}'
                          : '—',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: iAmOwed
                        ? Colors.green[700]
                        : iOwe
                            ? Colors.red[700]
                            : cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tab 1: Expenses ────────────────────────────────────────────────────────

class _ExpensesTab extends StatelessWidget {
  final GroupFund group;
  const _ExpensesTab({required this.group});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cubit = context.read<GroupCubit>();
    final expenses = cubit.expensesFor(group.id);
    if (expenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_rounded,
                size: 44, color: cs.outlineVariant),
            const SizedBox(height: 10),
            Text('No expenses yet',
                style:
                    TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
            const SizedBox(height: 4),
            Text('Tap "+ Add expense" to record one',
                style:
                    TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
      itemCount: expenses.length,
      itemBuilder: (ctx, i) {
        final e = expenses[i];
        return _ExpenseTile(group: group, expense: e);
      },
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  final GroupFund group;
  final GroupExpense expense;
  const _ExpenseTile({required this.group, required this.expense});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cubit = context.read<GroupCubit>();
    final payer = group.members[expense.paidByUid]?.label ?? '—';
    final mySplit = expense.splits
        .where((s) => s.uid == cubit.currentUid)
        .fold<double>(0, (s, x) => s + x.owed);
    final iPaid = expense.paidByUid == cubit.currentUid;
    final myShare =
        iPaid ? expense.amount - mySplit : -mySplit; // net delta for me

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: cubit,
              child: AddGroupExpensePage(group: group, existing: expense),
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 38,
                decoration: BoxDecoration(
                  color: group.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(expense.title,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(
                      '${DateFormat('d MMM').format(expense.date)} · paid by $payer',
                      style: TextStyle(
                          fontSize: 11, color: cs.onSurfaceVariant),
                    ),
                    if (_wasEdited(expense))
                      Text(
                        'edited by ${_editorLabel(group, expense)} · ${_relativeTime(expense.lastEditedAt!)}',
                        style: TextStyle(
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('₹${_money.format(expense.amount)}',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold)),
                  if (myShare.abs() > 0.01)
                    Text(
                      iPaid
                          ? 'you lent ₹${_money.format(myShare)}'
                          : 'you owe ₹${_money.format(-myShare)}',
                      style: TextStyle(
                        fontSize: 10,
                        color: iPaid
                            ? Colors.green[700]
                            : Colors.red[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              IconButton(
                icon: Icon(Icons.delete_outline_rounded,
                    size: 18, color: Colors.red[300]),
                tooltip: 'Delete',
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete expense'),
                      content: Text('Delete "${expense.title}"?'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel')),
                        TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: TextButton.styleFrom(
                                foregroundColor: Colors.red),
                            child: const Text('Delete')),
                      ],
                    ),
                  );
                  if (confirmed == true && context.mounted) {
                    await cubit.deleteExpense(group.id, expense.id);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Tab 2: Members ─────────────────────────────────────────────────────────

class _MembersTab extends StatefulWidget {
  final GroupFund group;
  const _MembersTab({required this.group});

  @override
  State<_MembersTab> createState() => _MembersTabState();
}

class _MembersTabState extends State<_MembersTab> {
  final _emailCtrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  static final _emailRegex =
      RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

  Future<void> _invite() async {
    final raw = _emailCtrl.text.trim().toLowerCase();
    if (!_emailRegex.hasMatch(raw)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid email')),
      );
      return;
    }
    setState(() => _sending = true);
    try {
      await context
          .read<GroupCubit>()
          .invite(groupId: widget.group.id, email: raw);
      _emailCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invitation sent to $raw')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not invite: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final group = widget.group;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text('Members (${group.memberIds.length})',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: cs.onSurface)),
        const SizedBox(height: 8),
        ...group.memberIds.map((uid) {
          final m = group.members[uid];
          final isOwner = uid == group.createdBy;
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
                CircleAvatar(
                  radius: 16,
                  backgroundColor: group.color.withValues(alpha: 0.2),
                  child: Text(
                    (m?.label.isNotEmpty == true
                            ? m!.label[0]
                            : '?')
                        .toUpperCase(),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: group.color,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m?.label ?? uid,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                      if (m?.email != null && m!.email != m.label)
                        Text(m.email,
                            style: TextStyle(
                                fontSize: 11,
                                color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
                if (isOwner)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: group.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('owner',
                        style: TextStyle(
                            fontSize: 10,
                            color: group.color,
                            fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
          );
        }),

        const SizedBox(height: 20),
        Text('Invite by email',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: cs.onSurface)),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _emailCtrl,
                decoration: const InputDecoration(
                  hintText: 'friend@example.com',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                keyboardType: TextInputType.emailAddress,
                onSubmitted: (_) => _invite(),
              ),
            ),
            const SizedBox(width: 6),
            IconButton.filled(
              onPressed: _sending ? null : _invite,
              icon: _sending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
            'They will see a pending invitation when they open the app, signed in with this email.',
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
      ],
    );
  }
}

// ─── Tab 3: Settle ──────────────────────────────────────────────────────────

class _SettleTab extends StatelessWidget {
  final String groupId;
  const _SettleTab({required this.groupId});

  @override
  Widget build(BuildContext context) {
    // Reuse the SettleUpPage's body inside the tab. We can't embed its
    // Scaffold (would double the AppBar), so we render a stripped variant
    // by pushing into its sub-widgets — simplest: just route to it as a
    // nested page when the body is non-trivial. For inline view we render
    // a minimal version here:
    return _SettleInline(groupId: groupId);
  }
}

class _SettleInline extends StatelessWidget {
  final String groupId;
  const _SettleInline({required this.groupId});

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (innerContext) {
      return SettleUpInlineBody(groupId: groupId);
    });
  }
}

/// Body of the settle-up screen without its own Scaffold/AppBar — used inside
/// the [GroupDetailPage] tab. Pulled out so the standalone [SettleUpPage]
/// stays a real route while the tab reuses the same widgets.
class SettleUpInlineBody extends StatelessWidget {
  final String groupId;
  const SettleUpInlineBody({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    // Delegate to SettleUpPage but extract its body — to avoid duplication we
    // simply navigate the user to a fresh route via a button when they want
    // the full standalone view. Inline, we use a tap-through tile that opens
    // SettleUpPage.
    final cubit = context.read<GroupCubit>();
    final group = cubit.getGroup(groupId);
    if (group == null) return const SizedBox.shrink();
    final plan = cubit.settlementPlan(groupId);
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${plan.length} pending transfer${plan.length == 1 ? "" : "s"}',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface)),
                const SizedBox(height: 8),
                ...plan.take(5).map((t) {
                  final from = group.members[t.fromUid]?.label ?? '?';
                  final to = group.members[t.toUid]?.label ?? '?';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text('$from → $to',
                              style: const TextStyle(fontSize: 13)),
                        ),
                        Text('₹${_money.format(t.amount)}',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: group.color)),
                      ],
                    ),
                  );
                }),
                if (plan.length > 5)
                  Text('+${plan.length - 5} more',
                      style: TextStyle(
                          fontSize: 11, color: cs.onSurfaceVariant)),
              ],
            ),
          ),
        const SizedBox(height: 12),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: group.color,
            minimumSize: const Size.fromHeight(46),
          ),
          icon: const Icon(Icons.handshake_rounded),
          label: const Text('Open settle-up'),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: cubit,
                child: SettleUpPage(groupId: groupId),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
