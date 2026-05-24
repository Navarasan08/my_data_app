import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:my_data_app/src/auth/cubit/auth_cubit.dart';
import 'package:my_data_app/src/events/model/event_model.dart';
import 'package:my_data_app/src/events/cubit/event_cubit.dart';
import 'package:my_data_app/src/events/cubit/event_state.dart';
import 'package:my_data_app/src/events/event_finance_page.dart';
import 'package:my_data_app/src/groups/create_group_page.dart';
import 'package:my_data_app/src/groups/cubit/group_cubit.dart';
import 'package:my_data_app/src/groups/cubit/group_state.dart';
import 'package:my_data_app/src/groups/group_detail_page.dart';
import 'package:my_data_app/src/groups/invitations_inbox_page.dart';
import 'package:my_data_app/src/groups/model/group_model.dart';
import 'package:my_data_app/src/shell/widgets/app_header.dart';

/// "My Events" tab — mirrors the Home dashboard's layout (blue gradient header
/// + categorized grid of cards). Currently shows a Finance category with one
/// card per user-created event, plus a "+ New Event" card. Designed so more
/// categories (Checklists, Schedules, …) can be added later with zero layout
/// rework.
class MyEventsPage extends StatelessWidget {
  const MyEventsPage({super.key});

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthCubit>().signOut();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EventCubit, EventState>(
      builder: (context, state) {
        final cubit = context.read<EventCubit>();
        final active = cubit.activeEvents;

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                AppHeader(
                  actions: [
                    BlocBuilder<GroupCubit, GroupState>(
                      builder: (context, gs) {
                        final count = gs.pendingInvitations.length;
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            HeaderIconButton(
                              icon: Icons.mark_email_unread_rounded,
                              tooltip: 'Group invitations',
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BlocProvider.value(
                                    value: context.read<GroupCubit>(),
                                    child: const InvitationsInboxPage(),
                                  ),
                                ),
                              ),
                            ),
                            if (count > 0)
                              Positioned(
                                top: -2,
                                right: -2,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: Colors.white, width: 1.5),
                                  ),
                                  child: Text(
                                    '$count',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    HeaderIconButton(
                      icon: Icons.logout_rounded,
                      tooltip: 'Logout',
                      onPressed: () => _showLogoutDialog(context),
                    ),
                  ],
                ),

                // Body — categorized sections (same visual as dashboard)
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final gridCols =
                          width > 900 ? 6 : width > 600 ? 5 : 4;

                      return ListView(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 32),
                        children: [
                          _SectionHeader(
                            title: 'Finance',
                            icon: Icons.account_balance_wallet_rounded,
                            color: Colors.green,
                            count: active.length,
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                            child: GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: gridCols,
                              mainAxisSpacing: 6,
                              crossAxisSpacing: 6,
                              childAspectRatio: 0.85,
                              children: [
                                // One card per active event
                                ...active.map((event) {
                                  final total = cubit.totalSpentFor(event.id);
                                  return _EventGridCard(
                                    event: event,
                                    total: total,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => BlocProvider.value(
                                            value: cubit,
                                            child: EventDetailPage(
                                                eventId: event.id),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                }),
                                // "+" Add new event card
                                _AddEventCard(
                                  onTap: () async {
                                    final newEvent =
                                        await Navigator.push<EventFund>(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => BlocProvider.value(
                                          value: cubit,
                                          child: const AddEventPage(),
                                        ),
                                      ),
                                    );
                                    if (newEvent != null) {
                                      cubit.addEvent(newEvent);
                                    }
                                  },
                                ),
                                // Card to see archived/manage
                                if (cubit.archivedEvents.isNotEmpty)
                                  _ManageCard(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              BlocProvider.value(
                                            value: cubit,
                                            child: const EventFinancePage(),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Groups (Splitwise-style shared expenses)
                          BlocBuilder<GroupCubit, GroupState>(
                            builder: (context, gs) {
                              final gcubit = context.read<GroupCubit>();
                              final groups = gcubit.activeGroups;
                              return Column(
                                children: [
                                  _SectionHeader(
                                    title: 'Groups',
                                    icon: Icons.groups_rounded,
                                    color: Colors.indigo,
                                    count: groups.length,
                                  ),
                                  Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(8, 0, 8, 8),
                                    child: GridView.count(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      crossAxisCount: gridCols,
                                      mainAxisSpacing: 6,
                                      crossAxisSpacing: 6,
                                      childAspectRatio: 0.85,
                                      children: [
                                        ...groups.map((g) {
                                          final myBal =
                                              gcubit.myBalanceIn(g.id);
                                          return _GroupGridCard(
                                            group: g,
                                            myBalance: myBal,
                                            onTap: () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    BlocProvider.value(
                                                  value: gcubit,
                                                  child: GroupDetailPage(
                                                      groupId: g.id),
                                                ),
                                              ),
                                            ),
                                          );
                                        }),
                                        _AddGroupCard(
                                          onTap: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  BlocProvider.value(
                                                value: gcubit,
                                                child:
                                                    const CreateGroupPage(),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Category Section Header (mirrors dashboard's _SectionHeader) ────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final int count;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.color,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Event Grid Card (mirrors dashboard's _FeatureGridCard) ──────────────────

final _money = NumberFormat.compact(locale: 'en_IN');

class _EventGridCard extends StatelessWidget {
  final EventFund event;
  final double total;
  final VoidCallback onTap;

  const _EventGridCard({
    required this.event,
    required this.total,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: event.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(event.icon, size: 26, color: event.color),
              ),
              if (total > 0)
                Positioned(
                  top: -4,
                  right: -6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: event.color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '₹${_money.format(total)}',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            event.name,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _AddEventCard extends StatelessWidget {
  final VoidCallback onTap;
  const _AddEventCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: cs.outline,
                style: BorderStyle.solid,
              ),
            ),
            child: Icon(Icons.add_rounded, size: 26, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 6),
          Text(
            'New Event',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: cs.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _GroupGridCard extends StatelessWidget {
  final GroupFund group;
  final double myBalance;
  final VoidCallback onTap;

  const _GroupGridCard({
    required this.group,
    required this.myBalance,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iAmOwed = myBalance > 0.01;
    final iOwe = myBalance < -0.01;
    final badgeColor = iAmOwed
        ? Colors.green
        : iOwe
            ? Colors.red
            : null;
    final badgeText = iAmOwed
        ? '+₹${_money.format(myBalance)}'
        : iOwe
            ? '-₹${_money.format(-myBalance)}'
            : null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: group.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(group.icon, size: 26, color: group.color),
              ),
              if (badgeText != null)
                Positioned(
                  top: -4,
                  right: -6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badgeText,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            group.name,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _AddGroupCard extends StatelessWidget {
  final VoidCallback onTap;
  const _AddGroupCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: cs.outline,
                style: BorderStyle.solid,
              ),
            ),
            child: Icon(Icons.group_add_rounded,
                size: 26, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 6),
          Text(
            'New Group',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: cs.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ManageCard extends StatelessWidget {
  final VoidCallback onTap;
  const _ManageCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.inventory_2_rounded,
                size: 26, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 6),
          Text(
            'Archived',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: cs.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
