import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:my_data_app/src/auth/cubit/auth_cubit.dart';
import 'package:my_data_app/src/events/model/event_model.dart';
import 'package:my_data_app/src/events/cubit/event_cubit.dart';
import 'package:my_data_app/src/events/cubit/event_state.dart';
import 'package:my_data_app/src/events/event_finance_page.dart';
import 'package:my_data_app/src/profile/profile_page.dart';

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

        final hour = DateTime.now().hour;
        final greeting = hour < 12
            ? 'Good Morning'
            : hour < 17
                ? 'Good Afternoon'
                : 'Good Evening';

        final authState = context.watch<AuthCubit>().state;
        final user = authState.user;
        final displayName = user?.displayName;
        final email = user?.email ?? '';
        final userName = (displayName != null && displayName.isNotEmpty)
            ? displayName
            : email;
        final userInitial =
            userName.isNotEmpty ? userName[0].toUpperCase() : '?';

        return Scaffold(
          backgroundColor: const Color(0xFFF0F4F8),
          body: SafeArea(
            child: Column(
              children: [
                // Fixed Header — mirrors the Home dashboard header.
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.blue[700]!, Colors.blue[500]!],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(28),
                      bottomRight: Radius.circular(28),
                    ),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          final authCubit = context.read<AuthCubit>();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BlocProvider.value(
                                value: authCubit,
                                child: const ProfilePage(),
                              ),
                            ),
                          );
                        },
                        child: CircleAvatar(
                          radius: 22,
                          backgroundColor:
                              Colors.white.withValues(alpha: 0.25),
                          child: Text(
                            userInitial,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$greeting!',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            Text(
                              userName,
                              style: const TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _showLogoutDialog(context),
                        icon: const Icon(
                          Icons.logout_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor:
                              Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                    ],
                  ),
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

                          // Placeholder categories for future expansion
                          _SectionHeader(
                            title: 'Tasks & Schedules',
                            icon: Icons.schedule_rounded,
                            color: Colors.grey,
                            count: 0,
                          ),
                          const Padding(
                            padding: EdgeInsets.fromLTRB(12, 4, 12, 16),
                            child: Text(
                              'Coming soon — per-event tasks and schedules',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
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
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey[300]!,
                style: BorderStyle.solid,
              ),
            ),
            child: Icon(Icons.add_rounded, size: 26, color: Colors.grey[600]),
          ),
          const SizedBox(height: 6),
          Text(
            'New Event',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.inventory_2_rounded,
                size: 26, color: Colors.grey[600]),
          ),
          const SizedBox(height: 6),
          Text(
            'Archived',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
