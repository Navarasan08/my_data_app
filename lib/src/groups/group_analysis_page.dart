import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:my_data_app/src/groups/cubit/group_cubit.dart';
import 'package:my_data_app/src/groups/cubit/group_state.dart';
import 'package:my_data_app/src/groups/model/group_model.dart';

final _money = NumberFormat('#,##,###.##', 'en_IN');

/// Time window for [GroupAnalysisPage]. A user-picked [DateTimeRange]
/// overrides this when present.
enum GroupAnalysisPeriod { thisMonth, lastMonth, year, all }

extension _PeriodX on GroupAnalysisPeriod {
  String get label {
    switch (this) {
      case GroupAnalysisPeriod.thisMonth:
        return 'This Month';
      case GroupAnalysisPeriod.lastMonth:
        return 'Last Month';
      case GroupAnalysisPeriod.year:
        return 'Year';
      case GroupAnalysisPeriod.all:
        return 'All Time';
    }
  }
}

/// Aggregated spend analysis for one group:
///  - period selector + custom range picker
///  - top summary (total spent / your paid / your share / your net)
///  - per-member breakdown (paid vs owed)
///  - category bar chart
///  - month trend bar chart
///
/// Reads everything off the cubit's in-memory cache so the page rebuilds
/// instantly when any member's snapshot listener fires.
class GroupAnalysisPage extends StatefulWidget {
  final String groupId;
  const GroupAnalysisPage({super.key, required this.groupId});

  @override
  State<GroupAnalysisPage> createState() => _GroupAnalysisPageState();
}

class _GroupAnalysisPageState extends State<GroupAnalysisPage> {
  GroupAnalysisPeriod _period = GroupAnalysisPeriod.thisMonth;
  DateTimeRange? _customRange;

  ({DateTime start, DateTime end, bool allTime}) _activeRange() {
    if (_customRange != null) {
      final end = DateTime(_customRange!.end.year, _customRange!.end.month,
          _customRange!.end.day, 23, 59, 59);
      return (start: _customRange!.start, end: end, allTime: false);
    }
    final now = DateTime.now();
    switch (_period) {
      case GroupAnalysisPeriod.thisMonth:
        return (
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
          allTime: false,
        );
      case GroupAnalysisPeriod.lastMonth:
        return (
          start: DateTime(now.year, now.month - 1, 1),
          end: DateTime(now.year, now.month, 0, 23, 59, 59),
          allTime: false,
        );
      case GroupAnalysisPeriod.year:
        return (
          start: DateTime(now.year, 1, 1),
          end: DateTime(now.year, 12, 31, 23, 59, 59),
          allTime: false,
        );
      case GroupAnalysisPeriod.all:
        return (
          start: DateTime(1970),
          end: DateTime(2100),
          allTime: true,
        );
    }
  }

  String _rangeLabel() {
    if (_customRange != null) {
      return '${DateFormat('d MMM').format(_customRange!.start)} – ${DateFormat('d MMM yyyy').format(_customRange!.end)}';
    }
    return _period.label;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return BlocBuilder<GroupCubit, GroupState>(
      builder: (context, state) {
        final cubit = context.read<GroupCubit>();
        final group = cubit.getGroup(widget.groupId);
        if (group == null) {
          return const Scaffold(
              body: Center(child: Text('Group not found')));
        }

        final range = _activeRange();
        final allExpenses = cubit.expensesFor(widget.groupId);
        final inRange = range.allTime
            ? allExpenses
            : allExpenses
                .where((e) =>
                    !e.date.isBefore(range.start) &&
                    !e.date.isAfter(range.end))
                .toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Analysis'),
            backgroundColor: group.color.withValues(alpha: 0.1),
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.date_range_rounded),
                tooltip: 'Custom range',
                onPressed: () async {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                    initialDateRange: _customRange,
                  );
                  if (picked != null) {
                    setState(() {
                      _customRange = picked;
                    });
                  }
                },
              ),
              if (_customRange != null)
                IconButton(
                  icon: const Icon(Icons.clear),
                  tooltip: 'Clear custom range',
                  onPressed: () => setState(() => _customRange = null),
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              if (_customRange == null)
                SegmentedButton<GroupAnalysisPeriod>(
                  segments: const [
                    ButtonSegment(
                        value: GroupAnalysisPeriod.thisMonth,
                        label: Text('Month')),
                    ButtonSegment(
                        value: GroupAnalysisPeriod.lastMonth,
                        label: Text('Last')),
                    ButtonSegment(
                        value: GroupAnalysisPeriod.year,
                        label: Text('Year')),
                    ButtonSegment(
                        value: GroupAnalysisPeriod.all,
                        label: Text('All')),
                  ],
                  selected: {_period},
                  onSelectionChanged: (s) =>
                      setState(() => _period = s.first),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.date_range, size: 16),
                      const SizedBox(width: 6),
                      Text(_rangeLabel(),
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              const SizedBox(height: 14),

              _SummarySection(
                group: group,
                expenses: inRange,
                myUid: cubit.currentUid,
              ),
              const SizedBox(height: 16),

              _SectionTitle(title: 'Per member'),
              _PerMemberBreakdown(group: group, expenses: inRange),
              const SizedBox(height: 16),

              if (_hasAnyCategory(inRange)) ...[
                _SectionTitle(title: 'Categories'),
                _CategoryChart(expenses: inRange, color: group.color),
                const SizedBox(height: 16),
              ],

              if (inRange.isNotEmpty) ...[
                _SectionTitle(title: 'Monthly trend'),
                _MonthlyTrendChart(
                    expenses: inRange, color: group.color),
                const SizedBox(height: 20),
              ] else
                _EmptyState(label: _rangeLabel()),
            ],
          ),
        );
      },
    );
  }

  bool _hasAnyCategory(List<GroupExpense> exps) =>
      exps.any((e) => (e.category ?? '').trim().isNotEmpty);
}

// ─── Summary cards ──────────────────────────────────────────────────────────

class _SummarySection extends StatelessWidget {
  final GroupFund group;
  final List<GroupExpense> expenses;
  final String myUid;
  const _SummarySection({
    required this.group,
    required this.expenses,
    required this.myUid,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final total = expenses.fold<double>(0, (s, e) => s + e.amount);
    final myPaid = expenses
        .where((e) => e.paidByUid == myUid)
        .fold<double>(0, (s, e) => s + e.amount);
    final myShare = expenses.fold<double>(0, (s, e) {
      return s +
          e.splits
              .where((sp) => sp.uid == myUid)
              .fold<double>(0, (a, sp) => a + sp.owed);
    });
    final myNet = myPaid - myShare;

    return Column(
      children: [
        _StatTile(
          label: 'Total spent',
          value: '₹${_money.format(total)}',
          icon: Icons.receipt_long_rounded,
          color: group.color,
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: 'You paid',
                value: '₹${_money.format(myPaid)}',
                icon: Icons.payments_rounded,
                color: Colors.blue[700]!,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _StatTile(
                label: 'Your share',
                value: '₹${_money.format(myShare)}',
                icon: Icons.pie_chart_rounded,
                color: Colors.orange[700]!,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _StatTile(
          label: myNet >= 0 ? 'You lent (net)' : 'You owe (net)',
          value: '₹${_money.format(myNet.abs())}',
          icon: myNet >= 0
              ? Icons.trending_up_rounded
              : Icons.trending_down_rounded,
          color: myNet >= 0 ? Colors.green[700]! : Colors.red[700]!,
          subtitle: myNet.abs() < 0.01
              ? Text(
                  'Even on this slice',
                  style: TextStyle(
                      fontSize: 11, color: cs.onSurfaceVariant),
                )
              : null,
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Widget? subtitle;
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 11, color: cs.onSurfaceVariant)),
                Text(value,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color)),
                if (subtitle != null) subtitle!,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Per-member ─────────────────────────────────────────────────────────────

class _PerMemberBreakdown extends StatelessWidget {
  final GroupFund group;
  final List<GroupExpense> expenses;
  const _PerMemberBreakdown({required this.group, required this.expenses});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (expenses.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text('Nothing to break down.',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
      );
    }
    final paidByMember = <String, double>{};
    final owedByMember = <String, double>{};
    for (final e in expenses) {
      paidByMember[e.paidByUid] =
          (paidByMember[e.paidByUid] ?? 0) + e.amount;
      for (final s in e.splits) {
        owedByMember[s.uid] = (owedByMember[s.uid] ?? 0) + s.owed;
      }
    }
    final maxValue = [
      ...paidByMember.values,
      ...owedByMember.values,
    ].fold<double>(0, (m, v) => v > m ? v : m);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: group.memberIds.map((uid) {
          final m = group.members[uid];
          final paid = paidByMember[uid] ?? 0;
          final owed = owedByMember[uid] ?? 0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(m?.label ?? uid,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                    Text(
                      'paid ₹${_money.format(paid)} · owes ₹${_money.format(owed)}',
                      style: TextStyle(
                          fontSize: 11, color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                _DualBar(
                  paidFraction: maxValue == 0 ? 0 : paid / maxValue,
                  owedFraction: maxValue == 0 ? 0 : owed / maxValue,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DualBar extends StatelessWidget {
  final double paidFraction;
  final double owedFraction;
  const _DualBar({required this.paidFraction, required this.owedFraction});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: paidFraction.clamp(0.0, 1.0),
            minHeight: 5,
            backgroundColor: cs.surfaceContainerHighest,
            valueColor:
                AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
          ),
        ),
        const SizedBox(height: 2),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: owedFraction.clamp(0.0, 1.0),
            minHeight: 5,
            backgroundColor: cs.surfaceContainerHighest,
            valueColor:
                AlwaysStoppedAnimation<Color>(Colors.orange[700]!),
          ),
        ),
      ],
    );
  }
}

// ─── Category chart ─────────────────────────────────────────────────────────

class _CategoryChart extends StatelessWidget {
  final List<GroupExpense> expenses;
  final Color color;
  const _CategoryChart({required this.expenses, required this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final byCat = <String, double>{};
    for (final e in expenses) {
      final cat = (e.category ?? '').trim();
      final key = cat.isEmpty ? 'Uncategorized' : cat;
      byCat[key] = (byCat[key] ?? 0) + e.amount;
    }
    final entries = byCat.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxVal = entries.first.value;
    final total = entries.fold<double>(0, (s, e) => s + e.value);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: entries.map((e) {
          final pct = total == 0 ? 0 : e.value / total * 100;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(e.key,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                    Text(
                      '₹${_money.format(e.value)}  (${pct.toStringAsFixed(0)}%)',
                      style: TextStyle(
                          fontSize: 11, color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: maxVal == 0 ? 0 : e.value / maxVal,
                    minHeight: 6,
                    backgroundColor: cs.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Monthly trend (bar chart) ──────────────────────────────────────────────

class _MonthlyTrendChart extends StatelessWidget {
  final List<GroupExpense> expenses;
  final Color color;
  const _MonthlyTrendChart({required this.expenses, required this.color});

  @override
  Widget build(BuildContext context) {
    // Bucket by (year, month).
    final buckets = <DateTime, double>{};
    for (final e in expenses) {
      final key = DateTime(e.date.year, e.date.month);
      buckets[key] = (buckets[key] ?? 0) + e.amount;
    }
    if (buckets.isEmpty) return const SizedBox.shrink();
    final sortedKeys = buckets.keys.toList()..sort();
    final maxVal = buckets.values.fold<double>(0, (m, v) => v > m ? v : m);

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: SizedBox(
        height: 180,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxVal == 0 ? 1 : maxVal * 1.15,
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (value, meta) {
                    final i = value.toInt();
                    if (i < 0 || i >= sortedKeys.length) {
                      return const SizedBox.shrink();
                    }
                    final d = sortedKeys[i];
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(DateFormat('MMM').format(d),
                          style: const TextStyle(fontSize: 10)),
                    );
                  },
                ),
              ),
            ),
            barGroups: [
              for (var i = 0; i < sortedKeys.length; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: buckets[sortedKeys[i]] ?? 0,
                      color: color,
                      width: 16,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4)),
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

// ─── Misc ──────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 4),
      child: Text(title,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: cs.onSurface)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String label;
  const _EmptyState({required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.bar_chart_rounded,
                size: 48, color: cs.outlineVariant),
            const SizedBox(height: 8),
            Text('No expenses in "$label"',
                style: TextStyle(
                    fontSize: 13, color: cs.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
