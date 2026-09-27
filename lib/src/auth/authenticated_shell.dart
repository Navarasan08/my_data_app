import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_data_app/src/core/sync/sync_node.dart';
import 'package:my_data_app/src/core/sync/sync_snapshot.dart';
import 'package:my_data_app/src/groups/cubit/group_cubit.dart';
import 'package:my_data_app/src/groups/cubit/group_settings_cubit.dart';
import 'package:my_data_app/src/groups/repository/group_repository.dart';
import 'package:my_data_app/src/reminder/repository/bill_repository.dart';
import 'package:my_data_app/src/reminder/cubit/bill_cubit.dart';
import 'package:my_data_app/src/vehicle/repository/vehicle_repository.dart';
import 'package:my_data_app/src/vehicle/cubit/vehicle_cubit.dart';
import 'package:my_data_app/src/chits/repository/chit_repository.dart';
import 'package:my_data_app/src/chits/cubit/chit_cubit.dart';
import 'package:my_data_app/src/checklist/repository/checklist_repository.dart';
import 'package:my_data_app/src/checklist/cubit/checklist_cubit.dart';
import 'package:my_data_app/src/periods/repository/period_repository.dart';
import 'package:my_data_app/src/periods/cubit/period_cubit.dart';
import 'package:my_data_app/src/home/repository/home_record_repository.dart';
import 'package:my_data_app/src/home/cubit/home_record_cubit.dart';
import 'package:my_data_app/src/schedule/repository/schedule_repository.dart';
import 'package:my_data_app/src/schedule/cubit/schedule_cubit.dart';
import 'package:my_data_app/src/food_menu/repository/food_menu_repository.dart';
import 'package:my_data_app/src/food_menu/cubit/food_menu_cubit.dart';
import 'package:my_data_app/src/loans/repository/loan_repository.dart';
import 'package:my_data_app/src/loans/cubit/loan_cubit.dart';
import 'package:my_data_app/src/goals/repository/goal_repository.dart';
import 'package:my_data_app/src/goals/cubit/goal_cubit.dart';
import 'package:my_data_app/src/money_owe/repository/money_owe_repository.dart';
import 'package:my_data_app/src/money_owe/cubit/money_owe_cubit.dart';
import 'package:my_data_app/src/medical/cubit/medical_cubit.dart';
import 'package:my_data_app/src/medical/repository/medical_repository.dart';
import 'package:my_data_app/src/profile_vault/cubit/profile_vault_cubit.dart';
import 'package:my_data_app/src/profile_vault/repository/profile_vault_repository.dart';
import 'package:my_data_app/src/land/cubit/land_cubit.dart';
import 'package:my_data_app/src/land/repository/land_repository.dart';
import 'package:my_data_app/src/events/cubit/event_cubit.dart';
import 'package:my_data_app/src/events/repository/event_repository.dart';
import 'package:my_data_app/src/interest/cubit/interest_cubit.dart';
import 'package:my_data_app/src/interest/repository/interest_repository.dart';
import 'package:my_data_app/src/activities/cubit/activity_cubit.dart';
import 'package:my_data_app/src/activities/repository/activity_repository.dart';
import 'package:my_data_app/src/diet/cubit/diet_cubit.dart';
import 'package:my_data_app/src/diet/repository/diet_repository.dart';
import 'package:my_data_app/src/days_counter/cubit/days_counter_cubit.dart';
import 'package:my_data_app/src/days_counter/repository/days_counter_repository.dart';
import 'package:my_data_app/src/notifications/cubit/notification_cubit.dart';
import 'package:my_data_app/src/notifications/repository/notification_repository.dart';
import 'package:my_data_app/src/notifications/notification_service.dart';
import 'package:my_data_app/src/notifications/reminder_sweeper.dart';
import 'package:my_data_app/src/schedule/schedule_reminder_source.dart';
import 'package:my_data_app/src/loans/loan_reminder_source.dart';
import 'package:my_data_app/src/chits/chit_reminder_source.dart';
import 'package:my_data_app/src/checklist/checklist_reminder_source.dart';
import 'package:my_data_app/src/dashboard/dashboard_settings_cubit.dart';
import 'package:my_data_app/src/shell/main_shell.dart';

/// Owns every module's repository and cubit for the signed-in user.
///
/// Nothing here waits on the network. Each repository attaches a Firestore
/// listener the moment it is created: the local cache renders on the first
/// frame and server changes (including edits from other devices) stream in
/// as they arrive. The only awaited work is platform setup for local
/// notifications, and that runs in the background.
class AuthenticatedShell extends StatefulWidget {
  final String uid;

  const AuthenticatedShell({super.key, required this.uid});

  @override
  State<AuthenticatedShell> createState() => _AuthenticatedShellState();
}

/// All module repositories as one node: one `start()`, one `dispose()`, and
/// a combined sync status for the global activity bar.
class _RepoBundle extends CompositeSyncNode {
  _RepoBundle(super.nodes);
}

class _AuthenticatedShellState extends State<AuthenticatedShell> {
  late final FirestoreBillRepository _billRepo;
  late final FirestoreVehicleRepository _vehicleRepo;
  late final FirestoreChitRepository _chitRepo;
  late final FirestoreChecklistRepository _checklistRepo;
  late final FirestorePeriodRepository _periodRepo;
  late final FirestoreHomeRecordRepository _homeRecordRepo;
  late final FirestoreScheduleRepository _scheduleRepo;
  late final FirestoreFoodMenuRepository _foodMenuRepo;
  late final FirestoreLoanRepository _loanRepo;
  late final FirestoreGoalRepository _goalRepo;
  late final FirestoreMoneyOweRepository _moneyOweRepo;
  late final FirestoreMedicalRepository _medicalRepo;
  late final FirestoreProfileVaultRepository _vaultRepo;
  late final FirestoreLandRepository _landRepo;
  late final FirestoreEventRepository _eventRepo;
  late final FirestoreGroupRepository _groupRepo;
  late final FirestoreInterestRepository _interestRepo;
  late final FirestoreActivityRepository _activityRepo;
  late final FirestoreDietRepository _dietRepo;
  late final FirestoreDaysCounterRepository _daysCounterRepo;
  late final FirestoreNotificationRepository _notificationRepo;
  late final LocalNotificationService _notificationService;
  late final NotificationCubit _notificationCubit;
  late final BillCubit _billCubit;
  late final VehicleCubit _vehicleCubit;
  late final ScheduleCubit _scheduleCubit;
  late final LoanCubit _loanCubit;
  late final ChitCubit _chitCubit;
  late final ChecklistCubit _checklistCubit;
  late final PeriodCubit _periodCubit;
  late final HomeRecordCubit _homeRecordCubit;
  late final FoodMenuCubit _foodMenuCubit;
  late final GoalCubit _goalCubit;
  late final MoneyOweCubit _moneyOweCubit;
  late final MedicalCubit _medicalCubit;
  late final ProfileVaultCubit _vaultCubit;
  late final LandCubit _landCubit;
  late final EventCubit _eventCubit;
  late final InterestCubit _interestCubit;
  late final ActivityCubit _activityCubit;
  late final DietCubit _dietCubit;
  late final DaysCounterCubit _daysCounterCubit;
  late final ReminderSweeper _reminderSweeper;
  late final DashboardSettingsCubit _dashboardSettingsCubit;
  late final GroupSettingsCubit _groupSettingsCubit;

  late final _RepoBundle _repos;
  final _syncStatus = ValueNotifier<SyncStatus>(SyncStatus.loading);
  StreamSubscription<void>? _syncSub;

  @override
  void initState() {
    super.initState();
    final uid = widget.uid;

    _billRepo = FirestoreBillRepository(uid: uid);
    _vehicleRepo = FirestoreVehicleRepository(uid: uid);
    _chitRepo = FirestoreChitRepository(uid: uid);
    _checklistRepo = FirestoreChecklistRepository(uid: uid);
    _periodRepo = FirestorePeriodRepository(uid: uid);
    _homeRecordRepo = FirestoreHomeRecordRepository(uid: uid);
    _scheduleRepo = FirestoreScheduleRepository(uid: uid);
    _foodMenuRepo = FirestoreFoodMenuRepository(uid: uid);
    _loanRepo = FirestoreLoanRepository(uid: uid);
    _goalRepo = FirestoreGoalRepository(uid: uid);
    _moneyOweRepo = FirestoreMoneyOweRepository(uid: uid);
    _medicalRepo = FirestoreMedicalRepository(uid: uid);
    _vaultRepo = FirestoreProfileVaultRepository(uid: uid);
    _landRepo = FirestoreLandRepository(uid: uid);
    _eventRepo = FirestoreEventRepository(uid: uid);
    _interestRepo = FirestoreInterestRepository(uid: uid);
    _activityRepo = FirestoreActivityRepository(uid: uid);
    _dietRepo = FirestoreDietRepository(uid: uid);
    _daysCounterRepo = FirestoreDaysCounterRepository(uid: uid);
    _notificationRepo = FirestoreNotificationRepository(uid: uid);

    final firebaseUser = FirebaseAuth.instance.currentUser;
    _groupRepo = FirestoreGroupRepository(
      uid: uid,
      email: firebaseUser?.email ?? '',
      displayName: firebaseUser?.displayName,
    );
    _notificationService = LocalNotificationService();
    _dashboardSettingsCubit = DashboardSettingsCubit(uid: uid)..start();
    _groupSettingsCubit = GroupSettingsCubit(uid: uid)..start();

    // Order matters: Firestore serves listener registrations in sequence,
    // so the largest, most-visited collection (expense records) goes first
    // and gets the earliest snapshot instead of queueing behind 19 others.
    _repos = _RepoBundle([
      _homeRecordRepo,
      _billRepo,
      _vehicleRepo,
      _chitRepo,
      _checklistRepo,
      _periodRepo,
      _scheduleRepo,
      _foodMenuRepo,
      _loanRepo,
      _goalRepo,
      _moneyOweRepo,
      _medicalRepo,
      _vaultRepo,
      _landRepo,
      _eventRepo,
      _interestRepo,
      _activityRepo,
      _dietRepo,
      _daysCounterRepo,
      _notificationRepo,
    ]);
    _syncSub = _repos.changes.listen((_) {
      final s = _repos.syncStatus;
      if (_syncStatus.value != s) _syncStatus.value = s;
    });
    _repos.start();

    _notificationCubit = NotificationCubit(
      _notificationRepo,
      _notificationService,
    );
    _billCubit = BillCubit(_billRepo);
    _vehicleCubit = VehicleCubit(_vehicleRepo);
    _scheduleCubit = ScheduleCubit(_scheduleRepo);
    _loanCubit = LoanCubit(_loanRepo);
    _chitCubit = ChitCubit(_chitRepo);
    _checklistCubit = ChecklistCubit(_checklistRepo);
    _periodCubit = PeriodCubit(_periodRepo);
    _homeRecordCubit = HomeRecordCubit(_homeRecordRepo);
    _foodMenuCubit = FoodMenuCubit(_foodMenuRepo);
    _goalCubit = GoalCubit(_goalRepo);
    _moneyOweCubit = MoneyOweCubit(_moneyOweRepo);
    _medicalCubit = MedicalCubit(_medicalRepo);
    _vaultCubit = ProfileVaultCubit(_vaultRepo);
    _landCubit = LandCubit(_landRepo);
    _eventCubit = EventCubit(_eventRepo);
    _interestCubit = InterestCubit(_interestRepo);
    _activityCubit = ActivityCubit(_activityRepo);
    _dietCubit = DietCubit(_dietRepo);
    _daysCounterCubit = DaysCounterCubit(_daysCounterRepo);

    // Generic reminder pipeline. Add new modules by appending another
    // ReminderSource to the `sources` list — no other wiring needed.
    _reminderSweeper = ReminderSweeper(
      notificationCubit: _notificationCubit,
      sources: [
        ScheduleReminderSource(scheduleCubit: _scheduleCubit),
        LoanReminderSource(cubit: _loanCubit),
        ChitReminderSource(cubit: _chitCubit),
        ChecklistReminderSource(cubit: _checklistCubit),
      ],
    );

    unawaited(_initServices());
  }

  /// Background setup that must not hold up the first frame.
  Future<void> _initServices() async {
    // Groups attach their own listeners inside init() and then do a first
    // server read; a failure there (offline first launch) is not fatal — the
    // listeners still deliver once the connection is back.
    unawaited(
      _groupRepo.init().catchError((Object e) {
        if (kDebugMode) debugPrint('groups init failed: $e');
      }),
    );
    // The reminder sweeper posts OS notifications, so the platform plugin
    // must be ready before it runs.
    try {
      await _notificationService.init();
    } catch (e) {
      if (kDebugMode) debugPrint('notification service init failed: $e');
    }
    if (mounted) _reminderSweeper.start();
  }

  @override
  void dispose() {
    _reminderSweeper.stop();
    _syncSub?.cancel();
    _syncStatus.dispose();
    _groupRepo.dispose();
    _billCubit.close();
    _vehicleCubit.close();
    _chitCubit.close();
    _checklistCubit.close();
    _periodCubit.close();
    _homeRecordCubit.close();
    _scheduleCubit.close();
    _foodMenuCubit.close();
    _loanCubit.close();
    _goalCubit.close();
    _moneyOweCubit.close();
    _medicalCubit.close();
    _vaultCubit.close();
    _landCubit.close();
    _eventCubit.close();
    _interestCubit.close();
    _activityCubit.close();
    _dietCubit.close();
    _daysCounterCubit.close();
    _notificationCubit.close();
    _dashboardSettingsCubit.close();
    _groupSettingsCubit.close();
    _repos.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _billCubit),
        BlocProvider.value(value: _vehicleCubit),
        BlocProvider.value(value: _chitCubit),
        BlocProvider.value(value: _checklistCubit),
        BlocProvider.value(value: _periodCubit),
        BlocProvider.value(value: _homeRecordCubit),
        BlocProvider.value(value: _scheduleCubit),
        BlocProvider.value(value: _foodMenuCubit),
        BlocProvider.value(value: _loanCubit),
        BlocProvider.value(value: _goalCubit),
        BlocProvider.value(value: _moneyOweCubit),
        BlocProvider.value(value: _medicalCubit),
        BlocProvider.value(value: _vaultCubit),
        BlocProvider.value(value: _landCubit),
        BlocProvider.value(value: _eventCubit),
        BlocProvider(
          create: (_) => GroupCubit(_groupRepo, currentUid: widget.uid),
        ),
        BlocProvider.value(value: _interestCubit),
        BlocProvider.value(value: _activityCubit),
        BlocProvider.value(value: _dietCubit),
        BlocProvider.value(value: _daysCounterCubit),
        BlocProvider.value(value: _notificationCubit),
        BlocProvider.value(value: _dashboardSettingsCubit),
        BlocProvider.value(value: _groupSettingsCubit),
      ],
      child: MainShell(
        notificationService: _notificationService,
        syncStatus: _syncStatus,
      ),
    );
  }
}
