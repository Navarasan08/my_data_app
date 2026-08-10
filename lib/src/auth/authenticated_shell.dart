import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
import 'package:my_data_app/src/splash/branded_loader.dart';

class AuthenticatedShell extends StatefulWidget {
  final String uid;

  const AuthenticatedShell({super.key, required this.uid});

  @override
  State<AuthenticatedShell> createState() => _AuthenticatedShellState();
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
  ReminderSweeper? _reminderSweeper;
  late final DashboardSettingsCubit _dashboardSettingsCubit;
  late final GroupSettingsCubit _groupSettingsCubit;
  bool _initialized = false;
  bool _cubitsCreated = false;

  @override
  void initState() {
    super.initState();
    _billRepo = FirestoreBillRepository(uid: widget.uid);
    _vehicleRepo = FirestoreVehicleRepository(uid: widget.uid);
    _chitRepo = FirestoreChitRepository(uid: widget.uid);
    _checklistRepo = FirestoreChecklistRepository(uid: widget.uid);
    _periodRepo = FirestorePeriodRepository(uid: widget.uid);
    _homeRecordRepo = FirestoreHomeRecordRepository(uid: widget.uid);
    _scheduleRepo = FirestoreScheduleRepository(uid: widget.uid);
    _foodMenuRepo = FirestoreFoodMenuRepository(uid: widget.uid);
    _loanRepo = FirestoreLoanRepository(uid: widget.uid);
    _goalRepo = FirestoreGoalRepository(uid: widget.uid);
    _moneyOweRepo = FirestoreMoneyOweRepository(uid: widget.uid);
    _medicalRepo = FirestoreMedicalRepository(uid: widget.uid);
    _vaultRepo = FirestoreProfileVaultRepository(uid: widget.uid);
    _landRepo = FirestoreLandRepository(uid: widget.uid);
    _eventRepo = FirestoreEventRepository(uid: widget.uid);
    final firebaseUser = FirebaseAuth.instance.currentUser;
    _groupRepo = FirestoreGroupRepository(
      uid: widget.uid,
      email: firebaseUser?.email ?? '',
      displayName: firebaseUser?.displayName,
    );
    _interestRepo = FirestoreInterestRepository(uid: widget.uid);
    _activityRepo = FirestoreActivityRepository(uid: widget.uid);
    _dietRepo = FirestoreDietRepository(uid: widget.uid);
    _daysCounterRepo = FirestoreDaysCounterRepository(uid: widget.uid);
    _notificationRepo = FirestoreNotificationRepository(uid: widget.uid);
    _notificationService = LocalNotificationService();
    _dashboardSettingsCubit = DashboardSettingsCubit(uid: widget.uid);
    _groupSettingsCubit = GroupSettingsCubit(uid: widget.uid);
    _initRepos();
  }

  @override
  void dispose() {
    _reminderSweeper?.stop();
    _groupRepo.dispose();
    if (_cubitsCreated) {
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
    }
    _dashboardSettingsCubit.close();
    _groupSettingsCubit.close();
    super.dispose();
  }

  String? _initError;

  Future<void> _initRepos() async {
    try {
      // Cache-first: each repo reads Firestore's local cache and only goes to
      // the network when the cache is empty (first launch on a device), so
      // this stays fast no matter how much data has accumulated.
      await Future.wait([
        _billRepo.init(),
        _vehicleRepo.init(),
        _chitRepo.init(),
        _checklistRepo.init(),
        _periodRepo.init(),
        _homeRecordRepo.init(),
        _scheduleRepo.init(),
        _foodMenuRepo.init(),
        _loanRepo.init(),
        _goalRepo.init(),
        _moneyOweRepo.init(),
        _medicalRepo.init(),
        _vaultRepo.init(),
        _landRepo.init(),
        _eventRepo.init(),
        _groupRepo.init(),
        _interestRepo.init(),
        _activityRepo.init(),
        _dietRepo.init(),
        _daysCounterRepo.init(),
        _notificationRepo.init(),
        _notificationService.init(),
        _dashboardSettingsCubit.load(),
        _groupSettingsCubit.load(),
      ]);
      // Build top-level cubits and start the reminder sweeper now that data
      // is loaded.
      _notificationCubit =
          NotificationCubit(_notificationRepo, _notificationService);
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
      _cubitsCreated = true;
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
      )..start();
      if (mounted) setState(() => _initialized = true);
      // What's on screen came from the local cache; now pull the latest from
      // the server in the background so edits made on other devices show up.
      unawaited(_refreshFromServer());
    } catch (e) {
      if (mounted) setState(() => _initError = e.toString());
    }
  }

  /// Re-reads every repo from the server and re-emits the fresh data through
  /// the cubits. Failures are ignored — the cached data already on screen
  /// simply stays until the next successful refresh.
  Future<void> _refreshFromServer() async {
    try {
      await Future.wait([
        _billRepo.refresh(),
        _vehicleRepo.refresh(),
        _chitRepo.refresh(),
        _checklistRepo.refresh(),
        _periodRepo.refresh(),
        _homeRecordRepo.refresh(),
        _scheduleRepo.refresh(),
        _foodMenuRepo.refresh(),
        _loanRepo.refresh(),
        _goalRepo.refresh(),
        _moneyOweRepo.refresh(),
        _medicalRepo.refresh(),
        _vaultRepo.refresh(),
        _landRepo.refresh(),
        _eventRepo.refresh(),
        _interestRepo.refresh(),
        _activityRepo.refresh(),
        _dietRepo.refresh(),
        _daysCounterRepo.refresh(),
        _notificationRepo.refresh(),
      ]);
    } catch (_) {
      return;
    }
    if (!mounted || !_cubitsCreated) return;
    _billCubit.reloadFromRepository();
    _vehicleCubit.reloadFromRepository();
    _chitCubit.reloadFromRepository();
    _checklistCubit.reloadFromRepository();
    _periodCubit.reloadFromRepository();
    _homeRecordCubit.reloadFromRepository();
    _scheduleCubit.reloadFromRepository();
    _foodMenuCubit.reloadFromRepository();
    _loanCubit.reloadFromRepository();
    _goalCubit.reloadFromRepository();
    _moneyOweCubit.reloadFromRepository();
    _medicalCubit.reloadFromRepository();
    _vaultCubit.reloadFromRepository();
    _landCubit.reloadFromRepository();
    _eventCubit.reloadFromRepository();
    _interestCubit.reloadFromRepository();
    _activityCubit.reloadFromRepository();
    _dietCubit.reloadFromRepository();
    _daysCounterCubit.reloadFromRepository();
    _notificationCubit.reloadFromRepository();
  }

  @override
  Widget build(BuildContext context) {
    if (_initError != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'Unable to connect',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please check your internet connection and try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _initError = null;
                      _initialized = false;
                    });
                    _initRepos();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_initialized) {
      return const BrandedLoader(message: 'Loading your data…');
    }

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
      child: MainShell(notificationService: _notificationService),
    );
  }
}
