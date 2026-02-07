import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_data_app/src/reminder/repository/bill_repository.dart';
import 'package:my_data_app/src/reminder/cubit/bill_cubit.dart';
import 'package:my_data_app/src/vehicle/repository/vehicle_repository.dart';
import 'package:my_data_app/src/vehicle/cubit/vehicle_cubit.dart';
import 'package:my_data_app/src/chits/repository/chit_repository.dart';
import 'package:my_data_app/src/chits/cubit/chit_cubit.dart';
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
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _billRepo = FirestoreBillRepository(uid: widget.uid);
    _vehicleRepo = FirestoreVehicleRepository(uid: widget.uid);
    _chitRepo = FirestoreChitRepository(uid: widget.uid);
    _initRepos();
  }

  Future<void> _initRepos() async {
    await Future.wait([
      _billRepo.init(),
      _vehicleRepo.init(),
      _chitRepo.init(),
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
      ],
      child: const DashboardPage(),
    );
  }
}
