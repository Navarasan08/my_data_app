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
import 'package:my_data_app/src/home/cubit/home_record_cubit.dart';
import 'package:my_data_app/src/home/home_record_page.dart';
import 'package:my_data_app/src/schedule/cubit/schedule_cubit.dart';
import 'package:my_data_app/src/schedule/schedule_page.dart';
import 'package:my_data_app/src/food_menu/cubit/food_menu_cubit.dart';
import 'package:my_data_app/src/food_menu/food_menu_page.dart';
import 'package:my_data_app/src/profile/profile_page.dart';
import 'package:my_data_app/src/dashboard/dashboard_settings_cubit.dart';
import 'package:my_data_app/src/dashboard/dashboard_settings_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  String _getSubtitle(String id) {
    switch (id) {
      case 'bills': return 'Track recurring bills and daily tasks';
      case 'vehicles': return 'Manage vehicles and expenses';
      case 'chits': return 'Manage chit groups and auctions';
      case 'checklists': return 'Track tasks with target dates';
      case 'periods': return 'Track cycles & predictions';
      case 'home': return 'Track home purchases & expenses';
      case 'schedules': return 'Plan and manage your events';
      case 'food_menu': return 'Plan weekly meals';
      default: return '';
    }
  }

  String _getCountLabel(String id) {
    switch (id) {
      case 'bills': return 'bills';
      case 'vehicles': return 'vehicles';
      case 'chits': return 'groups';
      case 'checklists': return 'lists';
      case 'periods': return 'logs';
      case 'home': return 'records';
      case 'schedules': return 'events';
      case 'food_menu': return 'meals';
      default: return '';
    }
  }

  int _getCount(String id, billState, vehicleState, chitState, checklistState, periodState, homeRecordState, scheduleState, foodMenuState) {
    switch (id) {
      case 'bills': return billState.tasks.length;
      case 'vehicles': return vehicleState.vehicles.length;
      case 'chits': return chitState.chitFunds.length;
      case 'checklists': return checklistState.checklists.length;
      case 'periods': return periodState.entries.length;
      case 'home': return homeRecordState.records.length;
      case 'schedules': return scheduleState.entries.length;
      case 'food_menu': return foodMenuState.entries.length;
      default: return 0;
    }
  }

  void _navigateToFeature(BuildContext context, String id) {
    Widget page;
    switch (id) {
      case 'bills':
        page = BlocProvider.value(
          value: context.read<BillCubit>(),
          child: const BillTaskPage(),
        );
        break;
      case 'vehicles':
        page = BlocProvider.value(
          value: context.read<VehicleCubit>(),
          child: const VehicleListPage(),
        );
        break;
      case 'chits':
        page = BlocProvider.value(
          value: context.read<ChitCubit>(),
          child: const ChitFundListPage(),
        );
        break;
      case 'checklists':
        page = BlocProvider.value(
          value: context.read<ChecklistCubit>(),
          child: const ChecklistListPage(),
        );
        break;
      case 'periods':
        page = BlocProvider.value(
          value: context.read<PeriodCubit>(),
          child: const PeriodTrackerPage(),
        );
        break;
      case 'home':
        page = BlocProvider.value(
          value: context.read<HomeRecordCubit>(),
          child: const HomeRecordPage(),
        );
        break;
      case 'schedules':
        page = BlocProvider.value(
          value: context.read<ScheduleCubit>(),
          child: const SchedulePage(),
        );
        break;
      case 'food_menu':
        page = BlocProvider.value(
          value: context.read<FoodMenuCubit>(),
          child: const FoodMenuPage(),
        );
        break;
      default:
        return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
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
    final homeRecordState = context.watch<HomeRecordCubit>().state;
    final scheduleState = context.watch<ScheduleCubit>().state;
    final foodMenuState = context.watch<FoodMenuCubit>().state;
    final dashSettings = context.watch<DashboardSettingsCubit>().state;
    final visibleFeatures = dashSettings.visibleFeatures;

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
                  // Settings icon
                  IconButton(
                    onPressed: () {
                      final settingsCubit =
                          context.read<DashboardSettingsCubit>();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BlocProvider.value(
                            value: settingsCubit,
                            child: const DashboardSettingsPage(),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.settings_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor:
                          Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  const SizedBox(width: 6),
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final isWide = width > 600;
                  final isExtraWide = width > 900;
                  final gridCols = isExtraWide ? 4 : isWide ? 3 : 2;
                  final contentMaxWidth = isExtraWide ? 1200.0 : double.infinity;
                  final hPad = isWide ? 32.0 : 20.0;

                  return CustomScrollView(
                slivers: [
                  // Features title
                  SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: contentMaxWidth),
                        child: Padding(
                      padding:
                          EdgeInsets.fromLTRB(hPad + 4, 20, hPad + 4, 12),
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
                    ),
                  ),

                  // Grid of feature cards
                  SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: contentMaxWidth),
                        child: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: hPad),
                    child: GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: gridCols,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: isExtraWide ? 1.0 : isWide ? 0.9 : 0.85,
                      children: visibleFeatures.map((f) {
                        return _FeatureCard(
                          icon: f.icon,
                          title: f.title,
                          subtitle: _getSubtitle(f.id),
                          count: _getCount(f.id, billState, vehicleState, chitState, checklistState, periodState, homeRecordState, scheduleState, foodMenuState),
                          countLabel: _getCountLabel(f.id),
                          gradient: [
                            f.gradient[0].withValues(alpha: 1.0),
                            f.gradient[1].withValues(alpha: 1.0),
                          ],
                          onTap: () => _navigateToFeature(context, f.id),
                        );
                      }).toList(),
                    ),
                        ),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: 32),
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

