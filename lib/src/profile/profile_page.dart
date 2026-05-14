import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_data_app/src/auth/cubit/auth_cubit.dart';
import 'package:my_data_app/src/auth/cubit/auth_state.dart';
import 'package:my_data_app/src/dashboard/dashboard_settings_cubit.dart';
import 'package:my_data_app/src/settings/settings_page.dart';
import 'package:my_data_app/src/theme/app_theme.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final user = authState.user;
    final name = user?.displayName ?? '';
    final email = user?.email ?? '';
    final uid = user?.uid ?? '';
    final createdAt = user?.metadata.creationTime;
    final initial = name.isNotEmpty
        ? name[0].toUpperCase()
        : (email.isNotEmpty ? email[0].toUpperCase() : '?');

    final authCubit = context.read<AuthCubit>();
    final otherAccounts = authCubit.otherAccounts;
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            _ProfileHeader(
              initial: initial,
              name: name,
              email: email,
              canPop: canPop,
              onSettings: () => _openSettings(context),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _SectionLabel(label: 'Account'),
                  const SizedBox(height: 10),
                  _ProfileTile(
                    icon: Icons.person_rounded,
                    label: 'Display Name',
                    value: name.isNotEmpty ? name : 'Not set',
                    onEdit: () => _editDisplayName(context, name),
                  )
                      .animate()
                      .fadeIn(delay: 100.ms, duration: 350.ms)
                      .slideX(
                        begin: -0.04,
                        end: 0,
                        delay: 100.ms,
                        duration: 350.ms,
                        curve: Curves.easeOutCubic,
                      ),
                  _ProfileTile(
                    icon: Icons.email_rounded,
                    label: 'Email',
                    value: email,
                  )
                      .animate()
                      .fadeIn(delay: 180.ms, duration: 350.ms)
                      .slideX(
                        begin: -0.04,
                        end: 0,
                        delay: 180.ms,
                        duration: 350.ms,
                        curve: Curves.easeOutCubic,
                      ),
                  _ProfileTile(
                    icon: Icons.fingerprint_rounded,
                    label: 'User ID',
                    value: uid,
                  )
                      .animate()
                      .fadeIn(delay: 260.ms, duration: 350.ms)
                      .slideX(
                        begin: -0.04,
                        end: 0,
                        delay: 260.ms,
                        duration: 350.ms,
                        curve: Curves.easeOutCubic,
                      ),
                  if (createdAt != null)
                    _ProfileTile(
                      icon: Icons.calendar_today_rounded,
                      label: 'Member Since',
                      value:
                          '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                    )
                        .animate()
                        .fadeIn(delay: 340.ms, duration: 350.ms)
                        .slideX(
                          begin: -0.04,
                          end: 0,
                          delay: 340.ms,
                          duration: 350.ms,
                          curve: Curves.easeOutCubic,
                        ),
                  if (otherAccounts.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    const _SectionLabel(label: 'Other Accounts'),
                    const SizedBox(height: 10),
                    for (var i = 0; i < otherAccounts.length; i++)
                      _SavedAccountCard(
                        account: otherAccounts[i],
                        onSwitch: () =>
                            authCubit.switchAccount(otherAccounts[i]),
                        onRemove: () => authCubit
                            .removeSavedAccount(otherAccounts[i].email),
                      )
                          .animate()
                          .fadeIn(
                              delay: (420 + i * 60).ms, duration: 350.ms)
                          .slideX(
                            begin: -0.04,
                            end: 0,
                            delay: (420 + i * 60).ms,
                            duration: 350.ms,
                            curve: Curves.easeOutCubic,
                          ),
                  ],
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmLogout(context),
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Logout'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red[600],
                        side: BorderSide(color: Colors.red[300]!),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ).animate().fadeIn(delay: 600.ms, duration: 400.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openSettings(BuildContext context) {
    final dashCubit = context.read<DashboardSettingsCubit>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: dashCubit,
          child: const SettingsPage(),
        ),
      ),
    );
  }

  void _editDisplayName(BuildContext context, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter your name',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                final user = context.read<AuthCubit>().state.user;
                await user?.updateDisplayName(newName);
                if (context.mounted) {
                  await context.read<AuthCubit>().refreshUser();
                }
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthCubit>().signOut();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

/// Gradient hero header for the profile page. Mirrors the login/dashboard
/// header pattern (gradient + decorative blobs) for brand continuity.
class _ProfileHeader extends StatelessWidget {
  final String initial;
  final String name;
  final String email;
  final bool canPop;
  final VoidCallback onSettings;

  const _ProfileHeader({
    required this.initial,
    required this.name,
    required this.email,
    required this.canPop,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppTheme.brandGradient,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Soft decorative blobs (clipped by the rounded corners).
            Positioned(
              top: -50,
              right: -40,
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -60,
              left: -30,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Column(
              children: [
                Row(
                  children: [
                    if (canPop)
                      _HeaderIconButton(
                        icon: Icons.arrow_back_rounded,
                        onTap: () => Navigator.of(context).pop(),
                      )
                    else
                      const SizedBox(width: 40),
                    const Spacer(),
                    const Text(
                      'Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const Spacer(),
                    _HeaderIconButton(
                      icon: Icons.settings_rounded,
                      onTap: onSettings,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  width: 96,
                  height: 96,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.7),
                        Colors.white.withValues(alpha: 0.15),
                      ],
                    ),
                  ),
                  child: CircleAvatar(
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
                    .animate()
                    .scale(
                      begin: const Offset(0.6, 0.6),
                      end: const Offset(1, 1),
                      duration: 500.ms,
                      curve: Curves.easeOutBack,
                    )
                    .fadeIn(duration: 400.ms),
                const SizedBox(height: 14),
                if (name.isNotEmpty)
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
                if (name.isNotEmpty) const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ).animate().fadeIn(delay: 250.ms, duration: 400.ms),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.18),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onEdit;

  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.value,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: cs.primary, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (onEdit != null)
            IconButton(
              onPressed: onEdit,
              icon: Icon(
                Icons.edit_rounded,
                size: 18,
                color: cs.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

class _SavedAccountCard extends StatelessWidget {
  final SavedAccount account;
  final VoidCallback onSwitch;
  final VoidCallback onRemove;

  const _SavedAccountCard({
    required this.account,
    required this.onSwitch,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasName = account.displayName != null &&
        account.displayName!.isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: cs.primaryContainer,
            child: Text(
              account.email[0].toUpperCase(),
              style: TextStyle(
                color: cs.onPrimaryContainer,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasName ? account.displayName! : account.email,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (hasName)
                  Text(
                    account.email,
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: onSwitch,
            style: TextButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            child: const Text('Switch'),
          ),
          IconButton(
            onPressed: onRemove,
            iconSize: 18,
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.close_rounded, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
