import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_data_app/src/activities/activity_page.dart';
import 'package:my_data_app/src/activities/cubit/activity_cubit.dart';
import 'package:my_data_app/src/checklist/checklist_page.dart';
import 'package:my_data_app/src/checklist/cubit/checklist_cubit.dart';
import 'package:my_data_app/src/chits/chit_screen.dart';
import 'package:my_data_app/src/chits/cubit/chit_cubit.dart';
import 'package:my_data_app/src/dashboard/dashboard_settings_cubit.dart';
import 'package:my_data_app/src/days_counter/cubit/days_counter_cubit.dart';
import 'package:my_data_app/src/days_counter/days_counter_page.dart';
import 'package:my_data_app/src/diet/cubit/diet_cubit.dart';
import 'package:my_data_app/src/diet/diet_page.dart';
import 'package:my_data_app/src/events/cubit/event_cubit.dart';
import 'package:my_data_app/src/food_menu/cubit/food_menu_cubit.dart';
import 'package:my_data_app/src/food_menu/food_menu_page.dart';
import 'package:my_data_app/src/goals/cubit/goal_cubit.dart';
import 'package:my_data_app/src/goals/goal_page.dart';
import 'package:my_data_app/src/groups/cubit/group_cubit.dart';
import 'package:my_data_app/src/groups/cubit/group_settings_cubit.dart';
import 'package:my_data_app/src/home/cubit/home_record_cubit.dart';
import 'package:my_data_app/src/home/home_record_page.dart';
import 'package:my_data_app/src/interest/cubit/interest_cubit.dart';
import 'package:my_data_app/src/interest/interest_page.dart';
import 'package:my_data_app/src/land/cubit/land_cubit.dart';
import 'package:my_data_app/src/land/land_page.dart';
import 'package:my_data_app/src/loans/cubit/loan_cubit.dart';
import 'package:my_data_app/src/loans/loan_page.dart';
import 'package:my_data_app/src/medical/cubit/medical_cubit.dart';
import 'package:my_data_app/src/medical/medical_page.dart';
import 'package:my_data_app/src/money_owe/cubit/money_owe_cubit.dart';
import 'package:my_data_app/src/money_owe/money_owe_page.dart';
import 'package:my_data_app/src/monthly_stats/monthly_stats_page.dart';
import 'package:my_data_app/src/notifications/cubit/notification_cubit.dart';
import 'package:my_data_app/src/notifications/model/app_notification.dart';
import 'package:my_data_app/src/notifications/notifications_page.dart';
import 'package:my_data_app/src/periods/cubit/period_cubit.dart';
import 'package:my_data_app/src/periods/period_page.dart';
import 'package:my_data_app/src/pregnancy/cubit/pregnancy_cubit.dart';
import 'package:my_data_app/src/pregnancy/pregnancy_page.dart';
import 'package:my_data_app/src/profile_vault/cubit/profile_vault_cubit.dart';
import 'package:my_data_app/src/profile_vault/profile_vault_page.dart';
import 'package:my_data_app/src/quick_notes/cubit/quick_note_cubit.dart';
import 'package:my_data_app/src/reminder/cubit/bill_cubit.dart';
import 'package:my_data_app/src/reminder/reminder_page.dart';
import 'package:my_data_app/src/schedule/cubit/schedule_cubit.dart';
import 'package:my_data_app/src/schedule/schedule_detail_page.dart';
import 'package:my_data_app/src/schedule/schedule_page.dart';
import 'package:my_data_app/src/vehicle/cubit/vehicle_cubit.dart';
import 'package:my_data_app/src/vehicle/vehicle_manager_page.dart';

/// Re-provides every shell cubit to [child], for pages pushed onto the
/// Navigator from the drawer. Routes are built outside the shell's
/// MultiBlocProvider subtree, so without this a pushed page that reads a
/// cubit throws ProviderNotFoundException.
Widget withShellCubits(BuildContext context, Widget child) {
  return MultiBlocProvider(
    providers: [
      BlocProvider.value(value: context.read<BillCubit>()),
      BlocProvider.value(value: context.read<VehicleCubit>()),
      BlocProvider.value(value: context.read<ChitCubit>()),
      BlocProvider.value(value: context.read<ChecklistCubit>()),
      BlocProvider.value(value: context.read<PeriodCubit>()),
      BlocProvider.value(value: context.read<PregnancyCubit>()),
      BlocProvider.value(value: context.read<QuickNoteCubit>()),
      BlocProvider.value(value: context.read<HomeRecordCubit>()),
      BlocProvider.value(value: context.read<ScheduleCubit>()),
      BlocProvider.value(value: context.read<FoodMenuCubit>()),
      BlocProvider.value(value: context.read<LoanCubit>()),
      BlocProvider.value(value: context.read<GoalCubit>()),
      BlocProvider.value(value: context.read<MoneyOweCubit>()),
      BlocProvider.value(value: context.read<MedicalCubit>()),
      BlocProvider.value(value: context.read<ProfileVaultCubit>()),
      BlocProvider.value(value: context.read<LandCubit>()),
      BlocProvider.value(value: context.read<EventCubit>()),
      BlocProvider.value(value: context.read<GroupCubit>()),
      BlocProvider.value(value: context.read<InterestCubit>()),
      BlocProvider.value(value: context.read<ActivityCubit>()),
      BlocProvider.value(value: context.read<DietCubit>()),
      BlocProvider.value(value: context.read<DaysCounterCubit>()),
      BlocProvider.value(value: context.read<NotificationCubit>()),
      BlocProvider.value(value: context.read<DashboardSettingsCubit>()),
      BlocProvider.value(value: context.read<GroupSettingsCubit>()),
    ],
    child: child,
  );
}

/// Builds the page for a dashboard feature id, with the cubits it needs
/// re-provided from [context]. Shared by the dashboard tiles, the
/// configurable second bottom tab, and notification routing. Returns null
/// for an unknown id.
Widget? buildFeaturePage(BuildContext context, String id) {
  Widget withCubit<C extends StateStreamableSource<Object?>>(Widget page) =>
      BlocProvider.value(value: context.read<C>(), child: page);

  switch (id) {
    case 'monthly_stats':
      // The stats page tallies every finance module, and its rows push those
      // modules' pages, so all of their cubits (plus the expense tracker's
      // EventCubit) must be reachable from the pushed route's context.
      return MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<HomeRecordCubit>()),
          BlocProvider.value(value: context.read<EventCubit>()),
          BlocProvider.value(value: context.read<BillCubit>()),
          BlocProvider.value(value: context.read<LoanCubit>()),
          BlocProvider.value(value: context.read<MoneyOweCubit>()),
          BlocProvider.value(value: context.read<VehicleCubit>()),
          BlocProvider.value(value: context.read<ChitCubit>()),
          BlocProvider.value(value: context.read<InterestCubit>()),
        ],
        child: const MonthlyStatsPage(),
      );
    case 'bills':
      return withCubit<BillCubit>(const BillsPage());
    case 'vehicles':
      return withCubit<VehicleCubit>(const VehicleListPage());
    case 'chits':
      return withCubit<ChitCubit>(const ChitFundListPage());
    case 'checklists':
      return withCubit<ChecklistCubit>(const ChecklistListPage());
    case 'periods':
      return withCubit<PeriodCubit>(const PeriodTrackerPage());
    case 'pregnancy':
      return withCubit<PregnancyCubit>(const PregnancyPage());
    case 'home':
      // Provide EventCubit alongside HomeRecordCubit so records can be
      // linked to event/group funds and navigate to them.
      return MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<HomeRecordCubit>()),
          BlocProvider.value(value: context.read<EventCubit>()),
        ],
        child: const HomeRecordPage(),
      );
    case 'schedules':
      return withCubit<ScheduleCubit>(const SchedulePage());
    case 'food_menu':
      return withCubit<FoodMenuCubit>(const FoodMenuPage());
    case 'loans':
      return withCubit<LoanCubit>(const LoanListPage());
    case 'goals':
      return withCubit<GoalCubit>(const GoalListPage());
    case 'money_owe':
      return withCubit<MoneyOweCubit>(const MoneyOwePage());
    case 'medical':
      return withCubit<MedicalCubit>(const MedicalHomePage());
    case 'vault':
      return withCubit<ProfileVaultCubit>(const ProfileVaultHomePage());
    case 'land':
      return withCubit<LandCubit>(const LandListPage());
    case 'interest':
      return withCubit<InterestCubit>(const InterestListPage());
    case 'activities':
      return withCubit<ActivityCubit>(const ActivityPage());
    case 'diet':
      return withCubit<DietCubit>(const DietPage());
    case 'days_counter':
      return withCubit<DaysCounterCubit>(const DaysCounterPage());
    default:
      return null;
  }
}

/// The detail page a notification from [module] about [itemId] should open,
/// with its cubit re-provided. Falls back to the module's main page, or
/// null when the module is unknown.
Widget? buildNotificationTarget(
  BuildContext context,
  String module,
  String itemId,
) {
  switch (module) {
    case 'schedule':
      return BlocProvider.value(
        value: context.read<ScheduleCubit>(),
        child: ScheduleDetailPage(entryId: itemId),
      );
    case 'loans':
      return BlocProvider.value(
        value: context.read<LoanCubit>(),
        child: LoanDetailPage(loanId: itemId),
      );
    case 'chits':
      return BlocProvider.value(
        value: context.read<ChitCubit>(),
        child: ChitFundDetailsPage(chitFundId: itemId),
      );
    case 'checklists':
      return BlocProvider.value(
        value: context.read<ChecklistCubit>(),
        child: ChecklistDetailPage(groupId: itemId),
      );
    default:
      return buildFeaturePage(context, module);
  }
}

/// Opens the notification's target page; if the module has none, stays put.
void openNotification(BuildContext context, AppNotification n) {
  final page = buildNotificationTarget(context, n.sourceModule, n.sourceItemId);
  if (page == null) return;
  Navigator.push(context, MaterialPageRoute(builder: (_) => page));
}

/// The Alerts page as a pushed route (it used to be a tab), with every shell
/// cubit available to it and to the pages it opens.
Widget buildNotificationsRoute(BuildContext context) {
  return withShellCubits(
    context,
    Builder(
      builder: (ctx) =>
          NotificationsPage(onOpen: (n) => openNotification(ctx, n)),
    ),
  );
}
