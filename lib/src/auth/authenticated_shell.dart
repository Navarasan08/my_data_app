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
import 'package:my_data_app/src/dashboard_page.dart';

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
    _initRepos();
  }

  Future<void> _initRepos() async {
    await Future.wait([
      _billRepo.init(),
      _vehicleRepo.init(),
      _chitRepo.init(),
      _checklistRepo.init(),
      _periodRepo.init(),
      _homeRecordRepo.init(),
    ]);
    if (mounted) setState(() => _initialized = true);
  }

  @override
  Widget build(BuildContext context) {
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
      ],
      child: const DashboardPage(),
    );
  }
}
