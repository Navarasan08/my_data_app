import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:my_data_app/src/auth/cubit/auth_cubit.dart';
import 'package:my_data_app/src/reminder/model/bill_model.dart';
import 'package:my_data_app/src/reminder/cubit/bill_cubit.dart';
import 'package:my_data_app/src/reminder/reminder_page.dart';
import 'package:my_data_app/src/checklist/model/checklist_model.dart';
import 'package:my_data_app/src/vehicle/cubit/vehicle_cubit.dart';
import 'package:my_data_app/src/vehicle/vehicle_manager_page.dart';
import 'package:my_data_app/src/chits/cubit/chit_cubit.dart';
import 'package:my_data_app/src/chits/chit_screen.dart';
import 'package:my_data_app/src/checklist/cubit/checklist_cubit.dart';
import 'package:my_data_app/src/checklist/checklist_page.dart';
import 'package:my_data_app/src/periods/cubit/period_cubit.dart';
import 'package:my_data_app/src/periods/period_page.dart';
import 'package:my_data_app/src/profile/profile_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  static List<_UpcomingItem> _collectUpcomingItems(
    List<BillTask> bills,
    List<Vehicle> vehicles,
    List<ChitFund> chitFunds,
    List<ChecklistGroup> checklists,
    PeriodCubit periodCubit,
  ) {
    final items = <_UpcomingItem>[];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 1. Bills due today that aren't completed
    for (final bill in bills) {
      if (bill.isDueForDate(today) && !bill.isCompletedForDate(today)) {
        items.add(_UpcomingItem(
          icon: Icons.receipt_long_rounded,
          color: Colors.deepOrange,
          source: 'Bill',
          title: bill.title,
          subtitle: bill.amount != null
              ? '\$${bill.amount!.toStringAsFixed(0)} due today'
              : 'Due today',
          date: today,
          daysLeft: 0,
        ));
      }
      // Check next 7 days for upcoming bills
      for (int d = 1; d <= 7; d++) {
        final futureDate = today.add(Duration(days: d));
        if (bill.isDueForDate(futureDate) &&
            !bill.isCompletedForDate(futureDate)) {
          items.add(_UpcomingItem(
            icon: Icons.receipt_long_rounded,
            color: Colors.orange,
            source: 'Bill',
            title: bill.title,
            subtitle: bill.amount != null
                ? '\$${bill.amount!.toStringAsFixed(0)} in $d days'
                : 'In $d days',
            date: futureDate,
            daysLeft: d,
          ));
          break; // Only show the next upcoming occurrence
        }
      }
    }

    // 2. Vehicle service due
    for (final vehicle in vehicles) {
      final daysLeft = vehicle.daysLeftForService;
      if (daysLeft != null && daysLeft <= 30) {
        final nsd = vehicle.nextServiceDate!;
        items.add(_UpcomingItem(
          icon: Icons.build_rounded,
          color: daysLeft < 0
              ? Colors.red
              : daysLeft <= 7
                  ? Colors.orange
                  : Colors.blue,
          source: 'Vehicle',
          title: '${vehicle.name} service',
          subtitle: daysLeft < 0
              ? 'Overdue by ${-daysLeft} days'
              : daysLeft == 0
                  ? 'Due today'
                  : '$daysLeft days left',
          date: nsd,
          daysLeft: daysLeft,
        ));
      }
    }

    // 3. Chit unpaid payments (within next 30 days or overdue)
    for (final fund in chitFunds) {
      if (fund.status != ChitStatus.active) continue;
      for (final member in fund.members) {
        for (final payment in member.payments) {
          if (payment.isPaid) continue;
          final dueDate = DateTime(
              payment.dueDate.year, payment.dueDate.month, payment.dueDate.day);
          final diff = dueDate.difference(today).inDays;
          if (diff <= 30) {
            items.add(_UpcomingItem(
              icon: Icons.group_work_rounded,
              color: diff < 0
                  ? Colors.red
                  : diff <= 7
                      ? Colors.orange
                      : Colors.purple,
              source: 'Chit',
              title: '${fund.name} - ${member.name}',
              subtitle: diff < 0
                  ? 'Payment overdue by ${-diff} days'
                  : diff == 0
                      ? '\$${payment.amount.toStringAsFixed(0)} due today'
                      : '\$${payment.amount.toStringAsFixed(0)} in $diff days',
              date: payment.dueDate,
              daysLeft: diff,
            ));
          }
        }
      }
    }

    // 4. Checklist target dates (incomplete, within 30 days or overdue)
    for (final checklist in checklists) {
      if (checklist.isAllCompleted) continue;
      final daysLeft = checklist.daysLeft;
      if (daysLeft <= 30) {
        items.add(_UpcomingItem(
          icon: Icons.checklist_rounded,
          color: daysLeft < 0
              ? Colors.red
              : daysLeft <= 7
                  ? Colors.orange
                  : Colors.teal,
          source: 'Checklist',
          title: checklist.name,
          subtitle: daysLeft < 0
              ? 'Overdue by ${-daysLeft} days (${checklist.completedItems}/${checklist.totalItems})'
              : daysLeft == 0
                  ? 'Due today (${checklist.completedItems}/${checklist.totalItems})'
                  : '$daysLeft days left (${checklist.completedItems}/${checklist.totalItems})',
          date: checklist.targetDate,
          daysLeft: daysLeft,
        ));
      }
    }

    // 5. Next predicted period
    final nextPeriod = periodCubit.nextPeriodStart;
    if (nextPeriod != null) {
      final diff = DateTime(nextPeriod.year, nextPeriod.month, nextPeriod.day)
          .difference(today)
          .inDays;
      if (diff >= 0 && diff <= 30) {
        items.add(_UpcomingItem(
          icon: Icons.favorite_rounded,
          color: diff <= 3 ? Colors.pink : Colors.pink[300]!,
          source: 'Period',
          title: 'Next period',
          subtitle:
              diff == 0 ? 'Predicted today' : 'Predicted in $diff days',
          date: nextPeriod,
          daysLeft: diff,
        ));
      }
    }

    // Sort: overdue first (most overdue), then by nearest date
    items.sort((a, b) => a.daysLeft.compareTo(b.daysLeft));
    return items;
  }

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
    final billState = context.watch<BillCubit>().state;
    final vehicleState = context.watch<VehicleCubit>().state;
    final chitState = context.watch<ChitCubit>().state;
    final checklistState = context.watch<ChecklistCubit>().state;
    final periodState = context.watch<PeriodCubit>().state;

    final periodCubit = context.read<PeriodCubit>();

    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';

    // Collect upcoming items from all modules
    final upcomingItems = _collectUpcomingItems(
      billState.tasks,
      vehicleState.vehicles,
      chitState.chitFunds,
      checklistState.checklists,
      periodCubit,
    );

    final authState = context.watch<AuthCubit>().state;
    final user = authState.user;
    final displayName = user?.displayName;
    final email = user?.email ?? '';
    final userName = (displayName != null && displayName.isNotEmpty)
        ? displayName
        : email;
    final userInitial = userName.isNotEmpty ? userName[0].toUpperCase() : '?';

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Fixed Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue[700]!,
                    Colors.blue[500]!,
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Row(
                children: [
                  // Profile icon
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
                  // Greeting + Name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$greeting!',
                          style: TextStyle(
                            fontSize: 13,
                            color:
                                Colors.white.withValues(alpha: 0.8),
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
                  // Logout icon
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

            // Scrollable content
            Expanded(
              child: CustomScrollView(
                slivers: [
                  // Upcoming section
                  if (upcomingItems.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding:
                            const EdgeInsets.fromLTRB(24, 20, 24, 12),
                        child: Row(
                          children: [
                            Text(
                              'Upcoming',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius:
                                    BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${upcomingItems.length}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red[600],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _UpcomingItemTile(
                              item: upcomingItems[index]),
                          childCount: upcomingItems.length,
                        ),
                      ),
                    ),
                  ],

                  // Features title
                  SliverToBoxAdapter(
                    child: Padding(
                      padding:
                          const EdgeInsets.fromLTRB(24, 20, 24, 12),
                      child: Text(
                        'Features',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                  ),

                  // Grid of feature cards
                  SliverPadding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.85,
                      ),
                      delegate: SliverChildListDelegate([
                        _FeatureCard(
                          icon: Icons.receipt_long_rounded,
                          title: 'Bills & Tasks',
                          subtitle:
                              'Track recurring bills and daily tasks',
                          count: billState.tasks.length,
                          countLabel: 'bills',
                          gradient: [
                            Colors.orange[400]!,
                            Colors.deepOrange[400]!
                          ],
                          onTap: () {
                            final billCubit =
                                context.read<BillCubit>();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BlocProvider.value(
                                  value: billCubit,
                                  child: const BillTaskPage(),
                                ),
                              ),
                            );
                          },
                        ),
                        _FeatureCard(
                          icon: Icons.directions_car_rounded,
                          title: 'Vehicles',
                          subtitle:
                              'Manage vehicles and expenses',
                          count: vehicleState.vehicles.length,
                          countLabel: 'vehicles',
                          gradient: [
                            Colors.blue[400]!,
                            Colors.indigo[400]!
                          ],
                          onTap: () {
                            final vehicleCubit =
                                context.read<VehicleCubit>();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BlocProvider.value(
                                  value: vehicleCubit,
                                  child: const VehicleListPage(),
                                ),
                              ),
                            );
                          },
                        ),
                        _FeatureCard(
                          icon: Icons.group_work_rounded,
                          title: 'Chit Funds',
                          subtitle:
                              'Manage chit groups and auctions',
                          count: chitState.chitFunds.length,
                          countLabel: 'groups',
                          gradient: [
                            Colors.purple[400]!,
                            Colors.deepPurple[400]!
                          ],
                          onTap: () {
                            final chitCubit =
                                context.read<ChitCubit>();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BlocProvider.value(
                                  value: chitCubit,
                                  child: const ChitFundListPage(),
                                ),
                              ),
                            );
                          },
                        ),
                        _FeatureCard(
                          icon: Icons.checklist_rounded,
                          title: 'Checklists',
                          subtitle:
                              'Track tasks with target dates',
                          count: checklistState.checklists.length,
                          countLabel: 'lists',
                          gradient: [
                            Colors.teal[400]!,
                            Colors.green[600]!,
                          ],
                          onTap: () {
                            final checklistCubit =
                                context.read<ChecklistCubit>();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BlocProvider.value(
                                  value: checklistCubit,
                                  child:
                                      const ChecklistListPage(),
                                ),
                              ),
                            );
                          },
                        ),
                        _FeatureCard(
                          icon: Icons.favorite_rounded,
                          title: 'Period Tracker',
                          subtitle:
                              'Track cycles & predictions',
                          count: periodState.entries.length,
                          countLabel: 'logs',
                          gradient: [
                            Colors.pink[300]!,
                            Colors.pink[600]!,
                          ],
                          onTap: () {
                            final periodCubit =
                                context.read<PeriodCubit>();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BlocProvider.value(
                                  value: periodCubit,
                                  child:
                                      const PeriodTrackerPage(),
                                ),
                              ),
                            );
                          },
                        ),
                      ]),
                    ),
                  ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: 32),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final int count;
  final String countLabel;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.count,
    required this.countLabel,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      shadowColor: gradient[0].withValues(alpha: 0.3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: Colors.white, size: 28),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$count $countLabel',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.8),
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    'Open',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpcomingItem {
  final IconData icon;
  final Color color;
  final String source;
  final String title;
  final String subtitle;
  final DateTime date;
  final int daysLeft;

  const _UpcomingItem({
    required this.icon,
    required this.color,
    required this.source,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.daysLeft,
  });
}

class _UpcomingItemTile extends StatelessWidget {
  final _UpcomingItem item;

  const _UpcomingItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, color: item.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: item.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.source,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: item.color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            DateFormat('MMM dd').format(item.date),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
