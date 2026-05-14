import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_data_app/src/auth/cubit/auth_cubit.dart';
import 'package:my_data_app/src/dashboard/dashboard_settings_cubit.dart';
import 'package:my_data_app/src/dashboard/dashboard_settings_page.dart';
import 'package:my_data_app/src/settings/data_io_service.dart';
import 'package:my_data_app/src/settings/export_options_page.dart';
import 'package:my_data_app/src/theme/theme_cubit.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final dashCubit = context.read<DashboardSettingsCubit>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const _SectionLabel(label: 'Appearance'),
          const SizedBox(height: 8),
          BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, themeMode) {
              final isDark = themeMode == ThemeMode.dark;
              return _ActionTile(
                icon: isDark
                    ? Icons.dark_mode_rounded
                    : Icons.light_mode_rounded,
                label: 'Dark Mode',
                value: isDark ? 'On' : 'Off',
                trailing: Switch(
                  value: isDark,
                  onChanged: (_) => context.read<ThemeCubit>().toggle(),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          const _SectionLabel(label: 'Dashboard'),
          const SizedBox(height: 8),
          BlocBuilder<DashboardSettingsCubit, DashboardSettingsState>(
            builder: (context, dashSettings) {
              return _ActionTile(
                icon: dashSettings.isGridView
                    ? Icons.grid_view_rounded
                    : Icons.view_list_rounded,
                label: 'View Mode',
                value: dashSettings.isGridView ? 'Grid' : 'List',
                trailing: Switch(
                  value: dashSettings.isGridView,
                  onChanged: (_) => dashCubit.toggleViewMode(),
                ),
              );
            },
          ),
          _ActionTile(
            icon: Icons.settings_rounded,
            label: 'Dashboard Settings',
            value: 'Manage features & order',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: dashCubit,
                  child: const DashboardSettingsPage(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const _SectionLabel(label: 'Data'),
          const SizedBox(height: 8),
          _ActionTile(
            icon: Icons.file_upload_outlined,
            label: 'Export Data',
            value: 'Save a backup of all your data',
            onTap: () => _handleExport(context),
          ),
          _ActionTile(
            icon: Icons.file_download_outlined,
            label: 'Import Data',
            value: 'Restore data from a backup file',
            onTap: () => _handleImport(context),
          ),
        ],
      ),
    );
  }

  Future<void> _handleExport(BuildContext context) async {
    final uid = context.read<AuthCubit>().state.user?.uid;
    if (uid == null) {
      _showSnack(context, 'You must be signed in to export.');
      return;
    }

    final options = await Navigator.of(context).push<ExportOptions>(
      MaterialPageRoute(
        builder: (_) => const ExportOptionsPage(),
        fullscreenDialog: true,
      ),
    );
    if (options == null) return;
    if (!context.mounted) return;

    final confirmed = await _confirmExport(context, options);
    if (confirmed != true) return;
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final service = DataIoService();

    _showBlockingLoader(context, 'Gathering your data…');
    try {
      final payload = await service.exportAll(
        uid,
        moduleIds: options.moduleIds,
        from: options.from,
        to: options.to,
      );
      final json = service.encodePayload(payload);
      final size = service.evaluatePayloadSize(json);

      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      if (size.verdict == ExportSize.block) {
        await _showSizeBlockedDialog(context, size.bytes);
        return;
      }
      if (size.verdict == ExportSize.warn) {
        final go = await _confirmLargeExport(context, size.bytes);
        if (go != true) return;
      }

      if (!context.mounted) return;
      _showBlockingLoader(context, 'Preparing file…');
      await service.shareJson(json);
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      messenger.showSnackBar(
        SnackBar(content: Text(
            'Export ready (${_humanBytes(size.bytes)}) — choose where to save it.')),
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      messenger.showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  Future<bool?> _confirmExport(BuildContext context, ExportOptions opts) {
    final fmt = (DateTime d) =>
        '${d.day}/${d.month}/${d.year}';
    final range = (opts.from == null && opts.to == null)
        ? 'All time'
        : '${opts.from == null ? 'Any' : fmt(opts.from!)}'
            ' → '
            '${opts.to == null ? 'Any' : fmt(opts.to!)}';
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Export your data?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Modules: ${opts.moduleIds.length}'
                ' of ${DataIoService.modules.length}'),
            const SizedBox(height: 4),
            Text('Date range: $range'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmLargeExport(BuildContext context, int bytes) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Large export'),
        content: Text(
            'The export file is about ${_humanBytes(bytes)}. Sharing files '
            'this large can be slow or fail on some platforms. Continue anyway?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSizeBlockedDialog(BuildContext context, int bytes) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Export too large'),
        content: Text(
            'The export would be about ${_humanBytes(bytes)}, which exceeds '
            'the ${_humanBytes(DataIoService.blockBytes)} limit. Try narrowing '
            'the date range or deselecting some modules.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _humanBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  Future<void> _handleImport(BuildContext context) async {
    final uid = context.read<AuthCubit>().state.user?.uid;
    if (uid == null) {
      _showSnack(context, 'You must be signed in to import.');
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final service = DataIoService();

    Map<String, dynamic>? payload;
    try {
      payload = await service.pickAndParseImport();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not read file: $e')),
      );
      return;
    }
    if (payload == null) return; // user cancelled

    if (!context.mounted) return;
    final mode = await _askImportMode(context);
    if (mode == null) return;

    if (mode == ImportMode.replace) {
      if (!context.mounted) return;
      final confirmed = await _confirmReplace(context);
      if (confirmed != true) return;
    }

    if (!context.mounted) return;
    _showBlockingLoader(context, 'Importing your data…');
    try {
      await service.importAll(uid, payload, mode);
      Navigator.of(context, rootNavigator: true).pop();
      if (!context.mounted) return;
      await _showImportDoneDialog(context);
      if (!context.mounted) return;
      // Sign out so AuthenticatedShell tears down and re-creates every repo
      // against the new Firestore state on the next sign-in.
      await context.read<AuthCubit>().signOut();
    } catch (e) {
      Navigator.of(context, rootNavigator: true).pop();
      messenger.showSnackBar(
        SnackBar(content: Text('Import failed: $e')),
      );
    }
  }

  Future<ImportMode?> _askImportMode(BuildContext context) {
    return showDialog<ImportMode>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import mode'),
        content: const Text(
          'Choose how the imported data should be applied:',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ImportMode.addOnly),
            child: const Text('Add new only'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ImportMode.merge),
            child: const Text('Merge'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, ImportMode.replace),
            child: const Text('Replace'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmReplace(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Replace all data?'),
        content: const Text(
          'This will permanently delete all of your existing data for this '
          'account and replace it with the contents of the import file. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Replace'),
          ),
        ],
      ),
    );
  }

  Future<void> _showImportDoneDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Import complete'),
        content: const Text(
          'Your data has been imported. You\'ll be signed out so the app can '
          'reload everything with the new data — just sign back in.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showBlockingLoader(BuildContext context, String message) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: cs.primary, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else if (onTap != null)
                Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
