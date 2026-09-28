import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:my_data_app/src/loans/cubit/loan_cubit.dart';
import 'package:my_data_app/src/loans/cubit/loan_state.dart';
import 'package:my_data_app/src/loans/loan_analysis_page.dart';
import 'package:my_data_app/src/loans/loan_detail_page.dart';
import 'package:my_data_app/src/loans/loan_form_page.dart';
import 'package:my_data_app/src/loans/model/loan_model.dart';

// The module used to be one file; keep its public pages importable from here.
export 'package:my_data_app/src/loans/loan_detail_page.dart';
export 'package:my_data_app/src/loans/loan_form_page.dart';

String _fmt(double v) => NumberFormat('#,##,###', 'en_IN').format(v.round());

/// All loans: a summary header, Borrowed/Lent tabs, and a card per loan
/// with progress and outstanding amount. Tapping a card opens
/// [LoanDetailPage]; everything else (edit, payments, delete) lives there.
class LoanListPage extends StatelessWidget {
  const LoanListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoanCubit, LoanState>(
      builder: (context, state) {
        final cubit = context.read<LoanCubit>();
        final borrowed = cubit.borrowedLoans;
        final lent = cubit.lentLoans;

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Loans'),
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
              ],
              bottom: TabBar(
                tabs: [
                  Tab(text: 'Borrowed (${borrowed.length})'),
                  Tab(text: 'Lent (${lent.length})'),
                ],
              ),
            ),
            body: Column(
              children: [
                _SummaryHeader(cubit: cubit),
                Expanded(
                  child: TabBarView(
                    children: [
                      _LoanListView(loans: borrowed),
                      _LoanListView(loans: lent),
                    ],
                  ),
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () async {
                final loan = await Navigator.push<Loan>(
                  context,
                  MaterialPageRoute(builder: (_) => const AddLoanPage()),
                );
                if (loan != null) cubit.addLoan(loan);
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Loan'),
            ),
          ),
        );
      },
    );
  }
}

/// The gradient strip on top: outstanding debt, the month's EMI load and
/// how much is lent out.
class _SummaryHeader extends StatelessWidget {
  final LoanCubit cubit;
  const _SummaryHeader({required this.cubit});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade600, Colors.blueGrey.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: _HeaderStat(
              label: 'Outstanding',
              value: '₹${_fmt(cubit.totalBorrowed)}',
              icon: Icons.trending_down_rounded,
            ),
          ),
          _divider(),
          Expanded(
            child: _HeaderStat(
              label: 'Monthly EMI',
              value: '₹${_fmt(cubit.totalMonthlyEmi)}',
              icon: Icons.calendar_month_rounded,
            ),
          ),
          _divider(),
          Expanded(
            child: _HeaderStat(
              label: 'Lent Out',
              value: '₹${_fmt(cubit.totalLent)}',
              icon: Icons.trending_up_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
    width: 1,
    height: 36,
    margin: const EdgeInsets.symmetric(horizontal: 12),
    color: Colors.white24,
  );
}

class _HeaderStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _HeaderStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: Colors.white70),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _LoanListView extends StatelessWidget {
  final List<Loan> loans;
  const _LoanListView({required this.loans});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (loans.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_outlined,
              size: 64,
              color: cs.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No loans here',
              style: TextStyle(fontSize: 16, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    // Open loans first, then closed; within each, biggest balance first.
    final sorted = List<Loan>.from(loans)
      ..sort((a, b) {
        if (a.isClosed != b.isClosed) return a.isClosed ? 1 : -1;
        return b.outstandingBalance.compareTo(a.outstandingBalance);
      });

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 88),
      itemCount: sorted.length,
      itemBuilder: (context, index) => _LoanCard(loan: sorted[index]),
    );
  }
}

class _LoanCard extends StatelessWidget {
  final Loan loan;
  const _LoanCard({required this.loan});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cubit = context.read<LoanCubit>();
    final color = loan.type.color;
    final overdue = loan.overdueEmis;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: cubit,
              child: LoanDetailPage(loanId: loan.id),
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(loan.type.icon, size: 22, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loan.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [
                            loan.type.label,
                            if (loan.lenderOrBorrower?.isNotEmpty ?? false)
                              loan.lenderOrBorrower!,
                          ].join(' · '),
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
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${_fmt(loan.outstandingBalance)}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'EMI ₹${_fmt(loan.emiAmount)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: loan.progressPercent,
                        minHeight: 5,
                        backgroundColor: cs.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${loan.paidEmiCount}/${loan.tenureMonths}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  if (loan.isClosed) ...[
                    const SizedBox(width: 8),
                    _StatusChip(text: 'Closed', color: Colors.green),
                  ] else if (overdue > 0) ...[
                    const SizedBox(width: 8),
                    _StatusChip(text: '$overdue overdue', color: Colors.red),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String text;
  final Color color;
  const _StatusChip({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
