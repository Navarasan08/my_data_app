import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:my_data_app/src/loans/cubit/loan_cubit.dart';
import 'package:my_data_app/src/loans/cubit/loan_state.dart';
import 'package:my_data_app/src/loans/loan_analysis_page.dart';
import 'package:my_data_app/src/loans/loan_form_page.dart';
import 'package:my_data_app/src/loans/model/loan_model.dart';

String _fmt(double v) => NumberFormat('#,##,###', 'en_IN').format(v.round());

/// One loan in full: a hero card with the outstanding balance and progress,
/// payment actions, the terms and interest breakdown, and the repayment
/// history split into EMI and part-payment tabs.
class LoanDetailPage extends StatefulWidget {
  final String loanId;
  const LoanDetailPage({super.key, required this.loanId});

  @override
  State<LoanDetailPage> createState() => _LoanDetailPageState();
}

class _LoanDetailPageState extends State<LoanDetailPage> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoanCubit, LoanState>(
      builder: (context, state) {
        final cubit = context.read<LoanCubit>();
        final loan = cubit.getLoanById(widget.loanId);

        if (loan == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Loan')),
            body: const Center(child: Text('Loan not found')),
          );
        }

        final emiHistory = List<Repayment>.from(loan.emiRepayments)
          ..sort((a, b) => b.paidDate.compareTo(a.paidDate));
        final partHistory = List<Repayment>.from(loan.partPayments)
          ..sort((a, b) => b.paidDate.compareTo(a.paidDate));

        return Scaffold(
          appBar: AppBar(
            title: Text(loan.name),
            centerTitle: true,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.analytics_rounded),
                tooltip: 'Analysis',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: cubit,
                      child: const LoanAnalysisPage(),
                    ),
                  ),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (action) async {
                  switch (action) {
                    case 'edit':
                      final updated = await Navigator.push<Loan>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddLoanPage(loan: loan),
                        ),
                      );
                      if (updated != null) cubit.updateLoan(updated);
                    case 'close':
                      _confirmClose(context, cubit, loan);
                    case 'delete':
                      _confirmDelete(context, cubit, loan);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit_outlined),
                      title: Text('Edit'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  if (!loan.isClosed)
                    const PopupMenuItem(
                      value: 'close',
                      child: ListTile(
                        leading: Icon(Icons.check_circle_outline),
                        title: Text('Close Loan'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete_outline, color: Colors.red),
                      title: Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _HeroCard(loan: loan),
              if (!loan.isClosed) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _recordEmi(context, cubit, loan),
                        icon: const Icon(Icons.receipt_long_rounded, size: 18),
                        label: Text('EMI #${loan.paidEmiCount + 1}'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: () => _recordPartPayment(
                          context,
                          cubit,
                          loan,
                        ),
                        icon: const Icon(Icons.savings_rounded, size: 18),
                        label: const Text('Part Payment'),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              _InfoCard(
                title: 'Terms',
                rows: [
                  ('Principal', '₹${_fmt(loan.principalAmount)}'),
                  (
                    'Interest Rate',
                    '${loan.interestRate.toStringAsFixed(2)}% / yr',
                  ),
                  ('EMI', '₹${_fmt(loan.emiAmount)}'),
                  ('Tenure', '${loan.tenureMonths} months'),
                  (
                    'Start Date',
                    DateFormat('dd MMM yyyy').format(loan.startDate),
                  ),
                  if (!loan.isClosed && loan.remainingEmis > 0)
                    (
                      'Next EMI',
                      DateFormat('dd MMM yyyy').format(loan.nextEmiDate),
                    ),
                  if (loan.lenderOrBorrower?.isNotEmpty ?? false)
                    (
                      loan.direction == LoanDirection.borrowed
                          ? 'Lender'
                          : 'Borrower',
                      loan.lenderOrBorrower!,
                    ),
                  if (loan.accountNumber?.isNotEmpty ?? false)
                    ('Account', loan.accountNumber!),
                ],
              ),
              const SizedBox(height: 12),
              _InfoCard(
                title: 'Interest & Payments',
                rows: [
                  ('Total Paid', '₹${_fmt(loan.totalRepaid)}'),
                  ('Total Interest', '₹${_fmt(loan.totalInterestOriginal)}'),
                  ('Interest Paid', '₹${_fmt(loan.interestPaid)}'),
                  ('Interest Left', '₹${_fmt(loan.interestRemaining)}'),
                  if (loan.partPayments.isNotEmpty)
                    (
                      'Part Payments',
                      '₹${_fmt(loan.totalPartPayments)}'
                          ' (${loan.partPayments.length})',
                    ),
                ],
                footer: loan.interestSaved > 0
                    ? '🎉 ₹${_fmt(loan.interestSaved)} interest saved by '
                          'part payments'
                    : null,
              ),
              if (loan.notes?.isNotEmpty ?? false) ...[
                const SizedBox(height: 12),
                _InfoCard(title: 'Notes', rows: const [], footer: loan.notes),
              ],
              const SizedBox(height: 16),
              _RepaymentTabs(
                loan: loan,
                emiHistory: emiHistory,
                partHistory: partHistory,
                onDelete: (r) =>
                    _confirmDeleteRepayment(context, cubit, loan, r),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _recordEmi(
    BuildContext context,
    LoanCubit cubit,
    Loan loan,
  ) async {
    final repayment = await Navigator.push<Repayment>(
      context,
      MaterialPageRoute(
        builder: (_) => AddRepaymentPage(
          loanId: loan.id,
          nextMonthNumber: loan.paidEmiCount + 1,
          emiAmount: loan.emiAmount,
        ),
      ),
    );
    if (repayment != null) cubit.addRepayment(loan.id, repayment);
  }

  Future<void> _recordPartPayment(
    BuildContext context,
    LoanCubit cubit,
    Loan loan,
  ) async {
    final repayment = await Navigator.push<Repayment>(
      context,
      MaterialPageRoute(
        builder: (_) => AddRepaymentPage(
          loanId: loan.id,
          nextMonthNumber: 0,
          isPartPayment: true,
        ),
      ),
    );
    if (repayment == null || !context.mounted) return;
    _showStrategyDialog(context, cubit, loan, repayment);
  }

  Future<void> _confirmClose(
    BuildContext context,
    LoanCubit cubit,
    Loan loan,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Close Loan'),
        content: const Text('Mark this loan as closed? This cannot be undone.'),
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
    if (confirmed == true) cubit.closeLoan(loan.id);
  }

  Future<void> _confirmDelete(
    BuildContext context,
    LoanCubit cubit,
    Loan loan,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Loan'),
        content: Text(
          'Delete "${loan.name}" and its entire repayment history?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      cubit.deleteLoan(loan.id);
      Navigator.pop(context);
    }
  }

  Future<void> _confirmDeleteRepayment(
    BuildContext context,
    LoanCubit cubit,
    Loan loan,
    Repayment r,
  ) async {
    final label = r.isPartPayment ? 'Part Payment' : 'EMI #${r.monthNumber}';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          r.isPartPayment ? 'Delete Part Payment' : 'Delete Repayment',
        ),
        content: Text('Delete $label of ₹${_fmt(r.amount)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) cubit.deleteRepayment(loan.id, r.id);
  }

  void _showStrategyDialog(
    BuildContext context,
    LoanCubit cubit,
    Loan loan,
    Repayment repayment,
  ) {
    final remainingPrincipal = (loan.outstandingBalance - repayment.amount)
        .clamp(0.0, double.infinity);
    final remainingEmis = loan.remainingEmis;
    final newEmi = Loan.calculateNewEmi(
      remainingPrincipal,
      loan.interestRate,
      remainingEmis > 0 ? remainingEmis : 1,
    );
    final newTenure = Loan.calculateNewTenure(
      remainingPrincipal,
      loan.interestRate,
      loan.emiAmount,
    );

    double? interestAmount;

    showDialog(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        double? customEmi;
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Part Payment Strategy'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Part Payment: ₹${_fmt(repayment.amount)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'New Outstanding: ₹${_fmt(remainingPrincipal)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Interest charged (optional)',
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.currency_rupee, size: 16),
                      ),
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 14),
                      onChanged: (v) => interestAmount = double.tryParse(v),
                    ),
                    const SizedBox(height: 16),
                    _StrategyOption(
                      color: Colors.blue,
                      icon: Icons.timelapse_rounded,
                      title: 'Reduce Tenure',
                      subtitle:
                          'Keep EMI ₹${_fmt(loan.emiAmount)}, '
                          'finish in ~$newTenure months',
                      onTap: () {
                        Navigator.pop(ctx);
                        cubit.addPartPayment(
                          loan.id,
                          repayment.copyWith(
                            interestPortion: interestAmount ?? 0,
                          ),
                          PartPaymentStrategy.reduceTenure,
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    _StrategyOption(
                      color: Colors.green,
                      icon: Icons.trending_down_rounded,
                      title: 'Reduce EMI',
                      subtitle: 'Keep tenure, new EMI ≈ ₹${_fmt(newEmi)}',
                      onTap: () {
                        Navigator.pop(ctx);
                        cubit.addPartPayment(
                          loan.id,
                          repayment.copyWith(
                            interestPortion: interestAmount ?? 0,
                          ),
                          PartPaymentStrategy.reduceEmi,
                          newEmi: customEmi,
                        );
                      },
                      trailing: TextField(
                        decoration: InputDecoration(
                          labelText: 'Custom EMI (optional)',
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(
                            Icons.currency_rupee,
                            size: 16,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 14),
                        onChanged: (v) => customEmi = double.tryParse(v),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _HeroCard extends StatelessWidget {
  final Loan loan;
  const _HeroCard({required this.loan});

  @override
  Widget build(BuildContext context) {
    final color = loan.type.color;
    final overdue = loan.overdueEmis;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, Color.lerp(color, Colors.black, 0.3)!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(loan.type.icon, color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              Text(
                '${loan.type.label} · ${loan.directionLabel}',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const Spacer(),
              if (loan.isClosed)
                const _HeroChip(
                  icon: Icons.check_circle_rounded,
                  text: 'Closed',
                )
              else if (overdue > 0)
                _HeroChip(
                  icon: Icons.warning_amber_rounded,
                  text: '$overdue overdue',
                ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Outstanding',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          Text(
            '₹${_fmt(loan.outstandingBalance)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: loan.progressPercent,
              minHeight: 6,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${loan.paidEmiCount} of ${loan.tenureMonths} EMIs paid · '
            '${(loan.progressPercent * 100).toStringAsFixed(0)}%',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _HeroChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<(String, String)> rows;
  final String? footer;

  const _InfoCard({required this.title, required this.rows, this.footer});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: cs.primary,
            ),
          ),
          const SizedBox(height: 8),
          for (final (label, value) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          if (footer != null) ...[
            if (rows.isNotEmpty) const SizedBox(height: 6),
            Text(footer!, style: const TextStyle(fontSize: 13)),
          ],
        ],
      ),
    );
  }
}

class _StrategyOption extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  const _StrategyOption({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 12)),
            if (trailing != null) ...[
              const SizedBox(height: 8),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

class _RepaymentTabs extends StatefulWidget {
  final Loan loan;
  final List<Repayment> emiHistory;
  final List<Repayment> partHistory;
  final Future<void> Function(Repayment) onDelete;

  const _RepaymentTabs({
    required this.loan,
    required this.emiHistory,
    required this.partHistory,
    required this.onDelete,
  });

  @override
  State<_RepaymentTabs> createState() => _RepaymentTabsState();
}

class _RepaymentTabsState extends State<_RepaymentTabs>
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
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: cs.primary,
            unselectedLabelColor: cs.onSurfaceVariant,
            labelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            indicator: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                ),
              ],
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            tabs: [
              Tab(text: 'EMIs (${widget.emiHistory.length})'),
              Tab(text: 'Part Payments (${widget.partHistory.length})'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 360,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildList(widget.emiHistory, 'No EMI repayments yet'),
              _buildList(widget.partHistory, 'No part payments yet'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildList(List<Repayment> items, String emptyMsg) {
    if (items.isEmpty) {
      return Builder(
        builder: (context) {
          final cs = Theme.of(context).colorScheme;
          return Center(
            child: Text(emptyMsg, style: TextStyle(color: cs.onSurfaceVariant)),
          );
        },
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      itemCount: items.length,
      itemBuilder: (ctx, i) => _RepaymentTile(
        repayment: items[i],
        onDelete: () => widget.onDelete(items[i]),
      ),
    );
  }
}

class _RepaymentTile extends StatelessWidget {
  final Repayment repayment;
  final VoidCallback onDelete;

  const _RepaymentTile({required this.repayment, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = repayment.isPartPayment ? Colors.green : Colors.blue;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: repayment.isPartPayment
                ? Icon(Icons.savings_rounded, size: 18, color: accent)
                : Text(
                    '#${repayment.monthNumber}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: accent,
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '₹${_fmt(repayment.amount)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('dd MMM yyyy').format(repayment.paidDate),
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
                if (repayment.principalPortion != null ||
                    repayment.interestPortion != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'P: ₹${_fmt(repayment.principalPortion ?? 0.0)}  '
                    'I: ₹${_fmt(repayment.interestPortion ?? 0.0)}',
                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                  ),
                ],
                if (repayment.notes?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 2),
                  Text(
                    repayment.notes!,
                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            visualDensity: VisualDensity.compact,
            icon: Icon(
              Icons.delete_outline_rounded,
              size: 18,
              color: Colors.red[300],
            ),
          ),
        ],
      ),
    );
  }
}
