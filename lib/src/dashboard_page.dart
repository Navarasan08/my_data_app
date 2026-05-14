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
import 'package:my_data_app/src/loans/cubit/loan_cubit.dart';
import 'package:my_data_app/src/loans/loan_page.dart';
import 'package:my_data_app/src/goals/cubit/goal_cubit.dart';
import 'package:my_data_app/src/goals/goal_page.dart';
import 'package:my_data_app/src/money_owe/cubit/money_owe_cubit.dart';
import 'package:my_data_app/src/money_owe/money_owe_page.dart';
import 'package:my_data_app/src/medical/cubit/medical_cubit.dart';
import 'package:my_data_app/src/medical/medical_page.dart';
import 'package:my_data_app/src/profile_vault/cubit/profile_vault_cubit.dart';
import 'package:my_data_app/src/profile_vault/profile_vault_page.dart';
import 'package:my_data_app/src/land/cubit/land_cubit.dart';
import 'package:my_data_app/src/land/land_page.dart';
import 'package:my_data_app/src/interest/cubit/interest_cubit.dart';
import 'package:my_data_app/src/interest/interest_page.dart';
import 'package:my_data_app/src/activities/cubit/activity_cubit.dart';
import 'package:my_data_app/src/activities/activity_page.dart';
import 'package:my_data_app/src/diet/cubit/diet_cubit.dart';
import 'package:my_data_app/src/diet/diet_page.dart';
import 'package:my_data_app/src/days_counter/cubit/days_counter_cubit.dart';
import 'package:my_data_app/src/days_counter/days_counter_page.dart';
import 'package:my_data_app/src/profile/profile_page.dart';
import 'package:my_data_app/src/dashboard/dashboard_settings_cubit.dart';
import 'package:my_data_app/src/theme/theme_cubit.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  static const _categoryIds = {
    'Finance': ['bills', 'chits', 'loans', 'home', 'money_owe', 'interest'],
    'Lifestyle': ['schedules', 'food_menu', 'checklists', 'goals', 'activities', 'diet', 'days_counter'],
    'Health': ['periods', 'medical'],
    'Personal': ['vehicles', 'vault', 'land'],
  };

  static final _categoryMeta = {
    'Finance': (Icons.account_balance_wallet_rounded, Colors.green),
    'Lifestyle': (Icons.self_improvement_rounded, Colors.blue),
    'Health': (Icons.health_and_safety_rounded, Colors.red),
    'Personal': (Icons.person_rounded, Colors.purple),
  };

  String _getSubtitle(String id) {
    switch (id) {
      case 'bills': return 'Bills & recurring tasks';
      case 'vehicles': return 'Vehicles & expenses';
      case 'chits': return 'Chit groups & auctions';
      case 'checklists': return 'Tasks with deadlines';
      case 'periods': return 'Cycles & predictions';
      case 'home': return 'Daily expenses';
      case 'schedules': return 'Events & appointments';
      case 'food_menu': return 'Weekly meal plan';
      case 'loans': return 'Loans & repayments';
      case 'goals': return 'Track habits & goals';
      case 'money_owe': return 'Lend & borrow tracker';
      case 'medical': return 'Medical records & health';
      case 'vault': return 'Personal details & documents';
      case 'land': return 'Land & property details';
      case 'interest': return 'Interest-bearing money';
      case 'activities': return 'Trips, certificates, milestones';
      case 'diet': return 'Food items & consumption';
      case 'days_counter': return 'Birthdays, anniversaries, countdowns';
      default: return '';
    }
  }

  int _getCount(String id, billState, vehicleState, chitState, checklistState, periodState, homeRecordState, scheduleState, foodMenuState, loanState, goalState, moneyOweState, medicalState, vaultState, landState, interestState, activityState, dietState, daysCounterState) {
    switch (id) {
      case 'bills': return billState.tasks.length;
      case 'vehicles': return vehicleState.vehicles.length;
      case 'chits': return chitState.chitFunds.length;
      case 'checklists': return checklistState.checklists.length;
      case 'periods': return periodState.entries.length;
      case 'home':
        final now = DateTime.now();
        return homeRecordState.records
            .where((r) => r.date.year == now.year && r.date.month == now.month)
            .length;
      case 'schedules': return scheduleState.entries.length;
      case 'food_menu': return foodMenuState.entries.length;
      case 'loans': return loanState.loans.length;
      case 'goals': return goalState.goals.length;
      case 'money_owe': return moneyOweState.entries.length;
      case 'medical': return medicalState.records.length + medicalState.members.length;
      case 'vault': return vaultState.entries.length;
      case 'land': return landState.records.length;
      case 'interest': return interestState.records.length;
      case 'activities': return activityState.records.length;
      case 'diet':
        final now = DateTime.now();
        return dietState.entries
            .where((e) => e.date.year == now.year && e.date.month == now.month)
            .length;
      case 'days_counter':
        return (daysCounterState.events as List).length;
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
      case 'loans':
        page = BlocProvider.value(
          value: context.read<LoanCubit>(),
          child: const LoanListPage(),
        );
        break;
      case 'goals':
        page = BlocProvider.value(
          value: context.read<GoalCubit>(),
          child: const GoalListPage(),
        );
        break;
      case 'money_owe':
        page = BlocProvider.value(
          value: context.read<MoneyOweCubit>(),
          child: const MoneyOwePage(),
        );
        break;
      case 'medical':
        page = BlocProvider.value(
          value: context.read<MedicalCubit>(),
          child: const MedicalHomePage(),
        );
        break;
      case 'vault':
        page = BlocProvider.value(
          value: context.read<ProfileVaultCubit>(),
          child: const ProfileVaultHomePage(),
        );
        break;
      case 'land':
        page = BlocProvider.value(
          value: context.read<LandCubit>(),
          child: const LandListPage(),
        );
        break;
      case 'interest':
        page = BlocProvider.value(
          value: context.read<InterestCubit>(),
          child: const InterestListPage(),
        );
        break;
      case 'activities':
        page = BlocProvider.value(
          value: context.read<ActivityCubit>(),
          child: const ActivityPage(),
        );
        break;
      case 'diet':
        page = BlocProvider.value(
          value: context.read<DietCubit>(),
          child: const DietPage(),
        );
        break;
      case 'days_counter':
        page = BlocProvider.value(
          value: context.read<DaysCounterCubit>(),
          child: const DaysCounterPage(),
        );
        break;
      default:
        return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  Widget _buildListView(BuildContext context, List<FeatureItem> visibleFeatures,
      billState, vehicleState, chitState, checklistState, periodState,
      homeRecordState, scheduleState, foodMenuState, loanState, goalState, moneyOweState, medicalState, vaultState, landState, interestState, activityState, dietState, daysCounterState) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: _categoryIds.entries.map((catEntry) {
        final categoryName = catEntry.key;
        final featureIds = catEntry.value;
        final categoryFeatures = visibleFeatures
            .where((f) => featureIds.contains(f.id))
            .toList();
        if (categoryFeatures.isEmpty) return const SizedBox.shrink();
        final meta = _categoryMeta[categoryName]!;
        final cs = Theme.of(context).colorScheme;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Column(
            children: [
              _SectionHeader(
                title: categoryName,
                icon: meta.$1,
                color: meta.$2,
                count: categoryFeatures.length,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: Column(
                  children: categoryFeatures.map((f) {
                    final count = _getCount(f.id, billState, vehicleState,
                        chitState, checklistState, periodState,
                        homeRecordState, scheduleState, foodMenuState,
                        loanState, goalState, moneyOweState, medicalState, vaultState, landState, interestState, activityState, dietState, daysCounterState);
                    return _FeatureRow(
                      icon: f.icon,
                      title: f.title,
                      subtitle: _getSubtitle(f.id),
                      count: count,
                      color: f.gradient[0],
                      onTap: () => _navigateToFeature(context, f.id),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGridView(BuildContext context, List<FeatureItem> visibleFeatures,
      billState, vehicleState, chitState, checklistState, periodState,
      homeRecordState, scheduleState, foodMenuState, loanState, goalState, moneyOweState, medicalState, vaultState, landState, interestState, activityState, dietState, daysCounterState) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final gridCols = width > 900 ? 6 : width > 600 ? 5 : 4;

        return ListView(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 32),
          children: _categoryIds.entries.map((catEntry) {
            final categoryName = catEntry.key;
            final featureIds = catEntry.value;
            final categoryFeatures = visibleFeatures
                .where((f) => featureIds.contains(f.id))
                .toList();
            if (categoryFeatures.isEmpty) return const SizedBox.shrink();
            final meta = _categoryMeta[categoryName]!;
            final cs = Theme.of(context).colorScheme;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Column(
                children: [
                  _SectionHeader(
                    title: categoryName,
                    icon: meta.$1,
                    color: meta.$2,
                    count: categoryFeatures.length,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
                    child: GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: gridCols,
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 6,
                      childAspectRatio: 0.85,
                      children: categoryFeatures.map((f) {
                        final count = _getCount(f.id, billState,
                            vehicleState, chitState, checklistState,
                            periodState, homeRecordState, scheduleState,
                            foodMenuState, loanState, goalState, moneyOweState, medicalState, vaultState, landState, interestState, activityState, dietState, daysCounterState);
                        return _FeatureGridCard(
                          icon: f.icon,
                          title: f.title,
                          count: count,
                          color: f.gradient[0],
                          onTap: () =>
                              _navigateToFeature(context, f.id),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
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
    final loanState = context.watch<LoanCubit>().state;
    final goalState = context.watch<GoalCubit>().state;
    final moneyOweState = context.watch<MoneyOweCubit>().state;
    final medicalState = context.watch<MedicalCubit>().state;
    final vaultState = context.watch<ProfileVaultCubit>().state;
    final landState = context.watch<LandCubit>().state;
    final interestState = context.watch<InterestCubit>().state;
    final activityState = context.watch<ActivityCubit>().state;
    final dietState = context.watch<DietCubit>().state;
    final daysCounterState = context.watch<DaysCounterCubit>().state;
    final dashSettings = context.watch<DashboardSettingsCubit>().state;
    final visibleFeatures = dashSettings.visibleFeatures;
    final isGrid = dashSettings.isGridView;

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
                  // Profile icon — tap to open profile page
                  GestureDetector(
                    onTap: () {
                      final authCubit = context.read<AuthCubit>();
                      final settingsCubit =
                          context.read<DashboardSettingsCubit>();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MultiBlocProvider(
                            providers: [
                              BlocProvider.value(value: authCubit),
                              BlocProvider.value(value: settingsCubit),
                            ],
                            child: const ProfilePage(),
                          ),
                        ),
                      );
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
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
                        if (context
                            .read<AuthCubit>()
                            .otherAccounts
                            .isNotEmpty)
                          Positioned(
                            bottom: -2,
                            right: -2,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.blue[600]!, width: 1.5),
                              ),
                              child: Icon(Icons.swap_horiz_rounded,
                                  size: 10, color: Colors.blue[600]),
                            ),
                          ),
                      ],
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
                  // Grid/List toggle
                  IconButton(
                    onPressed: () =>
                        context.read<DashboardSettingsCubit>().toggleViewMode(),
                    icon: Icon(
                      isGrid
                          ? Icons.view_list_rounded
                          : Icons.grid_view_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor:
                          Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Dark mode toggle
                  BlocBuilder<ThemeCubit, ThemeMode>(
                    builder: (context, themeMode) {
                      final isDark = themeMode == ThemeMode.dark;
                      return IconButton(
                        onPressed: () =>
                            context.read<ThemeCubit>().toggle(),
                        icon: Icon(
                          isDark
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor:
                              Colors.white.withValues(alpha: 0.2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Scrollable content
            Expanded(
              child: isGrid
                  ? _buildGridView(context, visibleFeatures, billState,
                      vehicleState, chitState, checklistState, periodState,
                      homeRecordState, scheduleState, foodMenuState, loanState, goalState, moneyOweState, medicalState, vaultState, landState, interestState, activityState, dietState, daysCounterState)
                  : _buildListView(context, visibleFeatures, billState,
                      vehicleState, chitState, checklistState, periodState,
                      homeRecordState, scheduleState, foodMenuState, loanState, goalState, moneyOweState, medicalState, vaultState, landState, interestState, activityState, dietState, daysCounterState),
            ),
          ],
        ),
      ),
    );
  }
}

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
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final int count;
  final Color color;
  final VoidCallback onTap;

  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.count,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (count > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded,
                  size: 20, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      );
  }
}

class _FeatureGridCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final int count;
  final Color color;
  final VoidCallback onTap;

  const _FeatureGridCard({
    required this.icon,
    required this.title,
    required this.count,
    required this.color,
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
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 26, color: color),
              ),
              if (count > 0)
                Positioned(
                  top: -4,
                  right: -6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        fontSize: 10,
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
            title,
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

