import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:my_data_app/src/dashboard_page.dart';
import 'package:my_data_app/src/reminder/repository/bill_repository.dart';
import 'package:my_data_app/src/reminder/cubit/bill_cubit.dart';
import 'package:my_data_app/src/vehicle/repository/vehicle_repository.dart';
import 'package:my_data_app/src/vehicle/cubit/vehicle_cubit.dart';
import 'package:my_data_app/src/chits/repository/chit_repository.dart';
import 'package:my_data_app/src/chits/cubit/chit_cubit.dart';

void main() {
  testWidgets('DashboardPage smoke test', (WidgetTester tester) async {
    final billRepository = InMemoryBillRepository();
    final vehicleRepository = InMemoryVehicleRepository();
    final chitRepository = InMemoryChitRepository();

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => BillCubit(billRepository)),
          BlocProvider(create: (_) => VehicleCubit(vehicleRepository)),
          BlocProvider(create: (_) => ChitCubit(chitRepository)),
        ],
        child: const MaterialApp(
          home: DashboardPage(),
        ),
      ),
    );

    expect(find.text('My Assistant'), findsOneWidget);
  });
}
