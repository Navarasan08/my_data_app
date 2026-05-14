import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_data_app/src/settings/data_io_service.dart';

class ExportOptions {
  final Set<String> moduleIds;
  final DateTime? from;
  final DateTime? to;

  const ExportOptions({
    required this.moduleIds,
    this.from,
    this.to,
  });
}

/// Fullscreen dialog letting the user pick which modules to export and an
/// optional date range. Pop result is an [ExportOptions] or null on cancel.
class ExportOptionsPage extends StatefulWidget {
  const ExportOptionsPage({super.key});

  @override
  State<ExportOptionsPage> createState() => _ExportOptionsPageState();
}

class _ExportOptionsPageState extends State<ExportOptionsPage> {
  late final Set<String> _selected;
  DateTime? _from;
  DateTime? _to;

  @override
  void initState() {
    super.initState();
    _selected = DataIoService.modules.map((m) => m.id).toSet();
  }

  bool get _allSelected => _selected.length == DataIoService.modules.length;
  bool get _noneSelected => _selected.isEmpty;

  void _toggleAll() {
    setState(() {
      if (_allSelected) {
        _selected.clear();
      } else {
        _selected
          ..clear()
          ..addAll(DataIoService.modules.map((m) => m.id));
      }
    });
  }

  Future<void> _pickFrom() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _from ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: _to ?? DateTime(2100),
    );
    if (picked != null) setState(() => _from = picked);
  }

  Future<void> _pickTo() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _to ?? DateTime.now(),
      firstDate: _from ?? DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _to = picked);
  }

  void _clearDates() => setState(() {
        _from = null;
        _to = null;
      });

  void _submit() {
    Navigator.pop(
      context,
      ExportOptions(
        moduleIds: Set.of(_selected),
        from: _from,
        to: _to,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fmt = DateFormat('d MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Export options'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _toggleAll,
            child: Text(_allSelected ? 'Clear all' : 'Select all'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Date range (optional)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: cs.onSurfaceVariant,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: const Text('From'),
                  subtitle: Text(_from == null ? 'Any' : fmt.format(_from!)),
                  onTap: _pickFrom,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.event_outlined),
                  title: const Text('To'),
                  subtitle: Text(_to == null ? 'Any' : fmt.format(_to!)),
                  onTap: _pickTo,
                ),
                if (_from != null || _to != null) ...[
                  const Divider(height: 1),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _clearDates,
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      label: const Text('Clear range'),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Reference data (vehicles, vault, categories, etc.) ignores the '
              'date range and is exported whenever its module is selected.',
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Modules (${_selected.length}/${DataIoService.modules.length})',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: cs.onSurfaceVariant,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Column(
              children: [
                for (var i = 0; i < DataIoService.modules.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  CheckboxListTile(
                    value: _selected.contains(DataIoService.modules[i].id),
                    onChanged: (v) {
                      setState(() {
                        if (v == true) {
                          _selected.add(DataIoService.modules[i].id);
                        } else {
                          _selected.remove(DataIoService.modules[i].id);
                        }
                      });
                    },
                    title: Row(
                      children: [
                        Icon(DataIoService.modules[i].icon,
                            size: 20, color: cs.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(DataIoService.modules[i].label),
                        ),
                      ],
                    ),
                    controlAffinity: ListTileControlAffinity.trailing,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: _noneSelected ? null : _submit,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('Continue'),
          ),
        ),
      ),
    );
  }
}
