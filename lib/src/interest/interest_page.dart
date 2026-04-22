import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:my_data_app/src/interest/cubit/interest_cubit.dart';
import 'package:my_data_app/src/interest/cubit/interest_state.dart';
import 'package:my_data_app/src/interest/model/interest_model.dart';
import 'package:my_data_app/src/interest/interest_photo_service.dart';

String _money(double v) => NumberFormat('#,##,###', 'en_IN').format(v.round());
String _date(DateTime d) => DateFormat('dd MMM yyyy').format(d);

// ─────────────────────────────────────────────────────────────────────────────
// 1. InterestListPage
// ─────────────────────────────────────────────────────────────────────────────

class InterestListPage extends StatefulWidget {
  const InterestListPage({Key? key}) : super(key: key);

  @override
  State<InterestListPage> createState() => _InterestListPageState();
}

class _InterestListPageState extends State<InterestListPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InterestCubit, InterestState>(
      builder: (context, state) {
        final cubit = context.read<InterestCubit>();
        final lent = cubit.lent;
        final borrowed = cubit.borrowed;
        final lentActive = lent.where((r) => !r.isClosed).length;
        final borrowedActive = borrowed.where((r) => !r.isClosed).length;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Interest'),
            centerTitle: true,
            elevation: 0,
            bottom: TabBar(
              controller: _tabController,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.call_made_rounded,
                          size: 16, color: Colors.green),
                      const SizedBox(width: 6),
                      const Text('I Lent'),
                      const SizedBox(width: 4),
                      Text('($lentActive)',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.call_received_rounded,
                          size: 16, color: Colors.deepOrange),
                      const SizedBox(width: 6),
                      const Text('I Borrowed'),
                      const SizedBox(width: 4),
                      Text('($borrowedActive)',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                color: Colors.white,
                child: Row(
                  children: [
                    Expanded(
                      child: _SummaryTile(
                        label: 'To Receive',
                        value: '₹${_money(cubit.totalLentOutstanding)}',
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SummaryTile(
                        label: 'To Pay',
                        value: '₹${_money(cubit.totalBorrowedOutstanding)}',
                        color: Colors.deepOrange,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _RecordListView(records: lent),
                    _RecordListView(records: borrowed),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showDirectionPicker(context, cubit),
            icon: const Icon(Icons.add),
            label: const Text('Add'),
          ),
        );
      },
    );
  }

  void _showDirectionPicker(BuildContext context, InterestCubit cubit) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            for (final dir in InterestDirection.values)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: dir.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(dir.icon, color: dir.color, size: 22),
                ),
                title: Text(dir.label,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(dir == InterestDirection.lent
                    ? 'Money you gave with interest'
                    : 'Money you took with interest'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final record = await Navigator.push<InterestRecord>(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          AddInterestPage(presetDirection: dir),
                    ),
                  );
                  if (record != null) cubit.addRecord(record);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _RecordListView extends StatelessWidget {
  final List<InterestRecord> records;
  const _RecordListView({required this.records});

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet_outlined,
                size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No records yet',
                style: TextStyle(fontSize: 16, color: Colors.grey[600])),
            const SizedBox(height: 4),
            Text('Tap + to add',
                style: TextStyle(fontSize: 13, color: Colors.grey[500])),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: records.length,
      itemBuilder: (context, i) => _RecordCard(record: records[i]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. _RecordCard
// ─────────────────────────────────────────────────────────────────────────────

class _RecordCard extends StatelessWidget {
  final InterestRecord record;
  const _RecordCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<InterestCubit>();
    final color = record.direction.color;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        // Only the left side is colored; the other three default to
        // BorderSide.none which Flutter allows alongside borderRadius.
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: cubit,
                child: InterestDetailPage(recordId: record.id),
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(record.direction.icon, size: 20, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.personName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₹${_money(record.principal)} @ '
                      '${record.interestRate.toStringAsFixed(record.interestRate.truncateToDouble() == record.interestRate ? 0 : 2)}'
                      '${record.rateUnit.short} · Started ${_date(record.startDate)}',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    if (record.isClosed)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'CLOSED',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.black54),
                        ),
                      )
                    else
                      Text(
                        'Outstanding ₹${_money(record.totalOutstanding)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                record.isClosed
                    ? Icons.archive_rounded
                    : Icons.chevron_right_rounded,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. InterestDetailPage
// ─────────────────────────────────────────────────────────────────────────────

class InterestDetailPage extends StatelessWidget {
  final String recordId;
  const InterestDetailPage({Key? key, required this.recordId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InterestCubit, InterestState>(
      builder: (context, state) {
        final cubit = context.read<InterestCubit>();
        final record = cubit.getById(recordId);

        if (record == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Interest')),
            body: const Center(child: Text('Not found')),
          );
        }

        final payments = List<InterestPayment>.from(record.payments)
          ..sort((a, b) => b.paidDate.compareTo(a.paidDate));
        final color = record.direction.color;

        return Scaffold(
          appBar: AppBar(
            title: Text(record.personName),
            centerTitle: true,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () async {
                  final updated = await Navigator.push<InterestRecord>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddInterestPage(existing: record),
                    ),
                  );
                  if (updated != null) cubit.updateRecord(updated);
                },
              ),
              IconButton(
                icon: const Icon(Icons.share_outlined),
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Coming soon')),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Record'),
                      content: Text(
                          'Delete record with ${record.personName}? This cannot be undone.'),
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
                    cubit.deleteRecord(record.id);
                    if (context.mounted) Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              // Header card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _Chip(
                          icon: record.direction.icon,
                          label: record.direction.label,
                          color: color,
                        ),
                        const SizedBox(width: 8),
                        if (record.isClosed)
                          _Chip(
                            icon: Icons.archive_rounded,
                            label: 'Closed',
                            color: Colors.grey,
                          )
                        else
                          _Chip(
                            icon: Icons.check_circle_rounded,
                            label: 'Active',
                            color: Colors.green,
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      record.personName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (record.personContact != null &&
                        record.personContact!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.phone_outlined,
                              size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            record.personContact!,
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Stat cards 2x2
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Outstanding',
                      value: '₹${_money(record.totalOutstanding)}',
                      color: color,
                      icon: Icons.pending_outlined,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatCard(
                      label: 'Total Paid',
                      value: '₹${_money(record.totalPaid)}',
                      color: Colors.blue,
                      icon: Icons.check_circle_outline,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: record.direction == InterestDirection.lent
                          ? 'Interest Earned'
                          : 'Interest Paid',
                      value: '₹${_money(record.totalInterestPaid)}',
                      color: Colors.amber[800]!,
                      icon: Icons.trending_up_rounded,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatCard(
                      label: 'Accrued so far',
                      value: '₹${_money(record.interestAccruedReducing)}',
                      color: Colors.purple,
                      icon: Icons.timelapse_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Terms section
              _SectionTitle('Terms'),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    _InfoRow(
                        label: 'Principal',
                        value: '₹${_money(record.principal)}'),
                    _InfoRow(
                      label: 'Rate',
                      value:
                          '${_rateText(record.interestRate)}% ${record.rateUnit == RateUnit.perMonth ? 'per month' : 'per year'}',
                    ),
                    _InfoRow(
                      label: 'Monthly interest',
                      value:
                          '₹${_money(record.monthlyInterestOnPrincipal)}',
                    ),
                    _InfoRow(
                        label: 'Started', value: _date(record.startDate)),
                    if (record.expectedEndDate != null)
                      _InfoRow(
                          label: 'Expected end',
                          value: _date(record.expectedEndDate!)),
                    if (record.notes != null && record.notes!.isNotEmpty)
                      _InfoRow(label: 'Notes', value: record.notes!),
                  ],
                ),
              ),

              // Agreement Photos
              if (record.agreementPhotoUrls.isNotEmpty) ...[
                const SizedBox(height: 16),
                _SectionTitle('Agreement Photos'),
                SizedBox(
                  height: 88,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: record.agreementPhotoUrls.length,
                    itemBuilder: (ctx, i) {
                      final url = record.agreementPhotoUrls[i];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => _FullscreenGallery(
                                urls: record.agreementPhotoUrls,
                                initialIndex: i,
                              ),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              url,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 80,
                                height: 80,
                                color: Colors.grey[200],
                                child: Icon(Icons.broken_image_rounded,
                                    color: Colors.grey[400]),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],

              // Payments
              const SizedBox(height: 16),
              _SectionTitle('Payments (${payments.length})'),
              if (payments.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'No payments yet',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                )
              else
                ...payments.map((p) => _PaymentTile(
                      payment: p,
                      direction: record.direction,
                      onEdit: () async {
                        final updated =
                            await Navigator.push<InterestPayment>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddPaymentPage(
                                record: record, existing: p),
                          ),
                        );
                        if (updated != null) {
                          cubit.updatePayment(record.id, updated);
                        }
                      },
                      onDelete: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete Payment'),
                            content: Text(
                                'Delete payment of ₹${_money(p.amount)}?'),
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
                          cubit.deletePayment(record.id, p.id);
                        }
                      },
                    )),

              const SizedBox(height: 20),

              // Action buttons
              if (record.isClosed)
                OutlinedButton.icon(
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Reopen'),
                  onPressed: () => cubit.reopenRecord(record.id),
                )
              else
                OutlinedButton.icon(
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Mark Closed'),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Close Record'),
                        content: const Text(
                            'Mark this record as fully settled?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) cubit.closeRecord(record.id);
                  },
                ),
              const SizedBox(height: 60),
            ],
          ),
          floatingActionButton: record.isClosed
              ? null
              : FloatingActionButton.extended(
                  onPressed: () async {
                    final payment = await Navigator.push<InterestPayment>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddPaymentPage(record: record),
                      ),
                    );
                    if (payment != null) {
                      cubit.addPayment(record.id, payment);
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Payment'),
                ),
        );
      },
    );
  }

  String _rateText(double r) =>
      r.truncateToDouble() == r ? r.toStringAsFixed(0) : r.toStringAsFixed(2);
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Chip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. _PaymentTile
// ─────────────────────────────────────────────────────────────────────────────

class _PaymentTile extends StatelessWidget {
  final InterestPayment payment;
  final InterestDirection direction;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PaymentTile({
    required this.payment,
    required this.direction,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final kindColor = payment.kind.color;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: kindColor, width: 4)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: kindColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  payment.kind.label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: kindColor,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '₹${_money(payment.amount)}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          _date(payment.paidDate),
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey[600]),
                        ),
                        if (payment.photoUrls.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.attach_file_rounded,
                              size: 11, color: Colors.grey[600]),
                          const SizedBox(width: 2),
                          Text(
                            '${payment.photoUrls.length}',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[600]),
                          ),
                        ],
                      ],
                    ),
                    if (payment.notes != null &&
                        payment.notes!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        payment.notes!,
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey[500]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: Colors.grey[500]),
                onSelected: (v) {
                  if (v == 'edit') onEdit();
                  if (v == 'delete') onDelete();
                },
                itemBuilder: (ctx) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 5. AddInterestPage
// ─────────────────────────────────────────────────────────────────────────────

class AddInterestPage extends StatefulWidget {
  final InterestRecord? existing;
  final InterestDirection? presetDirection;

  const AddInterestPage({
    Key? key,
    this.existing,
    this.presetDirection,
  }) : super(key: key);

  @override
  State<AddInterestPage> createState() => _AddInterestPageState();
}

class _AddInterestPageState extends State<AddInterestPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _principalController = TextEditingController();
  final _rateController = TextEditingController();
  final _notesController = TextEditingController();

  late InterestDirection _direction;
  RateUnit _rateUnit = RateUnit.perMonth;
  DateTime _startDate = DateTime.now();
  DateTime? _expectedEndDate;

  late final String _recordId;
  late final InterestPhotoService _photoService;
  List<String> _photoUrls = [];
  bool _uploading = false;

  bool get _isEditing => widget.existing != null;
  bool get _directionLocked => _isEditing || widget.presetDirection != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _direction = e?.direction ??
        widget.presetDirection ??
        InterestDirection.lent;
    if (e != null) {
      _nameController.text = e.personName;
      _contactController.text = e.personContact ?? '';
      _principalController.text = e.principal.toStringAsFixed(0);
      _rateController.text = e.interestRate.toString();
      _rateUnit = e.rateUnit;
      _startDate = e.startDate;
      _expectedEndDate = e.expectedEndDate;
      _notesController.text = e.notes ?? '';
      _photoUrls = List<String>.from(e.agreementPhotoUrls);
    }
    _recordId = e?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    _photoService = InterestPhotoService(
      uid: FirebaseAuth.instance.currentUser?.uid ?? 'anon',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _principalController.dispose();
    _rateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickGallery() async {
    setState(() => _uploading = true);
    try {
      final urls = await _photoService.pickAndUploadGallery(_recordId);
      if (urls.isNotEmpty) {
        setState(() => _photoUrls = [..._photoUrls, ...urls]);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _pickCamera() async {
    setState(() => _uploading = true);
    try {
      final url = await _photoService.pickFromCameraAndUpload(_recordId);
      if (url != null) {
        setState(() => _photoUrls = [..._photoUrls, url]);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _removePhoto(String url) async {
    setState(() => _photoUrls = _photoUrls.where((u) => u != url).toList());
    _photoService.deleteByUrl(url);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final now = DateTime.now();
    final record = InterestRecord(
      id: _recordId,
      direction: _direction,
      personName: _nameController.text.trim(),
      personContact: _contactController.text.trim().isEmpty
          ? null
          : _contactController.text.trim(),
      principal: double.parse(_principalController.text),
      interestRate: double.parse(_rateController.text),
      rateUnit: _rateUnit,
      startDate: _startDate,
      expectedEndDate: _expectedEndDate,
      isClosed: widget.existing?.isClosed ?? false,
      closedDate: widget.existing?.closedDate,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      agreementPhotoUrls: _photoUrls,
      payments: widget.existing?.payments ?? const [],
      createdAt: widget.existing?.createdAt ?? now,
      updatedAt: now,
    );
    Navigator.pop(context, record);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Record' : 'Add Record'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Direction',
                style:
                    TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            SegmentedButton<InterestDirection>(
              segments: const [
                ButtonSegment(
                  value: InterestDirection.lent,
                  label: Text('I Lent'),
                  icon: Icon(Icons.call_made_rounded),
                ),
                ButtonSegment(
                  value: InterestDirection.borrowed,
                  label: Text('I Borrowed'),
                  icon: Icon(Icons.call_received_rounded),
                ),
              ],
              selected: {_direction},
              onSelectionChanged: _directionLocked
                  ? null
                  : (s) => setState(() => _direction = s.first),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: '${_direction.counterpartyLabel} Name *',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.person_outline),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _contactController,
              decoration: const InputDecoration(
                labelText: 'Contact (optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _principalController,
              decoration: const InputDecoration(
                labelText: 'Principal Amount *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.currency_rupee),
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (double.tryParse(v) == null) return 'Invalid number';
                return null;
              },
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _rateController,
                    decoration: const InputDecoration(
                      labelText: 'Interest Rate *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.percent),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (double.tryParse(v) == null) return 'Invalid';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 4,
                  child: DropdownButtonFormField<RateUnit>(
                    initialValue: _rateUnit,
                    decoration: const InputDecoration(
                      labelText: 'Per',
                      border: OutlineInputBorder(),
                    ),
                    items: RateUnit.values
                        .map((u) => DropdownMenuItem(
                              value: u,
                              child: Text(u.label),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _rateUnit = v);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: const Text('Start Date'),
              subtitle: Text(_date(_startDate)),
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (d != null) setState(() => _startDate = d);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_outlined),
              title: const Text('Expected End Date (optional)'),
              subtitle: Text(_expectedEndDate != null
                  ? _date(_expectedEndDate!)
                  : 'Not set'),
              trailing: _expectedEndDate != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () =>
                          setState(() => _expectedEndDate = null),
                    )
                  : null,
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _expectedEndDate ??
                      _startDate.add(const Duration(days: 365)),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (d != null) setState(() => _expectedEndDate = d);
              },
            ),
            const Divider(),
            const SizedBox(height: 8),

            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notes),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),

            const Text(
              'Agreement Photos',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            _PhotosPicker(
              urls: _photoUrls,
              uploading: _uploading,
              onPickGallery: _pickGallery,
              onPickCamera: _pickCamera,
              onRemove: _removePhoto,
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                _isEditing ? 'Update Record' : 'Save Record',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 6. AddPaymentPage
// ─────────────────────────────────────────────────────────────────────────────

class AddPaymentPage extends StatefulWidget {
  final InterestRecord record;
  final InterestPayment? existing;

  const AddPaymentPage({
    Key? key,
    required this.record,
    this.existing,
  }) : super(key: key);

  @override
  State<AddPaymentPage> createState() => _AddPaymentPageState();
}

class _AddPaymentPageState extends State<AddPaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _principalPartController = TextEditingController();
  final _interestPartController = TextEditingController();
  final _notesController = TextEditingController();

  PaymentKind _kind = PaymentKind.interest;
  DateTime _paidDate = DateTime.now();

  late final String _paymentId;
  late final InterestPhotoService _photoService;
  List<String> _photoUrls = [];
  bool _uploading = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _amountController.text = e.amount.toStringAsFixed(0);
      _kind = e.kind;
      _paidDate = e.paidDate;
      _principalPartController.text =
          e.principalPart != null ? e.principalPart!.toStringAsFixed(0) : '';
      _interestPartController.text =
          e.interestPart != null ? e.interestPart!.toStringAsFixed(0) : '';
      _notesController.text = e.notes ?? '';
      _photoUrls = List<String>.from(e.photoUrls);
    }
    _paymentId = e?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    _photoService = InterestPhotoService(
      uid: FirebaseAuth.instance.currentUser?.uid ?? 'anon',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _principalPartController.dispose();
    _interestPartController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickGallery() async {
    setState(() => _uploading = true);
    try {
      final urls = await _photoService.pickAndUploadGallery(
        widget.record.id,
        paymentId: _paymentId,
      );
      if (urls.isNotEmpty) {
        setState(() => _photoUrls = [..._photoUrls, ...urls]);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _pickCamera() async {
    setState(() => _uploading = true);
    try {
      final url = await _photoService.pickFromCameraAndUpload(
        widget.record.id,
        paymentId: _paymentId,
      );
      if (url != null) {
        setState(() => _photoUrls = [..._photoUrls, url]);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _removePhoto(String url) async {
    setState(() => _photoUrls = _photoUrls.where((u) => u != url).toList());
    _photoService.deleteByUrl(url);
  }

  String? _validateMixed() {
    if (_kind != PaymentKind.mixed) return null;
    final total = double.tryParse(_amountController.text) ?? 0;
    final p = double.tryParse(_principalPartController.text);
    final i = double.tryParse(_interestPartController.text);
    if (p == null && i == null) {
      return 'Provide principal and/or interest part';
    }
    if (p != null && i != null) {
      if ((p + i - total).abs() > 0.5) {
        return 'Parts must sum to total';
      }
    }
    return null;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final mixedErr = _validateMixed();
    if (mixedErr != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(mixedErr)));
      return;
    }
    final amount = double.parse(_amountController.text);
    double? pPart;
    double? iPart;
    if (_kind == PaymentKind.mixed) {
      pPart = double.tryParse(_principalPartController.text);
      iPart = double.tryParse(_interestPartController.text);
      if (pPart == null && iPart != null) pPart = amount - iPart;
      if (iPart == null && pPart != null) iPart = amount - pPart;
    }
    final payment = InterestPayment(
      id: _paymentId,
      amount: amount,
      paidDate: _paidDate,
      kind: _kind,
      principalPart: pPart,
      interestPart: iPart,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      photoUrls: _photoUrls,
    );
    Navigator.pop(context, payment);
  }

  @override
  Widget build(BuildContext context) {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final pHint = double.tryParse(_principalPartController.text);
    final iHint = double.tryParse(_interestPartController.text);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Payment' : 'Add Payment'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.currency_rupee),
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (double.tryParse(v) == null) return 'Invalid';
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: const Text('Paid Date'),
              subtitle: Text(_date(_paidDate)),
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _paidDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (d != null) setState(() => _paidDate = d);
              },
            ),
            const Divider(),
            const SizedBox(height: 8),

            DropdownButtonFormField<PaymentKind>(
              initialValue: _kind,
              decoration: const InputDecoration(
                labelText: 'Payment Kind',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: PaymentKind.values
                  .map((k) => DropdownMenuItem(
                        value: k,
                        child: Text(k.label),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _kind = v);
              },
            ),
            const SizedBox(height: 16),

            if (_kind == PaymentKind.mixed) ...[
              TextFormField(
                controller: _principalPartController,
                decoration: InputDecoration(
                  labelText: 'Principal part',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                  helperText: (iHint != null && amount > 0)
                      ? 'Auto: ₹${_money(amount - iHint)}'
                      : null,
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _interestPartController,
                decoration: InputDecoration(
                  labelText: 'Interest part',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.percent),
                  helperText: (pHint != null && amount > 0)
                      ? 'Auto: ₹${_money(amount - pHint)}'
                      : null,
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
            ],

            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notes),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),

            const Text(
              'Receipt Photos',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            _PhotosPicker(
              urls: _photoUrls,
              uploading: _uploading,
              onPickGallery: _pickGallery,
              onPickCamera: _pickCamera,
              onRemove: _removePhoto,
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                _isEditing ? 'Update Payment' : 'Save Payment',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared photo picker widget
// ─────────────────────────────────────────────────────────────────────────────

class _PhotosPicker extends StatelessWidget {
  final List<String> urls;
  final bool uploading;
  final Future<void> Function() onPickGallery;
  final Future<void> Function() onPickCamera;
  final Future<void> Function(String url) onRemove;

  const _PhotosPicker({
    required this.urls,
    required this.uploading,
    required this.onPickGallery,
    required this.onPickCamera,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[];
    for (final url in urls) {
      tiles.add(Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              url,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 80,
                height: 80,
                color: Colors.grey[200],
                child: Icon(Icons.broken_image_rounded,
                    color: Colors.grey[400]),
              ),
            ),
          ),
          Positioned(
            top: 2,
            right: 2,
            child: InkWell(
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Photo'),
                    content: const Text(
                        'Remove this photo? It will also be deleted from storage.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style:
                            TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) onRemove(url);
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 12, color: Colors.white),
              ),
            ),
          ),
        ],
      ));
    }

    tiles.add(InkWell(
      onTap: uploading ? null : onPickGallery,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[400]!),
        ),
        child: uploading
            ? const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_rounded,
                      size: 22, color: Colors.grey[600]),
                  const SizedBox(height: 2),
                  Text('Gallery',
                      style:
                          TextStyle(fontSize: 10, color: Colors.grey[600])),
                ],
              ),
      ),
    ));

    tiles.add(InkWell(
      onTap: uploading ? null : onPickCamera,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[400]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_camera_rounded,
                size: 22, color: Colors.grey[600]),
            const SizedBox(height: 2),
            Text('Camera',
                style: TextStyle(fontSize: 10, color: Colors.grey[600])),
          ],
        ),
      ),
    ));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tiles
            .map((w) =>
                Padding(padding: const EdgeInsets.only(right: 8), child: w))
            .toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Fullscreen gallery
// ─────────────────────────────────────────────────────────────────────────────

class _FullscreenGallery extends StatefulWidget {
  final List<String> urls;
  final int initialIndex;

  const _FullscreenGallery({required this.urls, required this.initialIndex});

  @override
  State<_FullscreenGallery> createState() => _FullscreenGalleryState();
}

class _FullscreenGalleryState extends State<_FullscreenGallery> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('${_index + 1} / ${widget.urls.length}'),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.urls.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (ctx, i) {
          return InteractiveViewer(
            child: Center(
              child: Image.network(
                widget.urls[i],
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                    Icons.broken_image_rounded,
                    color: Colors.white54,
                    size: 48),
              ),
            ),
          );
        },
      ),
    );
  }
}
