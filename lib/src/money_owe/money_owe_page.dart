import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:my_data_app/src/money_owe/model/money_owe_model.dart';
import 'package:my_data_app/src/money_owe/cubit/money_owe_cubit.dart';
import 'package:my_data_app/src/money_owe/cubit/money_owe_state.dart';

// ─── 1. MoneyOwePage ────────────────────────────────────────────────────────

class MoneyOwePage extends StatelessWidget {
  const MoneyOwePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MoneyOweCubit, MoneyOweState>(
      builder: (context, state) {
        final cubit = context.read<MoneyOweCubit>();

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Lend & Owe'),
              centerTitle: true,
              elevation: 0,
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'I Lent'),
                  Tab(text: 'I Borrowed'),
                ],
              ),
            ),
            body: Column(
              children: [
                _SummaryBar(
                  toReceive: cubit.totalLentPending,
                  toPay: cubit.totalBorrowedPending,
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _DebtList(
                        entries: cubit.lentEntries,
                        emptyLabel: 'No lent entries yet',
                      ),
                      _DebtList(
                        entries: cubit.borrowedEntries,
                        emptyLabel: 'No borrowed entries yet',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () => _showAddOptions(context),
              child: const Icon(Icons.add),
            ),
          ),
        );
      },
    );
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.green,
                child: Icon(Icons.arrow_upward_rounded, color: Colors.white),
              ),
              title: const Text('I Gave Money (Lent)'),
              subtitle: const Text('Someone owes me'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: context.read<MoneyOweCubit>(),
                      child:
                          const AddDebtPage(direction: DebtDirection.lent),
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.red,
                child: Icon(Icons.arrow_downward_rounded, color: Colors.white),
              ),
              title: const Text('I Took Money (Borrowed)'),
              subtitle: const Text('I owe someone'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: context.read<MoneyOweCubit>(),
                      child: const AddDebtPage(
                          direction: DebtDirection.borrowed),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

// ─── Summary bar ────────────────────────────────────────────────────────────

class _SummaryBar extends StatelessWidget {
  final double toReceive;
  final double toPay;
  const _SummaryBar({required this.toReceive, required this.toPay});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Expanded(child: _summaryCard('To Receive', toReceive, Colors.green,
              Icons.arrow_upward_rounded)),
          const SizedBox(width: 12),
          Expanded(child: _summaryCard('To Pay', toPay, Colors.red,
              Icons.arrow_downward_rounded)),
        ],
      ),
    );
  }

  Widget _summaryCard(
      String label, double amount, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(fontSize: 12, color: color.shade700)),
                Text(
                  '\u20B9${_fmt(amount)}',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Debt list ──────────────────────────────────────────────────────────────

class _DebtList extends StatelessWidget {
  final List<DebtEntry> entries;
  final String emptyLabel;
  const _DebtList({required this.entries, required this.emptyLabel});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Center(
        child: Text(emptyLabel,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 15)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: entries.length,
      itemBuilder: (context, i) => _DebtItemCard(entry: entries[i]),
    );
  }
}

// ─── Debt item card ─────────────────────────────────────────────────────────

class _DebtItemCard extends StatelessWidget {
  final DebtEntry entry;
  const _DebtItemCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final color = entry.direction.color;
    final isSettled = entry.isFullySettled || entry.isSettled;
    final dateFmt = DateFormat('dd MMM yyyy');

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: context.read<MoneyOweCubit>(),
              child: DebtDetailPage(entryId: entry.id),
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                backgroundColor: color.withAlpha(40),
                child: Text(
                  entry.personName.isNotEmpty
                      ? entry.personName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              const SizedBox(width: 12),
              // Name, reason, date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.personName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        decoration:
                            isSettled ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (entry.reason != null && entry.reason!.isNotEmpty)
                      Text(entry.reason!,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    Text(dateFmt.format(entry.date),
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Amount + badges + progress
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\u20B9${_fmt(entry.pendingAmount)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isSettled ? Colors.grey : color,
                      decoration:
                          isSettled ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 60,
                    child: LinearProgressIndicator(
                      value: entry.settledPercent,
                      backgroundColor: Colors.grey.shade200,
                      color: color,
                      minHeight: 4,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (isSettled)
                    _badge('Settled', Colors.green)
                  else if (entry.isOverdue)
                    _badge('Overdue', Colors.red),
                ],
              ),
              // Delete button
              IconButton(
                icon: Icon(Icons.delete_outline,
                    size: 20, color: Colors.grey.shade400),
                onPressed: () async {
                  final cubit = context.read<MoneyOweCubit>();
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Entry'),
                      content: Text(
                          'Delete "${entry.personName}" entry? This cannot be undone.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: TextButton.styleFrom(
                              foregroundColor: Colors.red),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    cubit.deleteEntry(entry.id);
                  }
                },
                splashRadius: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style:
              TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

// ─── 2. DebtDetailPage ──────────────────────────────────────────────────────

class DebtDetailPage extends StatefulWidget {
  final String entryId;
  const DebtDetailPage({super.key, required this.entryId});

  @override
  State<DebtDetailPage> createState() => _DebtDetailPageState();
}

class _DebtDetailPageState extends State<DebtDetailPage> {
  final _dateFmt = DateFormat('dd MMM yyyy');

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MoneyOweCubit, MoneyOweState>(
      builder: (context, state) {
        final entry = state.entries
            .cast<DebtEntry?>()
            .firstWhere((e) => e!.id == widget.entryId, orElse: () => null);
        if (entry == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Entry not found')),
          );
        }

        final cubit = context.read<MoneyOweCubit>();
        final color = entry.direction.color;
        final isSettled = entry.isFullySettled || entry.isSettled;

        return Scaffold(
          appBar: AppBar(
            title: Text(entry.personName),
            centerTitle: true,
            elevation: 0,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Summary card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(entry.direction.label,
                            style: TextStyle(
                                color: color, fontWeight: FontWeight.w600)),
                        if (isSettled)
                          _statusChip('Settled', Colors.green)
                        else if (entry.isOverdue)
                          _statusChip('Overdue', Colors.red),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _detailRow('Total Amount', '\u20B9${_fmt(entry.amount)}'),
                    _detailRow('Settled', '\u20B9${_fmt(entry.totalSettled)}'),
                    _detailRow('Pending', '\u20B9${_fmt(entry.pendingAmount)}'),
                    const Divider(height: 20),
                    _detailRow('Date', _dateFmt.format(entry.date)),
                    if (entry.dueDate != null)
                      _detailRow('Due Date', _dateFmt.format(entry.dueDate!)),
                    if (entry.reason != null && entry.reason!.isNotEmpty)
                      _detailRow('Reason', entry.reason!),
                    if (entry.phone != null && entry.phone!.isNotEmpty)
                      _detailRow('Phone', entry.phone!),
                    const SizedBox(height: 12),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: entry.settledPercent,
                        backgroundColor: Colors.grey.shade200,
                        color: color,
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${(entry.settledPercent * 100).toStringAsFixed(0)}% settled',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ),
                  ],
                ),
              ),
              // Overdue alert
              if (entry.isOverdue) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withAlpha(60)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This entry is overdue by ${-entry.daysLeft!} day(s).',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              // Mark as settled
              if (!isSettled) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => cubit.markSettled(entry.id),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Mark as Settled'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                      side: const BorderSide(color: Colors.green),
                    ),
                  ),
                ),
              ],
              // Settlement history
              const SizedBox(height: 20),
              Text('Settlement History',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.grey.shade800)),
              const SizedBox(height: 8),
              if (entry.settlements.isEmpty)
                Text('No payments recorded yet.',
                    style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 13))
              else
                ...entry.settlements.map((s) => _settlementTile(s)),
            ],
          ),
          floatingActionButton: isSettled
              ? null
              : FloatingActionButton.extended(
                  onPressed: () async {
                    final result = await Navigator.push<DebtSettlement>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddSettlementPage(
                          entryId: entry.id,
                          pendingAmount: entry.pendingAmount,
                        ),
                      ),
                    );
                    if (result != null && mounted) {
                      cubit.addSettlement(entry.id, result);
                    }
                  },
                  icon: const Icon(Icons.payment),
                  label: const Text('Record Payment'),
                ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          Text(value,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _settlementTile(DebtSettlement s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt_long, size: 20, color: Colors.green),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('\u20B9${_fmt(s.amount)}',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                if (s.note != null && s.note!.isNotEmpty)
                  Text(s.note!,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
          Text(_dateFmt.format(s.date),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}

// ─── 3. AddDebtPage ─────────────────────────────────────────────────────────

class AddDebtPage extends StatefulWidget {
  final DebtEntry? existing;
  final DebtDirection direction;
  const AddDebtPage({super.key, this.existing, required this.direction});

  @override
  State<AddDebtPage> createState() => _AddDebtPageState();
}

class _AddDebtPageState extends State<AddDebtPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _reasonCtrl;
  late DateTime _date;
  DateTime? _dueDate;
  bool _hasDueDate = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.personName ?? '');
    _phoneCtrl = TextEditingController(text: e?.phone ?? '');
    _amountCtrl =
        TextEditingController(text: e != null ? e.amount.toString() : '');
    _reasonCtrl = TextEditingController(text: e?.reason ?? '');
    _date = e?.date ?? DateTime.now();
    _dueDate = e?.dueDate;
    _hasDueDate = _dueDate != null;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _amountCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isDue}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isDue ? (_dueDate ?? DateTime.now()) : _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isDue) {
          _dueDate = picked;
        } else {
          _date = picked;
        }
      });
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final cubit = context.read<MoneyOweCubit>();
    final entry = DebtEntry(
      id: widget.existing?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      personName: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      direction: widget.direction,
      amount: double.parse(_amountCtrl.text.trim()),
      reason:
          _reasonCtrl.text.trim().isEmpty ? null : _reasonCtrl.text.trim(),
      date: _date,
      dueDate: _hasDueDate ? _dueDate : null,
      isSettled: widget.existing?.isSettled ?? false,
      settlements: widget.existing?.settlements ?? [],
    );
    if (widget.existing != null) {
      cubit.updateEntry(entry);
    } else {
      cubit.addEntry(entry);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.direction.color;
    final dateFmt = DateFormat('dd MMM yyyy');
    final isEdit = widget.existing != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit
            ? 'Edit ${widget.direction.label}'
            : 'Add ${widget.direction.label}'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Direction badge
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  widget.direction == DebtDirection.lent
                      ? 'I gave money to someone'
                      : 'I took money from someone',
                  style: TextStyle(color: color, fontSize: 12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Person Name *',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(
                labelText: 'Phone (optional)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountCtrl,
              decoration: const InputDecoration(
                labelText: 'Amount *',
                prefixText: '\u20B9 ',
                border: OutlineInputBorder(),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (double.tryParse(v.trim()) == null) return 'Invalid number';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            // Date
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: const Text('Date'),
              subtitle: Text(dateFmt.format(_date)),
              onTap: () => _pickDate(isDue: false),
            ),
            // Due date toggle
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Set Due Date'),
              value: _hasDueDate,
              onChanged: (v) => setState(() {
                _hasDueDate = v;
                _dueDate ??= DateTime.now().add(const Duration(days: 30));
              }),
            ),
            if (_hasDueDate)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event),
                title: const Text('Due Date'),
                subtitle: Text(
                    _dueDate != null ? dateFmt.format(_dueDate!) : 'Pick date'),
                onTap: () => _pickDate(isDue: true),
              ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _save,
              child: Text(isEdit ? 'Update' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 4. AddSettlementPage ───────────────────────────────────────────────────

class AddSettlementPage extends StatefulWidget {
  final String entryId;
  final double pendingAmount;
  const AddSettlementPage({
    super.key,
    required this.entryId,
    required this.pendingAmount,
  });

  @override
  State<AddSettlementPage> createState() => _AddSettlementPageState();
}

class _AddSettlementPageState extends State<AddSettlementPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountCtrl;
  late final TextEditingController _noteCtrl;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    _amountCtrl =
        TextEditingController(text: widget.pendingAmount.toStringAsFixed(0));
    _noteCtrl = TextEditingController();
    _date = DateTime.now();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final settlement = DebtSettlement(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      amount: double.parse(_amountCtrl.text.trim()),
      date: _date,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
    );
    Navigator.pop(context, settlement);
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Payment'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Pending: \u20B9${_fmt(widget.pendingAmount)}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountCtrl,
              decoration: const InputDecoration(
                labelText: 'Amount *',
                prefixText: '\u20B9 ',
                border: OutlineInputBorder(),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                final val = double.tryParse(v.trim());
                if (val == null || val <= 0) return 'Enter a valid amount';
                return null;
              },
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: const Text('Date'),
              subtitle: Text(dateFmt.format(_date)),
              onTap: _pickDate,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _save,
              child: const Text('Save Payment'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Helpers ────────────────────────────────────────────────────────────────

String _fmt(double v) {
  if (v == v.roundToDouble()) return v.toStringAsFixed(0);
  return v.toStringAsFixed(2);
}

extension _ColorShade on Color {
  Color get shade700 {
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness((hsl.lightness * 0.6).clamp(0.0, 1.0)).toColor();
  }
}
