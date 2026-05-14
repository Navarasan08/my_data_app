import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:my_data_app/src/auth/cubit/auth_cubit.dart';
import 'package:my_data_app/src/dashboard/dashboard_settings_cubit.dart';
import 'package:my_data_app/src/profile/profile_page.dart';
import 'package:my_data_app/src/theme/app_theme.dart';

/// Shared gradient header used by the Home and My Events tabs.
///
/// Reads the current user from [AuthCubit] internally so callers don't have
/// to thread name/initial/greeting through; trailing [actions] (theme
/// toggle, view toggle, logout, etc.) are supplied per-screen and laid out
/// to the right of the greeting block. Tapping the avatar opens the profile
/// page, forwarding both [AuthCubit] and [DashboardSettingsCubit] so the
/// pushed route can read them.
class AppHeader extends StatelessWidget {
  /// Buttons rendered on the right side of the header. Use [HeaderIconButton]
  /// for the standard round white-tinted style.
  final List<Widget> actions;

  /// Hide the date subtitle when true (gives more room for trailing actions).
  final bool showDate;

  const AppHeader({
    super.key,
    this.actions = const [],
    this.showDate = true,
  });

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.user;
    final displayName = user?.displayName;
    final email = user?.email ?? '';
    final userName = (displayName != null && displayName.isNotEmpty)
        ? displayName
        : email;
    final userInitial =
        userName.isNotEmpty ? userName[0].toUpperCase() : '?';

    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';

    final hasOtherAccounts =
        context.read<AuthCubit>().otherAccounts.isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppTheme.brandGradient,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Stack(
        children: [
          // Decorative blobs — same pattern as the auth headers, gives the
          // gradient some surface texture.
          Positioned(
            top: -50,
            right: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -20,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Row(
            children: [
              _HeaderAvatar(
                initial: userInitial,
                hasOtherAccounts: hasOtherAccounts,
                onTap: () => _openProfile(context),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 22,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (showDate) ...[
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('EEEE, MMM d').format(DateTime.now()),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.65),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              for (var i = 0; i < actions.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                actions[i],
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _openProfile(BuildContext context) {
    final authCubit = context.read<AuthCubit>();
    // DashboardSettingsCubit may not be in scope if the header is used
    // somewhere outside AuthenticatedShell — fall back gracefully.
    DashboardSettingsCubit? settingsCubit;
    try {
      settingsCubit = context.read<DashboardSettingsCubit>();
    } catch (_) {
      settingsCubit = null;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: authCubit),
            if (settingsCubit != null)
              BlocProvider.value(value: settingsCubit),
          ],
          child: const ProfilePage(),
        ),
      ),
    );
  }
}

/// Compact round action button styled for use inside [AppHeader].
class HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  const HeaderIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: Colors.white.withValues(alpha: 0.18),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

/// Avatar with a soft white gradient ring + optional swap-icon badge for
/// "multiple saved accounts".
class _HeaderAvatar extends StatelessWidget {
  final String initial;
  final bool hasOtherAccounts;
  final VoidCallback onTap;

  const _HeaderAvatar({
    required this.initial,
    required this.hasOtherAccounts,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 52,
            height: 52,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.55),
                  Colors.white.withValues(alpha: 0.12),
                ],
              ),
            ),
            child: CircleAvatar(
              backgroundColor: Colors.white.withValues(alpha: 0.22),
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (hasOtherAccounts)
            Positioned(
              bottom: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppTheme.brandAccent, width: 1.5),
                ),
                child: const Icon(
                  Icons.swap_horiz_rounded,
                  size: 10,
                  color: AppTheme.brandAccent,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
