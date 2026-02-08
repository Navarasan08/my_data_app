import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_data_app/src/auth/cubit/auth_cubit.dart';
import 'package:my_data_app/src/reminder/cubit/bill_cubit.dart';
import 'package:my_data_app/src/reminder/reminder_page.dart';
import 'package:my_data_app/src/vehicle/cubit/vehicle_cubit.dart';
import 'package:my_data_app/src/vehicle/vehicle_manager_page.dart';
import 'package:my_data_app/src/chits/cubit/chit_cubit.dart';
import 'package:my_data_app/src/chits/chit_screen.dart';
import 'package:my_data_app/src/checklist/cubit/checklist_cubit.dart';
import 'package:my_data_app/src/checklist/checklist_page.dart';
import 'package:my_data_app/src/periods/cubit/period_cubit.dart';
import 'package:my_data_app/src/periods/period_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

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

    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
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
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.dashboard_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.apps_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '5 Features',
                                style: TextStyle(
                                  color:
                                      Colors.white.withValues(alpha: 0.9),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
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
                    const SizedBox(height: 24),
                    Text(
                      '$greeting!',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'My Assistant',
                      style: TextStyle(
                        fontSize: 28,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage bills, vehicles, chits, lists & more',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Section title
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
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
              padding: const EdgeInsets.symmetric(horizontal: 20),
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
                    subtitle: 'Track recurring bills and daily tasks',
                    count: billState.tasks.length,
                    countLabel: 'bills',
                    gradient: [
                      Colors.orange[400]!,
                      Colors.deepOrange[400]!
                    ],
                    onTap: () {
                      final billCubit = context.read<BillCubit>();
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
                    subtitle: 'Manage vehicles and expenses',
                    count: vehicleState.vehicles.length,
                    countLabel: 'vehicles',
                    gradient: [
                      Colors.blue[400]!,
                      Colors.indigo[400]!
                    ],
                    onTap: () {
                      final vehicleCubit = context.read<VehicleCubit>();
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
                    subtitle: 'Manage chit groups and auctions',
                    count: chitState.chitFunds.length,
                    countLabel: 'groups',
                    gradient: [
                      Colors.purple[400]!,
                      Colors.deepPurple[400]!
                    ],
                    onTap: () {
                      final chitCubit = context.read<ChitCubit>();
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
                    subtitle: 'Track tasks with target dates',
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
                            child: const ChecklistListPage(),
                          ),
                        ),
                      );
                    },
                  ),
                  _FeatureCard(
                    icon: Icons.favorite_rounded,
                    title: 'Period Tracker',
                    subtitle: 'Track cycles & predictions',
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
                            child: const PeriodTrackerPage(),
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
