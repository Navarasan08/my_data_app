import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:my_data_app/src/loans/model/loan_model.dart';
import 'package:my_data_app/src/loans/cubit/loan_cubit.dart';
import 'package:my_data_app/src/loans/cubit/loan_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 1. LoanListPage
// ─────────────────────────────────────────────────────────────────────────────

class LoanListPage extends StatelessWidget {
  const LoanListPage({Key? key}) : super(key: key);

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
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'Borrowed'),
                  Tab(text: 'Lent'),
                ],
              ),
            ),
            body: Column(
              children: [
                // Summary bar
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  color: Colors.white,
                  child: Row(
                    children: [
                      Expanded(
                        child: _SummaryTile(
                          label: 'Outstanding',
                          value:
                              '\u20B9${cubit.totalBorrowed.toStringAsFixed(0)}',
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _SummaryTile(
                          label: 'Monthly EMI',
                          value:
                              '\u20B9${cubit.totalMonthlyEmi.toStringAsFixed(0)}',
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _SummaryTile(
                          label: 'Lent Out',
                          value:
                              '\u20B9${cubit.totalLent.toStringAsFixed(0)}',
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Tab views
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
                  MaterialPageRoute(
                      builder: (context) => const AddLoanPage()),
                );
                if (loan != null) {
                  cubit.addLoan(loan);
                }
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
              fontSize: 15,
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

class _LoanListView extends StatelessWidget {
  final List<Loan> loans;
  const _LoanListView({required this.loans});

  @override
  Widget build(BuildContext context) {
    if (loans.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_outlined,
                size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No loans here',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: loans.length,
      itemBuilder: (context, index) {
        final loan = loans[index];
        return _LoanCard(loan: loan);
      },
    );
  }
}

class _LoanCard extends StatelessWidget {
  final Loan loan;
  const _LoanCard({required this.loan});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<LoanCubit>();
    final typeColor = loan.type.color;
    final overdue = loan.overdueEmis;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: cubit,
                child: LoanDetailPage(loanId: loan.id),
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Row(
            children: [
              // Icon circle
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(loan.type.icon, size: 22, color: typeColor),
              ),
              const SizedBox(width: 10),
              // Details
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
                    if (loan.lenderOrBorrower != null &&
                        loan.lenderOrBorrower!.isNotEmpty)
                      Text(
                        loan.direction == LoanDirection.borrowed
                            ? 'From: ${loan.lenderOrBorrower}'
                            : 'To: ${loan.lenderOrBorrower}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      loan.type.label,
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: loan.progressPercent,
                              minHeight: 4,
                              backgroundColor: Colors.grey[200],
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(typeColor),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${loan.paidEmiCount}/${loan.tenureMonths}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: typeColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Right column
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\u20B9${loan.outstandingBalance.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (overdue > 0) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$overdue overdue',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.red[700],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Loan'),
                          content: Text(
                              'Are you sure you want to delete "${loan.name}"?'),
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
                        cubit.deleteLoan(loan.id);
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.delete_outline_rounded,
                              size: 14, color: Colors.red[400]),
                          const SizedBox(width: 2),
                          Text(
                            'Delete',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.red[400],
                            ),
                          ),
                        ],
                      ),
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

// ─────────────────────────────────────────────────────────────────────────────
// 2. LoanDetailPage
// ─────────────────────────────────────────────────────────────────────────────

class LoanDetailPage extends StatefulWidget {
  final String loanId;
  const LoanDetailPage({Key? key, required this.loanId}) : super(key: key);

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

        final sortedRepayments = List<Repayment>.from(loan.repayments)
          ..sort((a, b) => a.monthNumber.compareTo(b.monthNumber));

        return Scaffold(
          appBar: AppBar(
            title: Text(loan.name),
            centerTitle: true,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () async {
                  final updated = await Navigator.push<Loan>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddLoanPage(loan: loan),
                    ),
                  );
                  if (updated != null) {
                    cubit.updateLoan(updated);
                  }
                },
              ),
              if (!loan.isClosed)
                IconButton(
                  icon: const Icon(Icons.check_circle_outline),
                  tooltip: 'Close Loan',
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Close Loan'),
                        content: const Text(
                            'Mark this loan as closed? This cannot be undone.'),
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
                    if (confirmed == true) {
                      cubit.closeLoan(loan.id);
                    }
                  },
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              // Closed banner
              if (loan.isClosed)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded,
                          color: Colors.green[700], size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Loan Closed',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.green[800],
                        ),
                      ),
                    ],
                  ),
                ),

              // Overdue alert
              if (loan.overdueEmis > 0 && !loan.isClosed)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: Colors.red[700], size: 18),
                      const SizedBox(width: 8),
                      Text(
                        '${loan.overdueEmis} EMI(s) overdue',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.red[800],
                        ),
                      ),
                    ],
                  ),
                ),

              // Dashboard
              _buildDashboard(loan),

              // Lender / Borrower
              if (loan.lenderOrBorrower != null &&
                  loan.lenderOrBorrower!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.person_outline,
                          size: 18, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        loan.direction == LoanDirection.borrowed
                            ? 'Lender: ${loan.lenderOrBorrower}'
                            : 'Borrower: ${loan.lenderOrBorrower}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],

              // Repayment history
              const SizedBox(height: 16),
              const Text(
                'Repayment History',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (sortedRepayments.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  alignment: Alignment.center,
                  child: Text(
                    'No repayments recorded yet',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                )
              else
                ...sortedRepayments.map((r) => _RepaymentTile(
                      repayment: r,
                      onDelete: () {
                        cubit.deleteRepayment(loan.id, r.id);
                      },
                    )),
            ],
          ),
          floatingActionButton: loan.isClosed
              ? null
              : FloatingActionButton.extended(
                  onPressed: () => _showPaymentOptions(
                      context, cubit, loan),
                  icon: const Icon(Icons.payment_rounded),
                  label: const Text('Record Payment'),
                ),
        );
      },
    );
  }

  void _showPaymentOptions(
      BuildContext context, LoanCubit cubit, Loan loan) {
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
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.receipt_long_rounded,
                    color: Colors.blue, size: 22),
              ),
              title: const Text('Record EMI Payment',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                  'Month ${loan.paidEmiCount + 1} · ₹${loan.emiAmount.toStringAsFixed(0)}'),
              onTap: () async {
                Navigator.pop(ctx);
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
                if (repayment != null) {
                  cubit.addRepayment(loan.id, repayment);
                }
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.savings_rounded,
                    color: Colors.green, size: 22),
              ),
              title: const Text('Part Payment / Prepayment',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text(
                  'Lump sum towards principal to reduce outstanding'),
              onTap: () async {
                Navigator.pop(ctx);
                final repayment = await Navigator.push<Repayment>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddRepaymentPage(
                      loanId: loan.id,
                      nextMonthNumber: 0,
                      emiAmount: 0,
                      isPartPayment: true,
                    ),
                  ),
                );
                if (repayment != null) {
                  cubit.addPartPayment(loan.id, repayment);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard(Loan loan) {
    return Column(
      children: [
        // Row 1: Principal, Interest Rate, EMI
        Row(
          children: [
            Expanded(
              child: _DashTile(
                label: 'Principal',
                value: '\u20B9${loan.principalAmount.toStringAsFixed(0)}',
                icon: Icons.account_balance_wallet_outlined,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _DashTile(
                label: 'Interest Rate',
                value: '${loan.interestRate.toStringAsFixed(2)}%',
                icon: Icons.percent_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _DashTile(
                label: 'EMI',
                value: '\u20B9${loan.emiAmount.toStringAsFixed(0)}',
                icon: Icons.calendar_month_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Row 2: Total Paid, Outstanding, Progress
        Row(
          children: [
            Expanded(
              child: _DashTile(
                label: 'Total Paid',
                value: '\u20B9${loan.totalRepaid.toStringAsFixed(0)}',
                icon: Icons.check_circle_outline,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _DashTile(
                label: 'Outstanding',
                value: '\u20B9${loan.outstandingBalance.toStringAsFixed(0)}',
                icon: Icons.pending_outlined,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _DashTile(
                label: 'Progress',
                value: '${loan.paidEmiCount}/${loan.tenureMonths} EMIs',
                icon: Icons.trending_up_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Row 3: Tenure, Start Date, Next EMI Date
        Row(
          children: [
            Expanded(
              child: _DashTile(
                label: 'Tenure',
                value: '${loan.tenureMonths} months',
                icon: Icons.timelapse_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _DashTile(
                label: 'Start Date',
                value: DateFormat('dd MMM yy').format(loan.startDate),
                icon: Icons.event_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _DashTile(
                label: 'Next EMI',
                value: loan.isClosed
                    ? '--'
                    : DateFormat('dd MMM yy').format(loan.nextEmiDate),
                icon: Icons.event_available_rounded,
              ),
            ),
          ],
        ),
        // Row 4: Part payments (if any)
        if (loan.partPayments.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.savings_rounded,
                    size: 18, color: Colors.green[700]),
                const SizedBox(width: 8),
                Text(
                  'Part Payments: ',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.green[800],
                  ),
                ),
                Text(
                  '₹${loan.totalPartPayments.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
                Text(
                  ' (${loan.partPayments.length} payments)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _DashTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _DashTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey[500]),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
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

class _RepaymentTile extends StatelessWidget {
  final Repayment repayment;
  final VoidCallback onDelete;

  const _RepaymentTile({
    required this.repayment,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // Badge
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: repayment.isPartPayment
                  ? Colors.green[50]
                  : Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: repayment.isPartPayment
                ? Icon(Icons.savings_rounded,
                    size: 18, color: Colors.green[600])
                : Text(
                    '#${repayment.monthNumber}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '\u20B9${repayment.amount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('dd MMM yyyy').format(repayment.paidDate),
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                if (repayment.principalPortion != null ||
                    repayment.interestPortion != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'P: \u20B9${(repayment.principalPortion ?? 0).toStringAsFixed(0)}  '
                    'I: \u20B9${(repayment.interestPortion ?? 0).toStringAsFixed(0)}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
                if (repayment.notes != null && repayment.notes!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    repayment.notes!,
                    style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. AddLoanPage
// ─────────────────────────────────────────────────────────────────────────────

class AddLoanPage extends StatefulWidget {
  final Loan? loan;
  const AddLoanPage({Key? key, this.loan}) : super(key: key);

  @override
  State<AddLoanPage> createState() => _AddLoanPageState();
}

class _AddLoanPageState extends State<AddLoanPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _principalController = TextEditingController();
  final _rateController = TextEditingController();
  final _tenureController = TextEditingController();
  final _emiController = TextEditingController();
  final _lenderController = TextEditingController();
  final _accountController = TextEditingController();
  final _notesController = TextEditingController();

  LoanType _type = LoanType.personal;
  LoanDirection _direction = LoanDirection.borrowed;
  DateTime _startDate = DateTime.now();
  bool _emiManuallyEdited = false;

  bool get _isEditing => widget.loan != null;

  @override
  void initState() {
    super.initState();
    if (widget.loan != null) {
      final l = widget.loan!;
      _nameController.text = l.name;
      _principalController.text = l.principalAmount.toStringAsFixed(0);
      _rateController.text = l.interestRate.toString();
      _tenureController.text = l.tenureMonths.toString();
      _emiController.text = l.emiAmount.toStringAsFixed(2);
      _lenderController.text = l.lenderOrBorrower ?? '';
      _accountController.text = l.accountNumber ?? '';
      _notesController.text = l.notes ?? '';
      _type = l.type;
      _direction = l.direction;
      _startDate = l.startDate;
      _emiManuallyEdited = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _principalController.dispose();
    _rateController.dispose();
    _tenureController.dispose();
    _emiController.dispose();
    _lenderController.dispose();
    _accountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _recalculateEmi() {
    if (_emiManuallyEdited) return;
    final p = double.tryParse(_principalController.text);
    final r = double.tryParse(_rateController.text);
    final t = int.tryParse(_tenureController.text);
    if (p != null && r != null && t != null && t > 0) {
      final emi = Loan.calculateEmi(p, r, t);
      _emiController.text = emi.toStringAsFixed(2);
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final loan = Loan(
      id: widget.loan?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      type: _type,
      direction: _direction,
      principalAmount: double.parse(_principalController.text),
      interestRate: double.parse(_rateController.text),
      tenureMonths: int.parse(_tenureController.text),
      emiAmount: double.parse(_emiController.text),
      startDate: _startDate,
      lenderOrBorrower: _lenderController.text.trim().isEmpty
          ? null
          : _lenderController.text.trim(),
      accountNumber: _accountController.text.trim().isEmpty
          ? null
          : _accountController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      isClosed: widget.loan?.isClosed ?? false,
      repayments: widget.loan?.repayments ?? [],
    );

    Navigator.pop(context, loan);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Loan' : 'Add Loan'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Loan Name *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label_outline),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // Loan Type dropdown
            DropdownButtonFormField<LoanType>(
              initialValue: _type,
              decoration: const InputDecoration(
                labelText: 'Loan Type',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: LoanType.values
                  .map((t) =>
                      DropdownMenuItem(value: t, child: Text(t.label)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _type = v);
              },
            ),
            const SizedBox(height: 16),

            // Direction segmented button
            const Text('Direction',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            SegmentedButton<LoanDirection>(
              segments: const [
                ButtonSegment(
                  value: LoanDirection.borrowed,
                  label: Text('Borrowed'),
                  icon: Icon(Icons.arrow_downward_rounded),
                ),
                ButtonSegment(
                  value: LoanDirection.lent,
                  label: Text('Lent'),
                  icon: Icon(Icons.arrow_upward_rounded),
                ),
              ],
              selected: {_direction},
              onSelectionChanged: (s) =>
                  setState(() => _direction = s.first),
            ),
            const SizedBox(height: 16),

            // Principal
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
              onChanged: (_) => _recalculateEmi(),
            ),
            const SizedBox(height: 16),

            // Interest Rate
            TextFormField(
              controller: _rateController,
              decoration: const InputDecoration(
                labelText: 'Interest Rate (%) *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.percent),
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (double.tryParse(v) == null) return 'Invalid number';
                return null;
              },
              onChanged: (_) => _recalculateEmi(),
            ),
            const SizedBox(height: 16),

            // Tenure
            TextFormField(
              controller: _tenureController,
              decoration: const InputDecoration(
                labelText: 'Tenure (months) *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.timelapse_rounded),
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (int.tryParse(v) == null) return 'Invalid number';
                return null;
              },
              onChanged: (_) => _recalculateEmi(),
            ),
            const SizedBox(height: 16),

            // EMI
            TextFormField(
              controller: _emiController,
              decoration: InputDecoration(
                labelText: 'EMI Amount',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.payment_rounded),
                suffixIcon: _emiManuallyEdited
                    ? IconButton(
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Auto-calculate',
                        onPressed: () {
                          setState(() => _emiManuallyEdited = false);
                          _recalculateEmi();
                        },
                      )
                    : null,
              ),
              keyboardType: TextInputType.number,
              onChanged: (_) => _emiManuallyEdited = true,
            ),
            const SizedBox(height: 16),

            // Start Date
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: const Text('Start Date'),
              subtitle: Text(DateFormat('dd MMM yyyy').format(_startDate)),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2040),
                );
                if (date != null) setState(() => _startDate = date);
              },
            ),
            const Divider(),

            // Lender / Borrower
            TextFormField(
              controller: _lenderController,
              decoration: InputDecoration(
                labelText: _direction == LoanDirection.borrowed
                    ? 'Lender Name'
                    : 'Borrower Name',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),

            // Account Number
            TextFormField(
              controller: _accountController,
              decoration: const InputDecoration(
                labelText: 'Account Number (optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.numbers),
              ),
            ),
            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notes),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Save
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                _isEditing ? 'Update Loan' : 'Save Loan',
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
// 4. AddRepaymentPage
// ─────────────────────────────────────────────────────────────────────────────

class AddRepaymentPage extends StatefulWidget {
  final String loanId;
  final int nextMonthNumber;
  final double emiAmount;
  final bool isPartPayment;

  const AddRepaymentPage({
    Key? key,
    required this.loanId,
    required this.nextMonthNumber,
    this.emiAmount = 0,
    this.isPartPayment = false,
  }) : super(key: key);

  @override
  State<AddRepaymentPage> createState() => _AddRepaymentPageState();
}

class _AddRepaymentPageState extends State<AddRepaymentPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _monthController;
  late final TextEditingController _amountController;
  final _principalController = TextEditingController();
  final _interestController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _paidDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _monthController = TextEditingController(
        text: widget.isPartPayment ? '0' : widget.nextMonthNumber.toString());
    _amountController = TextEditingController(
        text: widget.isPartPayment ? '' : widget.emiAmount.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _monthController.dispose();
    _amountController.dispose();
    _principalController.dispose();
    _interestController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountController.text);
    final repayment = Repayment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      monthNumber: widget.isPartPayment ? 0 : int.parse(_monthController.text),
      amount: amount,
      principalPortion: widget.isPartPayment
          ? amount
          : (_principalController.text.isNotEmpty
              ? double.tryParse(_principalController.text)
              : null),
      interestPortion: widget.isPartPayment
          ? 0
          : (_interestController.text.isNotEmpty
              ? double.tryParse(_interestController.text)
              : null),
      paidDate: _paidDate,
      notes: _notesController.text.trim().isEmpty
          ? (widget.isPartPayment ? 'Part payment' : null)
          : _notesController.text.trim(),
      isPartPayment: widget.isPartPayment,
    );

    Navigator.pop(context, repayment);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isPartPayment
            ? 'Part Payment'
            : 'Record EMI Payment'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Info banner
            if (widget.isPartPayment)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.savings_rounded,
                        color: Colors.green[700], size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Part payment reduces your outstanding principal directly',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.green[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Month number (EMI only)
            if (!widget.isPartPayment) ...[
              TextFormField(
                controller: _monthController,
                decoration: const InputDecoration(
                  labelText: 'Month Number *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.tag),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (int.tryParse(v) == null) return 'Invalid';
                  return null;
                },
              ),
              const SizedBox(height: 16),
            ],

            // Amount
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: widget.isPartPayment
                    ? 'Part Payment Amount *'
                    : 'EMI Amount *',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.currency_rupee),
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (double.tryParse(v) == null) return 'Invalid';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Principal/Interest split (EMI only)
            if (!widget.isPartPayment) ...[
              TextFormField(
                controller: _principalController,
                decoration: const InputDecoration(
                  labelText: 'Principal Portion (optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _interestController,
                decoration: const InputDecoration(
                  labelText: 'Interest Portion (optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.percent),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
            ],

            // Paid date
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: const Text('Paid Date'),
              subtitle: Text(DateFormat('dd MMM yyyy').format(_paidDate)),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _paidDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2040),
                );
                if (date != null) setState(() => _paidDate = date);
              },
            ),
            const Divider(),

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notes),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: widget.isPartPayment
                    ? Colors.green
                    : null,
              ),
              child: Text(
                widget.isPartPayment
                    ? 'Record Part Payment'
                    : 'Record EMI Payment',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
