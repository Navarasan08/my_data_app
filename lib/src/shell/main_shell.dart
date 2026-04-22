import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_data_app/src/dashboard_page.dart';
import 'package:my_data_app/src/events/my_events_page.dart';
import 'package:my_data_app/src/notifications/cubit/notification_cubit.dart';
import 'package:my_data_app/src/notifications/cubit/notification_state.dart';
import 'package:my_data_app/src/notifications/notification_service.dart';
import 'package:my_data_app/src/notifications/notifications_page.dart';
import 'package:my_data_app/src/schedule/cubit/schedule_cubit.dart';
import 'package:my_data_app/src/schedule/schedule_detail_page.dart';

/// Top-level shell with bottom navigation: Home / My Events / Notifications.
class MainShell extends StatefulWidget {
  /// The shared local notifications service. Tap callbacks are wired here.
  final LocalNotificationService notificationService;

  const MainShell({super.key, required this.notificationService});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // OS-notification taps are funneled through here too. Payload format:
    // <sourceModule>|<sourceItemId>|<sourceDate?>
    widget.notificationService.onTap = (payload) {
      final parts = payload.split('|');
      if (parts.length < 2) return;
      final module = parts[0];
      final itemId = parts[1];
      final dateStr = parts.length > 2 && parts[2].isNotEmpty ? parts[2] : null;
      _routeTo(module, itemId, dateStr);
    };
  }

  /// Open the right module for a tapped notification (in-app or OS).
  void _routeTo(String module, String itemId, String? dateStr) {
    switch (module) {
      case 'schedule':
        // Switch to Home tab (so back nav lands on the dashboard) then push
        // the schedule detail page. Schedule cubit is already provided by the
        // authenticated shell.
        setState(() => _index = 0);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final scheduleCubit = context.read<ScheduleCubit>();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: scheduleCubit,
                child: ScheduleDetailPage(entryId: itemId),
              ),
            ),
          );
        });
        break;
      // future modules slot in here
      default:
        // Unknown module — just switch to notifications tab.
        setState(() => _index = 2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const DashboardPage(),
      const MyEventsPage(),
      NotificationsPage(
        onOpen: (n) => _routeTo(n.sourceModule, n.sourceItemId, n.sourceDate),
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: pages,
      ),
      bottomNavigationBar: BlocBuilder<NotificationCubit, NotificationState>(
        builder: (context, state) {
          final unread = context.read<NotificationCubit>().unreadCount;
          return NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard_rounded),
                label: 'Home',
              ),
              const NavigationDestination(
                icon: Icon(Icons.event_outlined),
                selectedIcon: Icon(Icons.event_rounded),
                label: 'My Events',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: unread > 0,
                  label: Text('$unread'),
                  child: const Icon(Icons.notifications_outlined),
                ),
                selectedIcon: Badge(
                  isLabelVisible: unread > 0,
                  label: Text('$unread'),
                  child: const Icon(Icons.notifications_rounded),
                ),
                label: 'Alerts',
              ),
            ],
          );
        },
      ),
    );
  }
}
