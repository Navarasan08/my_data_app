import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_data_app/src/activities/cubit/activity_cubit.dart';
import 'package:my_data_app/src/auth/cubit/auth_cubit.dart';
import 'package:my_data_app/src/auth/cubit/auth_state.dart';
import 'package:my_data_app/src/theme/theme_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_data_app/src/activities/repository/activity_repository.dart';
import 'package:my_data_app/src/checklist/cubit/checklist_cubit.dart';
import 'package:my_data_app/src/checklist/repository/checklist_repository.dart';
import 'package:my_data_app/src/chits/cubit/chit_cubit.dart';
import 'package:my_data_app/src/chits/repository/chit_repository.dart';
import 'package:my_data_app/src/dashboard/dashboard_settings_cubit.dart';
import 'package:my_data_app/src/dashboard_page.dart';
import 'package:my_data_app/src/days_counter/cubit/days_counter_cubit.dart';
import 'package:my_data_app/src/days_counter/repository/days_counter_repository.dart';
import 'package:my_data_app/src/diet/cubit/diet_cubit.dart';
import 'package:my_data_app/src/diet/repository/diet_repository.dart';
import 'package:my_data_app/src/events/cubit/event_cubit.dart';
import 'package:my_data_app/src/events/repository/event_repository.dart';
import 'package:my_data_app/src/food_menu/cubit/food_menu_cubit.dart';
import 'package:my_data_app/src/food_menu/repository/food_menu_repository.dart';
import 'package:my_data_app/src/goals/cubit/goal_cubit.dart';
import 'package:my_data_app/src/goals/repository/goal_repository.dart';
import 'package:my_data_app/src/home/cubit/home_record_cubit.dart';
import 'package:my_data_app/src/home/repository/home_record_repository.dart';
import 'package:my_data_app/src/interest/cubit/interest_cubit.dart';
import 'package:my_data_app/src/interest/repository/interest_repository.dart';
import 'package:my_data_app/src/land/cubit/land_cubit.dart';
import 'package:my_data_app/src/land/repository/land_repository.dart';
import 'package:my_data_app/src/loans/cubit/loan_cubit.dart';
import 'package:my_data_app/src/loans/repository/loan_repository.dart';
import 'package:my_data_app/src/medical/cubit/medical_cubit.dart';
import 'package:my_data_app/src/medical/repository/medical_repository.dart';
import 'package:my_data_app/src/money_owe/cubit/money_owe_cubit.dart';
import 'package:my_data_app/src/money_owe/repository/money_owe_repository.dart';
import 'package:my_data_app/src/periods/cubit/period_cubit.dart';
import 'package:my_data_app/src/periods/repository/period_repository.dart';
import 'package:my_data_app/src/profile_vault/cubit/profile_vault_cubit.dart';
import 'package:my_data_app/src/profile_vault/repository/profile_vault_repository.dart';
import 'package:my_data_app/src/reminder/cubit/bill_cubit.dart';
import 'package:my_data_app/src/reminder/repository/bill_repository.dart';
import 'package:my_data_app/src/schedule/cubit/schedule_cubit.dart';
import 'package:my_data_app/src/schedule/repository/schedule_repository.dart';
import 'package:my_data_app/src/vehicle/cubit/vehicle_cubit.dart';
import 'package:my_data_app/src/vehicle/repository/vehicle_repository.dart';

/// Boots every module cubit over one in-memory Firestore and renders the
/// dashboard, the way the authenticated shell does. Catches wiring
/// regressions (a cubit the dashboard watches but nobody provides) and
/// proves the first frame renders before any data has arrived.
/// Stands in for the Firebase-backed AuthCubit; the dashboard header only
/// reads `state`.
class _FakeAuthCubit extends Cubit<AuthState> implements AuthCubit {
  _FakeAuthCubit() : super(const AuthState(status: AuthStatus.authenticated));

  @override
  List<SavedAccount> get otherAccounts => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('DashboardPage renders with every module cubit provided', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    // The test font (Ahem) is taller than the real one, so the feature tiles
    // overflow by a few pixels here and nowhere else. Ignore just that.
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('overflowed by')) return;
      originalOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = originalOnError);
    // Phone-sized surface so the dashboard's column has room to lay out.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fs = FakeFirebaseFirestore();
    const uid = 'u1';

    final billRepo = FirestoreBillRepository(uid: uid, firestore: fs)..start();
    final vehicleRepo = FirestoreVehicleRepository(uid: uid, firestore: fs)
      ..start();
    final chitRepo = FirestoreChitRepository(uid: uid, firestore: fs)..start();
    final checklistRepo = FirestoreChecklistRepository(uid: uid, firestore: fs)
      ..start();
    final periodRepo = FirestorePeriodRepository(uid: uid, firestore: fs)
      ..start();
    final homeRepo = FirestoreHomeRecordRepository(uid: uid, firestore: fs)
      ..start();
    final scheduleRepo = FirestoreScheduleRepository(uid: uid, firestore: fs)
      ..start();
    final foodMenuRepo = FirestoreFoodMenuRepository(uid: uid, firestore: fs)
      ..start();
    final loanRepo = FirestoreLoanRepository(uid: uid, firestore: fs)..start();
    final goalRepo = FirestoreGoalRepository(uid: uid, firestore: fs)..start();
    final moneyOweRepo = FirestoreMoneyOweRepository(uid: uid, firestore: fs)
      ..start();
    final medicalRepo = FirestoreMedicalRepository(uid: uid, firestore: fs)
      ..start();
    final vaultRepo = FirestoreProfileVaultRepository(uid: uid, firestore: fs)
      ..start();
    final landRepo = FirestoreLandRepository(uid: uid, firestore: fs)..start();
    final eventRepo = FirestoreEventRepository(uid: uid, firestore: fs)
      ..start();
    final interestRepo = FirestoreInterestRepository(uid: uid, firestore: fs)
      ..start();
    final activityRepo = FirestoreActivityRepository(uid: uid, firestore: fs)
      ..start();
    final dietRepo = FirestoreDietRepository(uid: uid, firestore: fs)..start();
    final daysCounterRepo = FirestoreDaysCounterRepository(
      uid: uid,
      firestore: fs,
    )..start();

    final dashboardSettings = DashboardSettingsCubit(uid: uid, firestore: fs)
      ..start();

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => BillCubit(billRepo)),
          BlocProvider(create: (_) => VehicleCubit(vehicleRepo)),
          BlocProvider(create: (_) => ChitCubit(chitRepo)),
          BlocProvider(create: (_) => ChecklistCubit(checklistRepo)),
          BlocProvider(create: (_) => PeriodCubit(periodRepo)),
          BlocProvider(create: (_) => HomeRecordCubit(homeRepo)),
          BlocProvider(create: (_) => ScheduleCubit(scheduleRepo)),
          BlocProvider(create: (_) => FoodMenuCubit(foodMenuRepo)),
          BlocProvider(create: (_) => LoanCubit(loanRepo)),
          BlocProvider(create: (_) => GoalCubit(goalRepo)),
          BlocProvider(create: (_) => MoneyOweCubit(moneyOweRepo)),
          BlocProvider(create: (_) => MedicalCubit(medicalRepo)),
          BlocProvider(create: (_) => ProfileVaultCubit(vaultRepo)),
          BlocProvider(create: (_) => LandCubit(landRepo)),
          BlocProvider(create: (_) => EventCubit(eventRepo)),
          BlocProvider(create: (_) => InterestCubit(interestRepo)),
          BlocProvider(create: (_) => ActivityCubit(activityRepo)),
          BlocProvider(create: (_) => DietCubit(dietRepo)),
          BlocProvider(create: (_) => DaysCounterCubit(daysCounterRepo)),
          BlocProvider.value(value: dashboardSettings),
          BlocProvider<AuthCubit>(create: (_) => _FakeAuthCubit()),
          BlocProvider(create: (_) => ThemeCubit()),
        ],
        child: const MaterialApp(home: DashboardPage()),
      ),
    );

    // First frame: nothing has loaded yet and the page must still render.
    expect(find.byType(DashboardPage), findsOneWidget);
    expect(find.text('Expense Tracker'), findsOneWidget);

    // Let every listener deliver its (empty, live) snapshot and rebuild.
    await tester.pumpAndSettle();
    expect(find.byType(DashboardPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
