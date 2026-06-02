import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:my_data_app/src/reminder/model/bill_model.dart';
import 'package:my_data_app/src/reminder/cubit/bill_cubit.dart';
import 'package:my_data_app/src/reminder/cubit/bill_state.dart';

/// Indian-grouped currency, e.g. ₹1,23,456 or ₹8,000.
final NumberFormat _moneyFormat = NumberFormat.decimalPattern('en_IN')
  ..minimumFractionDigits = 0
  ..maximumFractionDigits = 2;

String _money(double value) => '₹${_moneyFormat.format(value)}';

class BillsPage extends StatelessWidget {
  const BillsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BillCubit, BillState>(
      builder: (context, state) {
        final cs = Theme.of(context).colorScheme;
        final cubit = context.read<BillCubit>();
        final month = state.selectedMonth;
        final bills = cubit.billsForSelectedMonth;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Bills'),
            centerTitle: true,
            elevation: 0,
          ),
          body: Column(
            children: [
              // Month selector
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: cs.surface,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded),
                      onPressed: () => cubit.changeMonth(-1),
                    ),
                    Text(
                      DateFormat('MMMM yyyy').format(month),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded),
                      onPressed: () => cubit.changeMonth(1),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Summary bar
              if (bills.isNotEmpty)
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  color: cs.surface,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _SummaryCard(
                              icon: Icons.error_outline_rounded,
                              label: 'Overdue',
                              count: cubit.overdueCount,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _SummaryCard(
                              icon: Icons.schedule_rounded,
                              label: 'Upcoming',
                              count: cubit.pendingCount,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _SummaryCard(
                              icon: Icons.check_circle_outline_rounded,
                              label: 'Paid',
                              count: cubit.paidCount,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: Colors.blue.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.account_balance_wallet_rounded,
                                    color: Colors.blue[700], size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  'Amount due',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.blue[900],
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  _money(cubit.totalDue),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[900],
                                  ),
                                ),
                                Text(
                                  ' / ${_money(cubit.totalAmount)}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.blue[400],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const Divider(height: 1),

              // Bills list
              Expanded(
                child: bills.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long_outlined,
                                size: 64, color: cs.onSurfaceVariant),
                            const SizedBox(height: 16),
                            Text(
                              'No bills for this month',
                              style: TextStyle(
                                  fontSize: 16, color: cs.onSurfaceVariant),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap + to add a bill',
                              style: TextStyle(
                                  fontSize: 13, color: cs.onSurfaceVariant),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: bills.length,
                        itemBuilder: (context, index) {
                          final bill = bills[index];
                          return _BillCard(
                            bill: bill,
                            month: month,
                            onTogglePaid: () =>
                                cubit.togglePaidForMonth(bill.id, month),
                            onEdit: () async {
                              final edited = await Navigator.push<Bill>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AddBillPage(bill: bill),
                                ),
                              );
                              if (edited != null) cubit.updateBill(edited);
                            },
                            onDelete: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete Bill'),
                                  content: Text(
                                      'Are you sure you want to delete "${bill.name}"?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, true),
                                      style: TextButton.styleFrom(
                                          foregroundColor: Colors.red),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true) cubit.deleteBill(bill.id);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              final newBill = await Navigator.push<Bill>(
                context,
                MaterialPageRoute(builder: (_) => const AddBillPage()),
              );
              if (newBill != null) cubit.addBill(newBill);
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Bill'),
          ),
        );
      },
    );
  }
}

// ─── Summary Card ────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: color.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bill Card ───────────────────────────────────────────────────────────────

class _BillCard extends StatelessWidget {
  final Bill bill;
  final DateTime month;
  final VoidCallback onTogglePaid;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BillCard({
    required this.bill,
    required this.month,
    required this.onTogglePaid,
    required this.onEdit,
    required this.onDelete,
  });

  /// (label, color) for the days-left status badge, relative to [month].
  (String, Color) _status() {
    if (bill.isPaidForMonth(month)) return ('Paid', Colors.green);
    final d = bill.daysLeftInMonth(month);
    if (d < 0) {
      return ('Overdue by ${-d} day${d == -1 ? '' : 's'}', Colors.red);
    }
    if (d == 0) return ('Due today', Colors.red);
    if (d == 1) return ('1 day left', Colors.orange);
    if (d <= 3) return ('$d days left', Colors.orange);
    return ('$d days left', Colors.blue);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final paid = bill.isPaidForMonth(month);
    final overdue = bill.isOverdueInMonth(month);
    final (statusLabel, statusColor) = _status();

    final total = bill.totalOccurrences;
    final countLabel =
        total != null ? '${bill.completedCount}/$total' : '${bill.completedCount}';

    // Completed bills get a green-tinted card; overdue ones a soft red accent.
    final Color cardColor = paid
        ? Colors.green.withValues(alpha: 0.08)
        : overdue
            ? Colors.red.withValues(alpha: 0.04)
            : cs.surface;
    final Color borderColor = paid
        ? Colors.green.withValues(alpha: 0.40)
        : overdue
            ? Colors.red.withValues(alpha: 0.30)
            : cs.outlineVariant;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 6, 8, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Paid checkbox for this month
              Checkbox(
                value: paid,
                onChanged: (_) => onTogglePaid(),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                activeColor: Colors.green,
              ),
              const SizedBox(width: 4),
              // Name + due date + status + progress
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    Text(
                      bill.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: paid ? Colors.green[800] : cs.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.event_rounded,
                                size: 12, color: cs.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text(
                              'Due ${DateFormat('d MMM').format(bill.dueDateInMonth(month))}',
                              style: TextStyle(
                                  fontSize: 12, color: cs.onSurfaceVariant),
                            ),
                          ],
                        ),
                        _Pill(label: statusLabel, color: statusColor),
                        _Pill(
                          label: countLabel,
                          color: Colors.purple,
                          icon: Icons.check_rounded,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (bill.amount != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _money(bill.amount!),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: onDelete,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(Icons.delete_outline_rounded,
                          size: 16, color: Colors.red[300]),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const _Pill({required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 2),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Add / Edit Bill Page ────────────────────────────────────────────────────

class AddBillPage extends StatefulWidget {
  final Bill? bill;

  const AddBillPage({Key? key, this.bill}) : super(key: key);

  @override
  State<AddBillPage> createState() => _AddBillPageState();
}

class _AddBillPageState extends State<AddBillPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  late DateTime _dueDate;
  DateTime? _deadline;

  bool get _isEditing => widget.bill != null;

  @override
  void initState() {
    super.initState();
    if (widget.bill != null) {
      _nameController.text = widget.bill!.name;
      _descriptionController.text = widget.bill!.description ?? '';
      _amountController.text = widget.bill!.amount?.toString() ?? '';
      _dueDate = widget.bill!.dueDate;
      _deadline = widget.bill!.deadline;
    } else {
      final now = DateTime.now();
      _dueDate = DateTime(now.year, now.month, now.day);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final bill = Bill(
      id: widget.bill?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      description: _descriptionController.text.isEmpty
          ? null
          : _descriptionController.text.trim(),
      amount: _amountController.text.isEmpty
          ? null
          : double.tryParse(_amountController.text),
      dueDate: _dueDate,
      deadline: _deadline,
      paidMonths: widget.bill?.paidMonths ?? const [],
      createdDate: widget.bill?.createdDate ?? DateTime.now(),
    );
    Navigator.pop(context, bill);
  }

  Future<void> _pickDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (date != null) {
      setState(() => _dueDate = DateTime(date.year, date.month, date.day));
    }
  }

  Future<void> _pickDeadline() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _deadline ?? _dueDate,
      firstDate: _dueDate,
      lastDate: DateTime(2040),
      helpText: 'Select deadline month',
    );
    if (date != null) {
      setState(() => _deadline = DateTime(date.year, date.month, date.day));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Bill' : 'Add Bill'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Bill Name *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a bill name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount (optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.currency_rupee),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            // Due date
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: cs.outline),
              ),
              leading: Icon(Icons.event_rounded, color: cs.primary),
              title: const Text('Due Date'),
              subtitle: Text(
                'Day ${_dueDate.day} · ${DateFormat('MMM yyyy').format(_dueDate)} onward',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              trailing: const Icon(Icons.calendar_today, size: 18),
              onTap: _pickDueDate,
            ),
            const SizedBox(height: 12),
            // Optional deadline
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: cs.outline),
              ),
              leading: Icon(Icons.flag_rounded, color: cs.primary),
              title: const Text('Deadline (optional)'),
              subtitle: Text(
                _deadline == null
                    ? 'No deadline — ongoing monthly bill'
                    : 'Until ${DateFormat('MMM yyyy').format(_deadline!)}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              trailing: _deadline == null
                  ? const Icon(Icons.add, size: 18)
                  : IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => setState(() => _deadline = null),
                    ),
              onTap: _pickDeadline,
            ),
            if (_deadline != null) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Progress will show as completed / ${_monthsBetween(_dueDate, _deadline!)} months.',
                  style:
                      TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ),
            ],
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(_isEditing ? 'Update Bill' : 'Save Bill',
                  style: const TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  int _monthsBetween(DateTime start, DateTime end) {
    final n = (end.year - start.year) * 12 + (end.month - start.month) + 1;
    return n < 1 ? 1 : n;
  }
}
