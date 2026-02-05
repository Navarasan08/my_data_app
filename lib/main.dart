import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_data_app/firebase_options.dart';
import 'package:my_data_app/src/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:my_data_app/src/reminder/repository/bill_repository.dart';
import 'package:my_data_app/src/reminder/cubit/bill_cubit.dart';
import 'package:my_data_app/src/vehicle/repository/vehicle_repository.dart';
import 'package:my_data_app/src/vehicle/cubit/vehicle_cubit.dart';
import 'package:my_data_app/src/chits/repository/chit_repository.dart';
import 'package:my_data_app/src/chits/cubit/chit_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => BillCubit(InMemoryBillRepository())),
        BlocProvider(create: (_) => VehicleCubit(InMemoryVehicleRepository())),
        BlocProvider(create: (_) => ChitCubit(InMemoryChitRepository())),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Bill Scheduler',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.grey[50],
        ),
        home: SplashScreen(),
      ),
    );
  }
}
