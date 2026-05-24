import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:my_data_app/src/groups/cubit/group_cubit.dart';
import 'package:my_data_app/src/groups/model/group_balance.dart';
import 'package:my_data_app/src/groups/model/group_model.dart';

/// Add or edit a [GroupExpense]. Lets the user choose the payer, total amount,
/// participants (subset of group members) and the split mode (equal/exact/
/// share/percent). Each split mode shows a different per-participant input
/// row, with a live "remaining" indicator that highlights when the entered
/// values don't add up.
class AddGroupExpensePage extends StatefulWidget {
  final GroupFund group;
  final GroupExpense? existing;
  const AddGroupExpensePage({
    super.key,
    required this.group,
    this.existing,
  });

  @override
  State<AddGroupExpensePage> createState() => _AddGroupExpensePageState();
}

class _AddGroupExpensePageState extends State<AddGroupExpensePage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _amount = TextEditingController();
  final _category = TextEditingController();
  final _notes = TextEditingController();

  late String _payerUid;
  DateTime _date = DateTime.now();
  SplitMode _mode = SplitMode.equal;

  /// Per-participant raw input. Order matches `_participants`. For [equal]
  /// mode the values here are ignored (display only).
  final Map<String, TextEditingController> _splitControllers = {};

  /// uids of members who participate in this expense. Default: everyone.
  late Set<String> _participants;

  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _payerUid = widget.group.memberIds.contains(_currentUid)
        ? _currentUid
        : widget.group.memberIds.first;
    _participants = widget.group.memberIds.toSet();

    if (widget.existing != null) {
      final e = widget.existing!;
      _title.text = e.title;
      _amount.text = e.amount.toString();
      _category.text = e.category ?? '';
      _notes.text = e.notes ?? '';
      _date = e.date;
      _mode = e.splitMode;
      _payerUid = e.paidByUid;
      _participants = e.splits.map((s) => s.uid).toSet();
      for (final s in e.splits) {
        _splitControllers[s.uid] =
            TextEditingController(text: _formatValue(s.value));
      }
    }
    for (final uid in widget.group.memberIds) {
      _splitControllers.putIfAbsent(uid, () => TextEditingController());
    }
  }

  String get _currentUid => context.read<GroupCubit>().currentUid;

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _category.dispose();
    _notes.dispose();
    for (final c in _splitControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _formatValue(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(2);
  }

  /// Builds the raw splits list (one per active participant) from the current
  /// text-field state. For [SplitMode.equal] every value is 0; [resolveSplits]
  /// will recompute the per-person share.
  List<GroupSplit> _buildRawSplits() {
    return _participants.map((uid) {
      final raw = _splitControllers[uid]?.text.trim() ?? '';
      final v = double.tryParse(raw) ?? 0;
      return GroupSplit(uid: uid, value: v, owed: 0);
    }).toList();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_participants.isEmpty) {
      _snack('Select at least one participant.');
      return;
    }
    final amount = double.tryParse(_amount.text.trim());
    if (amount == null || amount <= 0) {
      _snack('Enter a valid amount.');
      return;
    }

    List<GroupSplit> resolved;
    try {
      resolved = resolveSplits(
        amount: amount,
        mode: _mode,
        rawSplits: _buildRawSplits(),
      );
    } on ArgumentError catch (e) {
      _snack(e.message?.toString() ?? 'Invalid splits.');
      return;
    }

    setState(() => _saving = true);
    final now = DateTime.now();
    final cubit = context.read<GroupCubit>();
    final expense = GroupExpense(
      id: widget.existing?.id ?? now.microsecondsSinceEpoch.toString(),
      groupId: widget.group.id,
      title: _title.text.trim(),
      amount: amount,
      paidByUid: _payerUid,
      date: _date,
      splitMode: _mode,
      splits: resolved,
      category: _category.text.trim().isEmpty ? null : _category.text.trim(),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      createdByUid: widget.existing?.createdByUid ?? cubit.currentUid,
      createdAt: widget.existing?.createdAt ?? now,
    );
    try {
      if (_isEditing) {
        await cubit.updateExpense(expense);
      } else {
        await cubit.addExpense(expense);
      }
      if (mounted) Navigator.pop(context, expense);
    } catch (e) {
      _snack('Failed to save: $e');
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = widget.group.color;
    final amount = double.tryParse(_amount.text.trim()) ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Expense' : 'New Expense'),
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Group banner
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(widget.group.icon, size: 18, color: color),
                      const SizedBox(width: 8),
                      Text(widget.group.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: color,
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _title,
                  decoration: const InputDecoration(
                    labelText: 'What was this for? *',
                    hintText: 'e.g. Hotel, Dinner, Cab',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _amount,
                  decoration: const InputDecoration(
                    labelText: 'Amount *',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    final n = double.tryParse(v.trim());
                    if (n == null || n <= 0) return 'Enter a positive number';
                    return null;
                  },
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),

                InkWell(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (d != null) setState(() => _date = d);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      border: OutlineInputBorder(),
                      isDense: true,
                      suffixIcon:
                          Icon(Icons.calendar_today_rounded, size: 18),
                    ),
                    child: Text(
                      DateFormat('EEE, MMM d, yyyy').format(_date),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  initialValue: _payerUid,
                  decoration: const InputDecoration(
                    labelText: 'Paid by *',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: widget.group.memberIds.map((uid) {
                    final m = widget.group.members[uid];
                    return DropdownMenuItem(
                      value: uid,
                      child: Text(
                        '${m?.label ?? uid}'
                        '${uid == _currentUid ? "  (you)" : ""}',
                      ),
                    );
                  }).toList(),
                  onChanged: (v) =>
                      v == null ? null : setState(() => _payerUid = v),
                ),
                const SizedBox(height: 16),

                Text('Split mode',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface)),
                const SizedBox(height: 6),
                SegmentedButton<SplitMode>(
                  segments: const [
                    ButtonSegment(
                        value: SplitMode.equal, label: Text('Equal')),
                    ButtonSegment(
                        value: SplitMode.exact, label: Text('Exact ₹')),
                    ButtonSegment(
                        value: SplitMode.share, label: Text('Shares')),
                    ButtonSegment(
                        value: SplitMode.percent, label: Text('%')),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (s) => setState(() => _mode = s.first),
                ),
                const SizedBox(height: 12),

                _SplitsEditor(
                  group: widget.group,
                  mode: _mode,
                  totalAmount: amount,
                  participants: _participants,
                  controllers: _splitControllers,
                  currentUid: _currentUid,
                  onToggleParticipant: (uid, included) {
                    setState(() {
                      if (included) {
                        _participants.add(uid);
                      } else {
                        _participants.remove(uid);
                      }
                    });
                  },
                  onChanged: () => setState(() {}),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _category,
                  decoration: const InputDecoration(
                    labelText: 'Category (optional)',
                    hintText: 'Food, Travel, Stay…',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notes,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 28),

                ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          _isEditing ? 'Update Expense' : 'Add Expense',
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SplitsEditor extends StatelessWidget {
  final GroupFund group;
  final SplitMode mode;
  final double totalAmount;
  final Set<String> participants;
  final Map<String, TextEditingController> controllers;
  final String currentUid;
  final void Function(String uid, bool included) onToggleParticipant;
  final VoidCallback onChanged;

  const _SplitsEditor({
    required this.group,
    required this.mode,
    required this.totalAmount,
    required this.participants,
    required this.controllers,
    required this.currentUid,
    required this.onToggleParticipant,
    required this.onChanged,
  });

  String _modeSuffix() {
    switch (mode) {
      case SplitMode.equal:
        return '';
      case SplitMode.exact:
        return '₹';
      case SplitMode.share:
        return 'shr';
      case SplitMode.percent:
        return '%';
    }
  }

  Widget _trailing(BuildContext context, String uid) {
    final cs = Theme.of(context).colorScheme;
    if (mode == SplitMode.equal) {
      final per = participants.isEmpty || totalAmount <= 0
          ? 0
          : totalAmount / participants.length;
      return Text('₹${per.toStringAsFixed(2)}',
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: cs.onSurface));
    }
    return SizedBox(
      width: 100,
      child: TextField(
        controller: controllers[uid],
        textAlign: TextAlign.right,
        keyboardType:
            const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          suffixText: _modeSuffix(),
        ),
        onChanged: (_) => onChanged(),
      ),
    );
  }

  String? _validationMessage() {
    if (participants.isEmpty) return 'No participants selected';
    if (totalAmount <= 0) return null; // amount validator handles it
    switch (mode) {
      case SplitMode.equal:
        return null;
      case SplitMode.exact:
        final sum = participants.fold<double>(
            0,
            (s, uid) =>
                s + (double.tryParse(controllers[uid]?.text ?? '') ?? 0));
        final diff = totalAmount - sum;
        if (diff.abs() < 0.01) return null;
        return diff > 0
            ? '₹${diff.toStringAsFixed(2)} unallocated'
            : '₹${(-diff).toStringAsFixed(2)} over';
      case SplitMode.share:
        final sum = participants.fold<double>(
            0,
            (s, uid) =>
                s + (double.tryParse(controllers[uid]?.text ?? '') ?? 0));
        if (sum <= 0) return 'Enter at least one share';
        return null;
      case SplitMode.percent:
        final sum = participants.fold<double>(
            0,
            (s, uid) =>
                s + (double.tryParse(controllers[uid]?.text ?? '') ?? 0));
        final diff = 100 - sum;
        if (diff.abs() < 0.01) return null;
        return diff > 0
            ? '${diff.toStringAsFixed(1)}% unallocated'
            : '${(-diff).toStringAsFixed(1)}% over';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final msg = _validationMessage();
    final allMembers = group.memberIds;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Split between',
                  style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              if (msg != null)
                Text(msg,
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange[800],
                        fontWeight: FontWeight.w600)),
            ],
          ),
          const Divider(height: 16),
          ...allMembers.map((uid) {
            final m = group.members[uid];
            final included = participants.contains(uid);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Checkbox(
                    value: included,
                    onChanged: (v) => onToggleParticipant(uid, v ?? false),
                    visualDensity: VisualDensity.compact,
                  ),
                  Expanded(
                    child: Text(
                      '${m?.label ?? uid}'
                      '${uid == currentUid ? "  (you)" : ""}',
                      style: TextStyle(
                        fontSize: 13,
                        color: included ? cs.onSurface : cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (included) _trailing(context, uid),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
