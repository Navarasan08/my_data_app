import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:my_data_app/src/auth/cubit/auth_cubit.dart';
import 'package:my_data_app/src/shell/app_drawer.dart';
import 'package:my_data_app/src/theme/app_theme.dart';

/// Shared gradient header used by the Home and My Events tabs.
///
/// Reads the current user from [AuthCubit] internally so callers don't have
/// to thread name/initial/greeting through; trailing [actions] (theme
/// toggle, view toggle, logout, etc.) are supplied per-screen and laid out
/// to the right of the greeting block. Tapping the avatar opens the shell's
/// side drawer, where the profile lives.
class AppHeader extends StatelessWidget {
  /// Buttons rendered on the right side of the header. Use [HeaderIconButton]
  /// for the standard round white-tinted style.
  final List<Widget> actions;

  /// Hide the date subtitle when true (gives more room for trailing actions).
  final bool showDate;

  const AppHeader({super.key, this.actions = const [], this.showDate = true});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.user;
    final displayName = user?.displayName;
    final email = user?.email ?? '';
    final userName = (displayName != null && displayName.isNotEmpty)
        ? displayName
        : email;
    final userInitial = userName.isNotEmpty ? userName[0].toUpperCase() : '?';

    final hour = DateTime.now().hour;
    final (greeting, greetingIcon) = hour < 12
        ? ('Good Morning', Icons.wb_sunny_rounded)
        : hour < 17
        ? ('Good Afternoon', Icons.wb_twilight_rounded)
        : ('Good Evening', Icons.nightlight_round);

    final hasOtherAccounts = context.read<AuthCubit>().otherAccounts.isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppTheme.brandGradient,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.brandAccent.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative texture: one soft blob and one thin ring, echoing the
          // auth screens without competing with the text.
          Positioned(
            top: -70,
            right: -50,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -46,
            left: -28,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.10),
                  width: 14,
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top bar: menu · date chip · actions · avatar.
              Row(
                children: [
                  HeaderIconButton(
                    icon: Icons.menu_rounded,
                    tooltip: 'Menu',
                    onPressed: () => openShellDrawer(context),
                  ),
                  if (showDate) ...[
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 12,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat('EEE, MMM d').format(DateTime.now()),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const Spacer(),
                  for (final action in actions) ...[
                    action,
                    const SizedBox(width: 8),
                  ],
                  _HeaderAvatar(
                    initial: userInitial,
                    hasOtherAccounts: hasOtherAccounts,
                    onTap: () => openShellDrawer(context),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // Greeting block.
              Row(
                children: [
                  Icon(
                    greetingIcon,
                    size: 15,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$greeting,',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                userName,
                style: const TextStyle(
                  fontSize: 26,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  height: 1.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
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
            width: 44,
            height: 44,
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
                  fontSize: 16,
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
                  border: Border.all(color: AppTheme.brandAccent, width: 1.5),
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
