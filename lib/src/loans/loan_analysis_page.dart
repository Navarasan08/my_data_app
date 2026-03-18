import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'package:my_data_app/src/loans/model/loan_model.dart';
import 'package:my_data_app/src/loans/cubit/loan_cubit.dart';
import 'package:my_data_app/src/loans/cubit/loan_state.dart';

final _currencyFormat = NumberFormat('#,##,###', 'en_IN');

String _fmt(double v) => '\u20B9${_currencyFormat.format(v.round())}';

class LoanAnalysisPage extends StatelessWidget {
  const LoanAnalysisPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loan Analysis'),
        centerTitle: true,
        elevation: 0,
      ),
      body: BlocBuilder<LoanCubit, LoanState>(
        builder: (context, state) {
          final cubit = context.read<LoanCubit>();
          final activeBorrowed = state.loans
              .where((l) =>
                  !l.isClosed && l.direction == LoanDirection.borrowed)
              .toList();

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              // 1. Overall Summary Cards
              _buildSectionTitle('Overall Summary'),
              Row(
                children: [
                  _summaryCard(
                    'Total Principal',
                    _fmt(activeBorrowed.fold(
                        0.0, (sum, l) => sum + l.principalAmount)),
                    Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  _summaryCard(
                    'Total Outstanding',
                    _fmt(cubit.totalBorrowed),
                    Colors.red,
                  ),
                  const SizedBox(width: 8),
                  _summaryCard(
                    'Monthly EMI',
                    _fmt(cubit.totalMonthlyEmi),
                    Colors.orange,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 2. Interest Overview
              _buildSectionTitle('Interest Overview'),
              Row(
                children: [
                  _summaryCard(
                    'Total Interest',
                    _fmt(cubit.totalInterestPaidAll +
                        cubit.totalInterestRemainingAll),
                    Colors.purple,
                  ),
                  const SizedBox(width: 8),
                  _summaryCard(
                    'Interest Paid',
                    _fmt(cubit.totalInterestPaidAll),
                    Colors.green,
                  ),
                  const SizedBox(width: 8),
                  _summaryCard(
                    'Interest Remaining',
                    _fmt(cubit.totalInterestRemainingAll),
                    Colors.orange,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 3. Interest Saved Banner
              if (cubit.totalInterestSavedAll > 0) ...[
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.savings_rounded, color: Colors.green.shade700),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${_fmt(cubit.totalInterestSavedAll)} saved from part payments!',
                          style: TextStyle(
                            color: Colors.green.shade800,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 4. Pie Chart - Loan Distribution by Type
              if (activeBorrowed.isNotEmpty) ...[
                _buildSectionTitle('Loan Distribution by Type'),
                _buildTypePieChart(activeBorrowed),
                const SizedBox(height: 16),
              ],

              // 5. Pie Chart - Principal vs Interest Split
              if (activeBorrowed.isNotEmpty) ...[
                _buildSectionTitle('Principal vs Interest Split'),
                _buildPrincipalInterestPie(activeBorrowed),
                const SizedBox(height: 16),
              ],

              // 6. Part Payment Benefit Analysis
              _buildPartPaymentSection(activeBorrowed),

              // 7. Per-Loan Amortization Summary
              if (activeBorrowed.isNotEmpty) ...[
                _buildSectionTitle('Per-Loan Summary'),
                ...activeBorrowed.map(_buildLoanAmortCard),
                const SizedBox(height: 16),
              ],

              // 8. Monthly EMI Breakdown Bar Chart
              if (activeBorrowed.isNotEmpty) ...[
                _buildSectionTitle('Monthly EMI Breakdown'),
                _buildEmiBarChart(activeBorrowed),
              ],

              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _summaryCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: color.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: color.shade700),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── 4. Type Pie Chart ──────────────────────────────────────────────────

  Widget _buildTypePieChart(List<Loan> loans) {
    final Map<LoanType, double> grouped = {};
    for (final loan in loans) {
      grouped[loan.type] = (grouped[loan.type] ?? 0) + loan.outstandingBalance;
    }
    final slices = grouped.entries
        .where((e) => e.value > 0)
        .map((e) => _PieSlice(e.key.label, e.value, e.key.color))
        .toList();

    if (slices.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 180,
            width: 180,
            child: CustomPaint(painter: _PieChartPainter(slices)),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: slices
                .map((s) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: s.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${s.label} (${_fmt(s.value)})',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  // ── 5. Principal vs Interest Pie ───────────────────────────────────────

  Widget _buildPrincipalInterestPie(List<Loan> loans) {
    final totalPrincipalPaid =
        loans.fold(0.0, (sum, l) => sum + l.totalPrincipalPaid);
    final totalInterestPaid =
        loans.fold(0.0, (sum, l) => sum + l.interestPaid);
    final remainingPrincipal =
        loans.fold(0.0, (sum, l) => sum + l.outstandingBalance);
    final remainingInterest =
        loans.fold(0.0, (sum, l) => sum + l.interestRemaining);

    final slices = <_PieSlice>[
      _PieSlice('Principal Paid', totalPrincipalPaid, Colors.blue),
      _PieSlice('Interest Paid', totalInterestPaid, Colors.orange),
      _PieSlice('Principal Remaining', remainingPrincipal, Colors.blue.shade200),
      _PieSlice('Interest Remaining', remainingInterest, Colors.orange.shade200),
    ].where((s) => s.value > 0).toList();

    if (slices.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 180,
            width: 180,
            child: CustomPaint(painter: _PieChartPainter(slices)),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: slices
                .map((s) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: s.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${s.label} (${_fmt(s.value)})',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  // ── 6. Part Payment Benefits ───────────────────────────────────────────

  Widget _buildPartPaymentSection(List<Loan> loans) {
    final loansWithPP = loans.where((l) => l.partPayments.isNotEmpty).toList();
    if (loansWithPP.isEmpty) return const SizedBox.shrink();

    final totalPP =
        loansWithPP.fold(0.0, (sum, l) => sum + l.totalPartPayments);
    final totalSaved =
        loansWithPP.fold(0.0, (sum, l) => sum + l.interestSaved);
    // Estimate months saved: interest saved / monthly interest cost
    final avgMonthlyInterest = loansWithPP.fold(0.0, (sum, l) {
      if (l.interestRate == 0) return sum;
      return sum + (l.outstandingBalance * l.interestRate / 12 / 100);
    });
    final monthsSaved =
        avgMonthlyInterest > 0 ? (totalSaved / avgMonthlyInterest).round() : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Part Payment Benefits'),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.teal.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.teal.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _miniStat('Total Part Payments', _fmt(totalPP), Colors.teal),
                  const SizedBox(width: 8),
                  _miniStat('Interest Saved', _fmt(totalSaved), Colors.green),
                  const SizedBox(width: 8),
                  _miniStat(
                      'Months Saved', '~$monthsSaved', Colors.deepPurple),
                ],
              ),
              const SizedBox(height: 12),
              ...loansWithPP.map((loan) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loan.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Part Payments: ${_fmt(loan.totalPartPayments)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          if (loan.partPayments.isNotEmpty)
                            Text(
                              'Strategy: ${loan.partPayments.last.strategy == PartPaymentStrategy.reduceEmi ? 'Reduce EMI' : 'Reduce Tenure'}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          Text(
                            'Interest Saved: ${_fmt(loan.interestSaved)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── 7. Per-Loan Amortization Summary ───────────────────────────────────

  Widget _buildLoanAmortCard(Loan loan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: loan.type.color.withAlpha(15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: loan.type.color.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(loan.type.icon, size: 18, color: loan.type.color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  loan.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
              Text(
                '${(loan.progressPercent * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: loan.type.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Mini progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: loan.progressPercent,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(loan.type.color),
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _amortLine(
                    'Principal Paid', _fmt(loan.totalPrincipalPaid)),
              ),
              Expanded(
                child: _amortLine(
                    'Principal Left', _fmt(loan.outstandingBalance)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child:
                    _amortLine('Interest Paid', _fmt(loan.interestPaid)),
              ),
              Expanded(
                child: _amortLine(
                    'Interest Left', _fmt(loan.interestRemaining)),
              ),
            ],
          ),
          if (loan.totalPartPayments > 0) ...[
            const SizedBox(height: 4),
            _amortLine('Part Payments', _fmt(loan.totalPartPayments)),
          ],
        ],
      ),
    );
  }

  Widget _amortLine(String label, String value) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 11, color: Colors.black87),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(color: Colors.black54),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // ── 8. EMI Bar Chart ───────────────────────────────────────────────────

  Widget _buildEmiBarChart(List<Loan> loans) {
    final maxEmi =
        loans.fold(0.0, (m, l) => l.emiAmount > m ? l.emiAmount : m);
    if (maxEmi == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: loans.map((loan) {
          final fraction = loan.emiAmount / maxEmi;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 80,
                  child: Text(
                    loan.name,
                    style: const TextStyle(fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        children: [
                          Container(
                            height: 18,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          Container(
                            height: 18,
                            width: constraints.maxWidth * fraction,
                            decoration: BoxDecoration(
                              color: loan.type.color,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _fmt(loan.emiAmount),
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Pie Chart Painter ──────────────────────────────────────────────────────

class _PieChartPainter extends CustomPainter {
  final List<_PieSlice> slices;
  _PieChartPainter(this.slices);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8;
    final total = slices.fold(0.0, (sum, s) => sum + s.value);
    if (total == 0) return;

    double startAngle = -math.pi / 2;
    for (final slice in slices) {
      final sweep = (slice.value / total) * 2 * math.pi;
      final paint = Paint()
        ..color = slice.color
        ..style = PaintingStyle.fill;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        true,
        paint,
      );
      // White separator
      final sepPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        true,
        sepPaint,
      );
      startAngle += sweep;
    }
    // Inner circle for donut effect
    canvas.drawCircle(center, radius * 0.55, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _PieSlice {
  final String label;
  final double value;
  final Color color;
  const _PieSlice(this.label, this.value, this.color);
}

// ── Color extension for shade access ───────────────────────────────────────

extension _ColorShade on Color {
  Color get shade700 {
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness((hsl.lightness * 0.6).clamp(0.0, 1.0)).toColor();
  }
}
