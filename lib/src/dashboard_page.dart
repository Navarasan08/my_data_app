import 'package:flutter/material.dart';
import 'package:my_data_app/src/chits/chit_screen.dart';
import 'package:my_data_app/src/reminder/reminder_page.dart';
import 'package:my_data_app/src/vehicle/vehicle_manager_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int selectedPage = 0;

  void setPage(int page) {
    selectedPage = page;
    setState(() {});
  }

  Widget _buildScreen() {
    switch (selectedPage) {
      case 0:
        return BillTaskPage();
      case 1:
        return VehicleListPage();

      case 2:
        return ChitFundListPage();
      default:
        return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildScreen(),
      bottomNavigationBar: BottomNavigationBar(
        onTap: setPage,
        currentIndex: selectedPage,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.task_alt), label: "BILLS"),
          BottomNavigationBarItem(
            icon: Icon(Icons.bike_scooter),
            label: "VEHICLE",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: "CHIT"),

        ],
      ),
    );
  }
}
