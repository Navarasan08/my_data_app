import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import 'package:my_data_app/src/home/cubit/home_record_cubit.dart';
import 'package:my_data_app/src/home/home_record_model.dart';
import 'package:my_data_app/src/home/services/expense_io_service.dart';

/// Bottom sheet that exposes the export / import / email flows for the
/// expense tracker. Reusable from the app bar so the parent page stays
/// thin.
class ExpenseIoSheet extends StatefulWidget {
  final HomeRecordCubit cubit;

  const ExpenseIoSheet({super.key, required this.cubit});

  /// Convenience: open this sheet over [context].
  static Future<void> show(BuildContext context, HomeRecordCubit cubit) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ExpenseIoSheet(cubit: cubit),
    );
  }

  @override
  State<ExpenseIoSheet> createState() => _ExpenseIoSheetState();
}

class _ExpenseIoSheetState extends State<ExpenseIoSheet> {
  late DateTimeRange _range;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _range = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month + 1, 0),
    );
  }

  List<HomeRecord> get _filtered =>
      ExpenseIoService.recordsInRange(
        widget.cubit.state.records,
        _range.start,
        _range.end,
      );

  String get _rangeLabel =>
      '${DateFormat('d MMM yyyy').format(_range.start)} – ${DateFormat('d MMM yyyy').format(_range.end)}';

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: _range,
    );
    if (picked != null) setState(() => _range = picked);
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _exportCsv() async {
    if (!await _confirmHasRecords()) return;
    setState(() => _busy = true);
    try {
      final path = await ExpenseIoService.exportToCsv(_filtered);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(path)],
          text: 'Expenses · $_rangeLabel',
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _exportExcel() async {
    if (!await _confirmHasRecords()) return;
    setState(() => _busy = true);
    try {
      final path = await ExpenseIoService.exportToExcel(_filtered);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(path)],
          text: 'Expenses · $_rangeLabel',
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _emailExcel() async {
    if (!await _confirmHasRecords()) return;
    final email = await _askEmail();
    if (email == null || email.isEmpty) return;

    setState(() => _busy = true);
    try {
      final path = await ExpenseIoService.exportToExcel(_filtered);
      try {
        await FlutterEmailSender.send(Email(
          subject: 'Expense report · $_rangeLabel',
          body:
              'Attached is the expense report for $_rangeLabel (${_filtered.length} records).',
          recipients: [email],
          attachmentPaths: [path],
          isHTML: false,
        ));
      } catch (e) {
        // No native mail client (desktop / web) — fall back to share sheet.
        if (!mounted) return;
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(path)],
            text:
                'Expense report · $_rangeLabel\nSend this attachment to: $email',
          ),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Email composer unavailable here — opened share sheet instead.",
              ),
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _importFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx'],
    );
    if (result == null || result.files.isEmpty) return;
    final path = result.files.single.path;
    if (path == null) return;

    setState(() => _busy = true);
    try {
      final cubit = widget.cubit;
      final outcome = await ExpenseIoService.importFromFile(
        path,
        allCategories: cubit.allCategories,
        paymentTypes: cubit.paymentTypes,
        existing: cubit.state.records,
      );
      if (!mounted) return;
      final go = await _confirmImport(outcome);
      if (go == true) {
        for (final r in outcome.imported) {
          cubit.addRecord(r);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Imported ${outcome.newCount} record${outcome.newCount == 1 ? '' : 's'}.',
              ),
            ),
          );
          Navigator.of(context).pop();
        }
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ── Confirmations / prompts ───────────────────────────────────────────────

  /// Shows a tiny snackbar if the active range is empty and returns `false`
  /// so the calling action can bail out early.
  Future<bool> _confirmHasRecords() async {
    if (_filtered.isNotEmpty) return true;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No records in the selected date range.')),
    );
    return false;
  }

  Future<String?> _askEmail() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return AlertDialog(
        title: const Text('Send by email'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Excel report · $_rangeLabel\n${_filtered.length} record${_filtered.length == 1 ? '' : 's'}',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Recipient email',
                hintText: 'name@example.com',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              final v = controller.text.trim();
              if (v.isEmpty || !v.contains('@')) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Enter a valid email.')),
                );
                return;
              }
              Navigator.pop(ctx, v);
            },
            icon: const Icon(Icons.send_rounded, size: 16),
            label: const Text('Continue'),
          ),
        ],
      );
      },
    );
  }

  Future<bool?> _confirmImport(ImportResult outcome) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import preview'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _statLine(
                Icons.check_circle_rounded,
                Colors.green,
                '${outcome.newCount} new record${outcome.newCount == 1 ? '' : 's'}',
              ),
              _statLine(
                Icons.skip_next_rounded,
                Colors.amber.shade700,
                '${outcome.skippedCount} duplicate${outcome.skippedCount == 1 ? '' : 's'} skipped',
              ),
              if (outcome.errorCount > 0)
                _statLine(
                  Icons.error_outline_rounded,
                  Colors.red,
                  '${outcome.errorCount} row${outcome.errorCount == 1 ? '' : 's'} couldn\'t be parsed',
                ),
              if (outcome.errors.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: outcome.errors
                        .take(5)
                        .map(
                          (e) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              '• $e',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.red.shade900,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                if (outcome.errors.length > 5)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '… and ${outcome.errors.length - 5} more',
                      style:
                          TextStyle(fontSize: 11, color: Theme.of(ctx).colorScheme.onSurfaceVariant),
                    ),
                  ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed:
                outcome.newCount == 0 ? null : () => Navigator.pop(ctx, true),
            child: Text('Import ${outcome.newCount}'),
          ),
        ],
      ),
    );
  }

  Widget _statLine(IconData icon, Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final count = _filtered.length;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Export / Import',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 4),

            // Date-range row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: InkWell(
                onTap: _busy ? null : _pickRange,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: cs.outline),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.date_range_rounded,
                          size: 18, color: cs.onSurface),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _rangeLabel,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                            Text(
                              '$count record${count == 1 ? '' : 's'} in range',
                              style: TextStyle(
                                  fontSize: 11, color: cs.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.edit_calendar_rounded,
                          size: 18, color: cs.onSurfaceVariant),
                    ],
                  ),
                ),
              ),
            ),

            const Divider(height: 1),

            if (_busy)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              _ActionTile(
                icon: Icons.description_rounded,
                color: Colors.blue,
                title: 'Export as CSV',
                subtitle: 'Plain text spreadsheet · share to any app',
                onTap: _exportCsv,
              ),
              _ActionTile(
                icon: Icons.grid_on_rounded,
                color: Colors.green,
                title: 'Export as Excel',
                subtitle: 'Native .xlsx · opens in Sheets / Excel',
                onTap: _exportExcel,
              ),
              _ActionTile(
                icon: Icons.email_rounded,
                color: Colors.orange,
                title: 'Send by Email',
                subtitle: 'Generate Excel and send to a recipient',
                onTap: _emailExcel,
              ),
              const Divider(height: 1),
              _ActionTile(
                icon: Icons.file_upload_rounded,
                color: Colors.purple,
                title: 'Import',
                subtitle: 'From .csv or .xlsx · duplicates skipped',
                onTap: _importFile,
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
