import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_data_app/src/core/sync/sync_indicator.dart';
import 'package:my_data_app/src/core/sync/sync_snapshot.dart';
import 'package:my_data_app/src/dashboard/dashboard_settings_cubit.dart';
import 'package:my_data_app/src/dashboard_page.dart';
import 'package:my_data_app/src/events/my_events_page.dart';
import 'package:my_data_app/src/notifications/notification_service.dart';
import 'package:my_data_app/src/quick_notes/quick_notes_page.dart';
import 'package:my_data_app/src/shell/app_drawer.dart';
import 'package:my_data_app/src/shell/feature_pages.dart';

/// Top-level shell: a left drawer (profile, settings) and four bottom tabs —
/// Quick Notes, a user-chosen module (Expense Tracker by default), the
/// Dashboard, and Groups. Alerts live behind the bell on the Dashboard
/// header. Which tab opens first is a setting.
class MainShell extends StatefulWidget {
  /// The shared local notifications service. Tap callbacks are wired here.
  final LocalNotificationService notificationService;

  /// Combined sync state of every module; drives the hairline activity bar
  /// at the top of the shell while data is still loading or unconfirmed.
  final ValueListenable<SyncStatus> syncStatus;

  const MainShell({
    super.key,
    required this.notificationService,
    required this.syncStatus,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const _notesIndex = 0;
  static const _moduleIndex = 1;
  static const _dashboardIndex = 2;
  static const _groupsIndex = 3;

  late int _index;

  /// Once the user picks a tab we stop following the landing-tab setting,
  /// which may still be arriving from Firestore on a cold start.
  bool _userNavigated = false;

  @override
  void initState() {
    super.initState();
    _index = _indexFor(context.read<DashboardSettingsCubit>().state.landingTab);
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

  static int _indexFor(ShellTab tab) => switch (tab) {
    ShellTab.notes => _notesIndex,
    ShellTab.module => _moduleIndex,
    ShellTab.dashboard => _dashboardIndex,
    ShellTab.groups => _groupsIndex,
  };

  void _select(int i) {
    _userNavigated = true;
    setState(() => _index = i);
  }

  /// Open the right page for a tapped OS notification.
  void _routeTo(String module, String itemId, String? dateStr) {
    _pushOnDashboard((ctx) {
      return buildNotificationTarget(ctx, module, itemId) ??
          buildNotificationsRoute(ctx);
    });
  }

  /// Switch to the Dashboard tab and push a page on the next frame, so the
  /// page builder can read cubits from the freshly-active context.
  void _pushOnDashboard(Widget Function(BuildContext) builder) {
    _select(_dashboardIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => builder(context)));
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<DashboardSettingsCubit>().state;
    final cs = Theme.of(context).colorScheme;
    if (!_userNavigated) {
      final wanted = _indexFor(settings.landingTab);
      if (wanted != _index) _index = wanted;
    }
    final moduleId = settings.secondTabFeatureId;
    final moduleFeature = settings.featureById(moduleId);
    final modulePage =
        buildFeaturePage(context, moduleId) ??
        buildFeaturePage(context, 'home')!;

    final pages = <Widget>[
      const QuickNotesPage(),
      // Keyed by module id so switching the setting rebuilds the tab.
      KeyedSubtree(key: ValueKey('tab_$moduleId'), child: modulePage),
      const DashboardPage(),
      const MyEventsPage(),
    ];

    // Intercept the system / browser back button.
    //   * If the user is on a non-Dashboard tab → switch to Dashboard.
    //   * If on Dashboard and at the root route → swallow the pop (prevents
    //     the "blank page" on web when the browser tries to navigate past
    //     the app's first history entry).
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_index != _dashboardIndex) _select(_dashboardIndex);
      },
      child: Scaffold(
        drawer: const AppDrawer(),
        body: Column(
          children: [
            SyncIndicator(status: widget.syncStatus),
            Expanded(
              child: IndexedStack(index: _index, children: pages),
            ),
          ],
        ),
        bottomNavigationBar: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: cs.outlineVariant, width: 0.6),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: _select,
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.sticky_note_2_outlined),
                selectedIcon: Icon(Icons.sticky_note_2_rounded),
                label: 'Notes',
              ),
              NavigationDestination(
                icon: Icon(
                  moduleFeature?.icon ?? Icons.account_balance_wallet_rounded,
                ),
                label: _shortTitle(moduleFeature?.title ?? 'Expenses'),
              ),
              const NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard_rounded),
                label: 'Dashboard',
              ),
              const NavigationDestination(
                icon: Icon(Icons.group_outlined),
                selectedIcon: Icon(Icons.group_rounded),
                label: 'Groups',
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Bottom-bar labels have little room; drop a trailing "Tracker" etc.
  static String _shortTitle(String title) {
    const drop = [' Tracker', ' Records', ' Manager'];
    var t = title;
    for (final d in drop) {
      if (t.endsWith(d)) t = t.substring(0, t.length - d.length);
    }
    return t;
  }
}
