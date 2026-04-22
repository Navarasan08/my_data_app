import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
import 'package:my_data_app/src/notifications/cubit/notification_cubit.dart';
import 'package:my_data_app/src/notifications/repository/notification_repository.dart';
import 'package:my_data_app/src/notifications/notification_service.dart';
import 'package:my_data_app/src/notifications/reminder_sweeper.dart';
import 'package:my_data_app/src/schedule/schedule_reminder_source.dart';
import 'package:my_data_app/src/dashboard/dashboard_settings_cubit.dart';
import 'package:my_data_app/src/shell/main_shell.dart';

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
  late final FirestoreNotificationRepository _notificationRepo;
  late final LocalNotificationService _notificationService;
  late final NotificationCubit _notificationCubit;
  late final ScheduleCubit _scheduleCubit;
  ReminderSweeper? _reminderSweeper;
  late final DashboardSettingsCubit _dashboardSettingsCubit;
  bool _initialized = false;

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
    _notificationRepo = FirestoreNotificationRepository(uid: widget.uid);
    _notificationService = LocalNotificationService();
    _dashboardSettingsCubit = DashboardSettingsCubit(uid: widget.uid);
    _initRepos();
  }

  @override
  void dispose() {
    _reminderSweeper?.stop();
    super.dispose();
  }

  String? _initError;

  Future<void> _initRepos() async {
    try {
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
        _notificationRepo.init(),
        _notificationService.init(),
        _dashboardSettingsCubit.load(),
      ]);
      // Build top-level cubits and start the reminder sweeper now that data
      // is loaded.
      _notificationCubit =
          NotificationCubit(_notificationRepo, _notificationService);
      _scheduleCubit = ScheduleCubit(_scheduleRepo);
      // Generic reminder pipeline. Add new modules by appending another
      // ReminderSource to the `sources` list — no other wiring needed.
      _reminderSweeper = ReminderSweeper(
        notificationCubit: _notificationCubit,
        sources: [
          ScheduleReminderSource(scheduleCubit: _scheduleCubit),
        ],
      )..start();
      if (mounted) setState(() => _initialized = true);
    } catch (e) {
      if (mounted) setState(() => _initError = e.toString());
    }
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => BillCubit(_billRepo)),
        BlocProvider(create: (_) => VehicleCubit(_vehicleRepo)),
        BlocProvider(create: (_) => ChitCubit(_chitRepo)),
        BlocProvider(create: (_) => ChecklistCubit(_checklistRepo)),
        BlocProvider(create: (_) => PeriodCubit(_periodRepo)),
        BlocProvider(create: (_) => HomeRecordCubit(_homeRecordRepo)),
        BlocProvider.value(value: _scheduleCubit),
        BlocProvider(create: (_) => FoodMenuCubit(_foodMenuRepo)),
        BlocProvider(create: (_) => LoanCubit(_loanRepo)),
        BlocProvider(create: (_) => GoalCubit(_goalRepo)),
        BlocProvider(create: (_) => MoneyOweCubit(_moneyOweRepo)),
        BlocProvider(create: (_) => MedicalCubit(_medicalRepo)),
        BlocProvider(create: (_) => ProfileVaultCubit(_vaultRepo)),
        BlocProvider(create: (_) => LandCubit(_landRepo)),
        BlocProvider(create: (_) => EventCubit(_eventRepo)),
        BlocProvider.value(value: _notificationCubit),
        BlocProvider.value(value: _dashboardSettingsCubit),
      ],
      child: MainShell(notificationService: _notificationService),
    );
  }
}
