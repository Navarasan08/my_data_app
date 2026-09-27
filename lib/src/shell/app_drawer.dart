import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_data_app/src/auth/cubit/auth_cubit.dart';
import 'package:my_data_app/src/dashboard/dashboard_settings_cubit.dart';
import 'package:my_data_app/src/dashboard/dashboard_settings_page.dart';
import 'package:my_data_app/src/profile/profile_page.dart';
import 'package:my_data_app/src/settings/settings_page.dart';
import 'package:my_data_app/src/shell/feature_pages.dart';
import 'package:my_data_app/src/theme/app_theme.dart';
import 'package:my_data_app/src/theme/theme_cubit.dart';

/// Opens the shell's side drawer from anywhere inside a tab, even from a
/// page with its own Scaffold: it walks up to the outermost Scaffold, which
/// is the one in [MainShell] that owns the drawer.
void openShellDrawer(BuildContext context) {
  final root = context.findRootAncestorStateOfType<ScaffoldState>();
  if (root != null && root.hasDrawer) {
    root.openDrawer();
  } else {
    Scaffold.maybeOf(context)?.openDrawer();
  }
}

/// Hamburger for a tab-root AppBar. Renders nothing when the page was
/// pushed (a back button belongs there instead).
class ShellMenuButton extends StatelessWidget {
  const ShellMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    if (Navigator.of(context).canPop()) return const BackButton();
    return IconButton(
      tooltip: 'Menu',
      icon: const Icon(Icons.menu_rounded),
      onPressed: () => openShellDrawer(context),
    );
  }
}

/// Left side drawer: the user's profile entry point plus settings.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  /// Closes the drawer and pushes [page] with every shell cubit
  /// re-provided, since routes live outside the shell's provider subtree.
  void _push(BuildContext context, Widget page) {
    final wrapped = withShellCubits(context, page);
    Navigator.pop(context); // close the drawer first
    Navigator.push(context, MaterialPageRoute(builder: (_) => wrapped));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final user = context.watch<AuthCubit>().state.user;
    final name = (user?.displayName ?? '').trim();
    final email = user?.email ?? '';
    final label = name.isNotEmpty ? name : email;
    final initial = label.isNotEmpty ? label[0].toUpperCase() : '?';
    final isDark = context.watch<ThemeCubit>().state == ThemeMode.dark;
    final dashCubit = context.read<DashboardSettingsCubit>();
    final isGrid = context.watch<DashboardSettingsCubit>().state.isGridView;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Header
            InkWell(
              onTap: () => _push(context, const ProfilePage()),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: AppTheme.brandGradient,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.white.withValues(alpha: 0.22),
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (name.isNotEmpty && email.isNotEmpty)
                            Text(
                              email,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          const SizedBox(height: 4),
                          Text(
                            'View profile',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white70,
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  ListTile(
                    leading: const Icon(Icons.person_rounded),
                    title: const Text('Profile'),
                    onTap: () => _push(context, const ProfilePage()),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.dashboard_customize_rounded),
                    title: const Text('Dashboard settings'),
                    subtitle: const Text('Features, order, tabs'),
                    onTap: () => _push(
                      context,
                      BlocProvider.value(
                        value: dashCubit,
                        child: const DashboardSettingsPage(),
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings_rounded),
                    title: const Text('Settings'),
                    onTap: () => _push(context, const SettingsPage()),
                  ),
                  SwitchListTile(
                    secondary: Icon(
                      isGrid
                          ? Icons.grid_view_rounded
                          : Icons.view_list_rounded,
                    ),
                    title: const Text('Dashboard grid view'),
                    subtitle: Text(isGrid ? 'Tiles' : 'List'),
                    value: isGrid,
                    onChanged: (_) => dashCubit.toggleViewMode(),
                  ),
                  SwitchListTile(
                    secondary: Icon(
                      isDark
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                    ),
                    title: const Text('Dark mode'),
                    value: isDark,
                    onChanged: (_) => context.read<ThemeCubit>().toggle(),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: cs.outlineVariant),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.red),
              title: const Text('Log out', style: TextStyle(color: Colors.red)),
              onTap: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (d) => AlertDialog(
                    title: const Text('Log out?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(d, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(d, true),
                        child: const Text('Log out'),
                      ),
                    ],
                  ),
                );
                if (ok == true && context.mounted) {
                  Navigator.pop(context);
                  context.read<AuthCubit>().signOut();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
