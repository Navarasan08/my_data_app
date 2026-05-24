import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:my_data_app/src/home/home_record_model.dart';
import 'package:my_data_app/src/home/cubit/home_record_cubit.dart';
import 'package:my_data_app/src/home/cubit/home_record_state.dart';
import 'package:my_data_app/src/home/home_record_page.dart' show AddHomeRecordPage;

/// Quick-pick time window for the analysis page. A user-set [DateTimeRange]
/// overrides this when present.
enum AnalysisPeriod { thisMonth, lastMonth, year, all }

extension _AnalysisPeriodX on AnalysisPeriod {
  /// Short label used in the segmented control and section subtitles.
  String get label {
    switch (this) {
      case AnalysisPeriod.thisMonth:
        return 'This Month';
      case AnalysisPeriod.lastMonth:
        return 'Last Month';
      case AnalysisPeriod.year:
        return 'Year';
      case AnalysisPeriod.all:
        return 'All';
    }
  }
}

class HomeRecordAnalysisPage extends StatefulWidget {
  const HomeRecordAnalysisPage({Key? key}) : super(key: key);

  @override
  State<HomeRecordAnalysisPage> createState() =>
      _HomeRecordAnalysisPageState();
}

class _HomeRecordAnalysisPageState extends State<HomeRecordAnalysisPage> {
  DateTimeRange? _dateRange;
  HomeCategory? _filterCategory;
  AnalysisPeriod _period = AnalysisPeriod.thisMonth;

  /// Resolved [start, end] window for the current selection. When the user
  /// has picked a [DateTimeRange] explicitly it wins; otherwise we derive
  /// the window from [_period]. The `allTime` flag tells the caller it can
  /// short-circuit to the cubit's all-time aggregates.
  ({DateTime start, DateTime end, bool allTime}) _activeRange() {
    if (_dateRange != null) {
      // showDateRangePicker's end-date is the start-of-day — bump to
      // end-of-day so a same-day range matches all records that day.
      final end = DateTime(_dateRange!.end.year, _dateRange!.end.month,
          _dateRange!.end.day, 23, 59, 59);
      return (start: _dateRange!.start, end: end, allTime: false);
    }
    final now = DateTime.now();
    switch (_period) {
      case AnalysisPeriod.thisMonth:
        return (
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
          allTime: false,
        );
      case AnalysisPeriod.lastMonth:
        return (
          start: DateTime(now.year, now.month - 1, 1),
          end: DateTime(now.year, now.month, 0, 23, 59, 59),
          allTime: false,
        );
      case AnalysisPeriod.year:
        return (
          start: DateTime(now.year, 1, 1),
          end: DateTime(now.year, 12, 31, 23, 59, 59),
          allTime: false,
        );
      case AnalysisPeriod.all:
        return (
          start: DateTime(1970),
          end: DateTime(2100),
          allTime: true,
        );
    }
  }

  String _activeRangeLabel() {
    if (_dateRange != null) {
      return '${DateFormat('d MMM').format(_dateRange!.start)} – ${DateFormat('d MMM yyyy').format(_dateRange!.end)}';
    }
    return _period.label;
  }

  Map<HomeCategory, double> _categoryTotals(HomeRecordCubit cubit) {
    final r = _activeRange();
    final base = r.allTime
        ? cubit.allTimeCategoryTotals()
        : cubit.categoryTotalsInRange(r.start, r.end);
    if (_filterCategory != null) {
      final v = base[_filterCategory!];
      return v != null ? {_filterCategory!: v} : {};
    }
    return base;
  }

  Map<PaymentType, double> _paymentTotals(HomeRecordCubit cubit) {
    final r = _activeRange();
    return cubit.paymentTotalsInRange(
      r.start,
      r.end,
      category: _filterCategory,
    );
  }

  int _untaggedPaymentCount(HomeRecordCubit cubit) {
    final r = _activeRange();
    return cubit.countUntaggedPaymentsInRange(
      r.start,
      r.end,
      category: _filterCategory,
    );
  }

  /// Key used to invalidate the [AnimatedSwitcher]s when any filter
  /// dimension changes — the new charts/lists cross-fade in.
  Object _filterKey() => Object.hash(
        _period,
        _dateRange?.start,
        _dateRange?.end,
        _filterCategory?.id,
      );

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeRecordCubit, HomeRecordState>(
      builder: (context, state) {
        final cubit = context.read<HomeRecordCubit>();
        final categoryTotals = _categoryTotals(cubit);
        final filteredTotal =
            categoryTotals.values.fold<double>(0, (s, v) => s + v);
        final paymentTotals = _paymentTotals(cubit);
        final paymentTotal =
            paymentTotals.values.fold<double>(0, (s, v) => s + v);
        final untaggedCount = _untaggedPaymentCount(cubit);
        final monthlyData = cubit.monthlyTotals(months: 12);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Spending Analysis'),
            centerTitle: true,
            elevation: 0,
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final isWide = width > 700;
              final contentMaxWidth = isWide ? 1100.0 : double.infinity;

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentMaxWidth),
                    child: _FadeSlideIn(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFilterControls(
                              context, cubit.categoriesByUsage),
                          const SizedBox(height: 20),

                          // Charts swap with a cross-fade whenever the
                          // filter changes.
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 320),
                            switchInCurve: Curves.easeOut,
                            child: Column(
                              key: ValueKey(_filterKey()),
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (isWide)
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _buildSectionTitle(
                                              'Category Breakdown',
                                              subtitle: _activeRangeLabel(),
                                              trailing: _TotalExpenseLabel(
                                                amount: cubit
                                                    .formatAmount(filteredTotal),
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            _buildPieChart(categoryTotals,
                                                filteredTotal),
                                            const SizedBox(height: 8),
                                            _buildPieLegend(
                                              categoryTotals,
                                              filteredTotal,
                                              cubit,
                                              cubit.categoryQuantities,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 24),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _buildSectionTitle(
                                                'Top Categories'),
                                            const SizedBox(height: 12),
                                            _buildBarChart(
                                                categoryTotals, cubit),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                else ...[
                                  _buildSectionTitle(
                                    'Category Breakdown',
                                    subtitle: _activeRangeLabel(),
                                    trailing: _TotalExpenseLabel(
                                      amount: cubit
                                          .formatAmount(filteredTotal),
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  _buildPieChart(categoryTotals, filteredTotal),
                                  const SizedBox(height: 8),
                                  _buildPieLegend(
                                    categoryTotals,
                                    filteredTotal,
                                    cubit,
                                    cubit.categoryQuantities,
                                  ),
                                ],
                                const SizedBox(height: 24),

                                _buildSectionTitle('Payment Method',
                                    subtitle: _activeRangeLabel()),
                                const SizedBox(height: 12),
                                _buildPaymentBreakdown(
                                  paymentTotals,
                                  paymentTotal,
                                  untaggedCount,
                                  cubit,
                                ),
                                const SizedBox(height: 24),

                                _buildSectionTitle('Monthly Trend'),
                                const SizedBox(height: 12),
                                _buildLineChart(monthlyData, cubit),

                                if (!isWide) ...[
                                  const SizedBox(height: 24),
                                  _buildSectionTitle('Top Categories'),
                                  const SizedBox(height: 12),
                                  _buildBarChart(categoryTotals, cubit),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ── Section helpers ─────────────────────────────────────────────────────

  Widget _buildSectionTitle(String title,
      {String? subtitle, Widget? trailing}) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              '· $subtitle',
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
        if (trailing != null) ...[
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(bottom: 1),
            child: trailing,
          ),
        ],
      ],
    );
  }

  Widget _buildFilterControls(
      BuildContext context, List<HomeCategory> allCategories) {
    final cs = Theme.of(context).colorScheme;
    final hasRange = _dateRange != null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Segmented period picker. Selection is empty when a custom date
          // range is active so no segment looks "wrong-selected".
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<AnalysisPeriod>(
              segments: AnalysisPeriod.values
                  .map((p) => ButtonSegment<AnalysisPeriod>(
                        value: p,
                        label: Text(p.label),
                      ))
                  .toList(),
              selected:
                  hasRange ? <AnalysisPeriod>{} : <AnalysisPeriod>{_period},
              emptySelectionAllowed: true,
              showSelectedIcon: false,
              onSelectionChanged: (values) {
                if (values.isEmpty) return;
                setState(() {
                  _period = values.first;
                  _dateRange = null;
                });
              },
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: const WidgetStatePropertyAll(
                  TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.date_range, size: 18),
                  label: Text(
                    hasRange
                        ? '${DateFormat('d MMM').format(_dateRange!.start)} – ${DateFormat('d MMM').format(_dateRange!.end)}'
                        : 'Date Range',
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        hasRange ? Colors.blue[700] : null,
                    side: hasRange
                        ? BorderSide(color: Colors.blue[300]!)
                        : null,
                  ),
                  onPressed: () async {
                    final range = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                      initialDateRange: _dateRange,
                    );
                    if (range != null) {
                      setState(() => _dateRange = range);
                    }
                  },
                ),
              ),
              if (hasRange) ...[
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () => setState(() => _dateRange = null),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<HomeCategory?>(
            initialValue: _filterCategory,
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('All Categories'),
              ),
              ...allCategories.map((cat) {
                return DropdownMenuItem(
                  value: cat,
                  child: Row(
                    children: [
                      Icon(cat.icon, size: 16, color: cat.color),
                      const SizedBox(width: 6),
                      Text(cat.displayName,
                          style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                );
              }),
            ],
            onChanged: (value) {
              setState(() => _filterCategory = value);
            },
          ),
        ],
      ),
    );
  }

  // ── Chart builders ──────────────────────────────────────────────────────

  Widget _buildPieChart(
      Map<HomeCategory, double> totals, double grandTotal) {
    if (totals.isEmpty || grandTotal == 0) {
      return _emptyChart('No data in this period');
    }

    return SizedBox(
      height: 220,
      child: PieChart(
        PieChartData(
          sections: totals.entries.map((e) {
            final percentage = (e.value / grandTotal * 100);
            return PieChartSectionData(
              value: e.value,
              title: percentage >= 5
                  ? '${percentage.toStringAsFixed(1)}%'
                  : '',
              color: e.key.color,
              radius: 85,
              titleStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          }).toList(),
          sectionsSpace: 2,
          centerSpaceRadius: 35,
        ),
        // fl_chart animates section-value changes when this duration is set.
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  Widget _buildPieLegend(
      Map<HomeCategory, double> totals,
      double grandTotal,
      HomeRecordCubit cubit,
      Map<HomeCategory, Map<MeasureUnit, double>> categoryQuantities) {
    if (totals.isEmpty) return const SizedBox();

    final cs = Theme.of(context).colorScheme;
    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sorted.map((e) {
        final pct = grandTotal > 0 ? (e.value / grandTotal * 100) : 0.0;
        final quantities = categoryQuantities[e.key];
        final qtyParts = <String>[];
        if (quantities != null) {
          for (final entry in quantities.entries) {
            final qStr = entry.value % 1 == 0
                ? entry.value.toInt().toString()
                : entry.value.toStringAsFixed(1);
            qtyParts.add('$qStr ${entry.key.label}');
          }
        }

        return InkWell(
          onTap: () => _showCategoryRecords(context, cubit, e.key),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: e.key.color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${e.key.displayName}  ',
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        TextSpan(
                          text:
                              '${cubit.formatAmount(e.value)} (${pct.toStringAsFixed(1)}%)',
                          style: const TextStyle(fontSize: 12),
                        ),
                        if (qtyParts.isNotEmpty)
                          TextSpan(
                            text: '  ·  ${qtyParts.join(', ')}',
                            style: TextStyle(
                                fontSize: 11, color: cs.onSurfaceVariant),
                          ),
                      ],
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    size: 16, color: cs.onSurfaceVariant),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPaymentBreakdown(
    Map<PaymentType, double> totals,
    double grandTotal,
    int untaggedCount,
    HomeRecordCubit cubit,
  ) {
    final cs = Theme.of(context).colorScheme;
    if (totals.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(Icons.payments_rounded,
                color: cs.onSurfaceVariant, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                untaggedCount > 0
                    ? 'No tagged records yet. $untaggedCount record${untaggedCount == 1 ? '' : 's'} in this period have no payment method.'
                    : 'No data in this period',
                style:
                    TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...sorted.map((e) {
            final pct = grandTotal > 0 ? (e.value / grandTotal * 100) : 0.0;
            return InkWell(
              onTap: () => _showPaymentTypeRecords(context, cubit, e.key),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: e.key.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(e.key.icon,
                          color: e.key.color, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.key.displayName,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: pct / 100),
                            duration:
                                const Duration(milliseconds: 500),
                            curve: Curves.easeOutCubic,
                            builder: (_, t, _) {
                              return ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: t,
                                  minHeight: 6,
                                  backgroundColor:
                                      cs.surfaceContainerHighest,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(
                                          e.key.color),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          cubit.formatAmount(e.value),
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '${pct.toStringAsFixed(1)}%',
                          style: TextStyle(
                              fontSize: 11, color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.chevron_right_rounded,
                        size: 16, color: cs.onSurfaceVariant),
                  ],
                ),
              ),
            );
          }),
          if (untaggedCount > 0) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                '$untaggedCount record${untaggedCount == 1 ? '' : 's'} in this period without a payment method.',
                style:
                    TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLineChart(
      Map<DateTime, double> monthlyData, HomeRecordCubit cubit) {
    final cs = Theme.of(context).colorScheme;
    final entries = monthlyData.entries.toList();
    if (entries.isEmpty) return _emptyChart('No data to display');

    final maxY =
        entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final yMax = maxY == 0 ? 100.0 : maxY * 1.2;

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: yMax,
          lineBarsData: [
            LineChartBarData(
              spots: entries.asMap().entries.map((e) {
                return FlSpot(e.key.toDouble(), e.value.value);
              }).toList(),
              isCurved: true,
              color: Colors.green[600],
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.green.withValues(alpha: 0.1),
              ),
            ),
          ],
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= entries.length) {
                    return const SizedBox();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      DateFormat('MMM').format(entries[idx].key),
                      style:
                          const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 60,
                getTitlesWidget: (value, meta) {
                  return Text(
                    cubit.formatAmount(value),
                    style:
                        const TextStyle(fontSize: 10, color: Colors.grey),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: yMax / 4,
            getDrawingHorizontalLine: (value) {
              return FlLine(color: cs.outlineVariant, strokeWidth: 1);
            },
          ),
          borderData: FlBorderData(show: false),
        ),
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  Widget _buildBarChart(
      Map<HomeCategory, double> totals, HomeRecordCubit cubit) {
    final cs = Theme.of(context).colorScheme;
    if (totals.isEmpty) return _emptyChart('No data to display');

    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final maxVal = sorted.first.value;
    final yMax = maxVal == 0 ? 100.0 : maxVal * 1.2;

    return SizedBox(
      height: 250,
      child: BarChart(
        BarChartData(
          maxY: yMax,
          barGroups: sorted.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value.value,
                  color: e.value.key.color,
                  width: sorted.length <= 5 ? 28 : 18,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(6)),
                ),
              ],
            );
          }).toList(),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= sorted.length) {
                    return const SizedBox();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      sorted[idx].key.displayName,
                      style: const TextStyle(fontSize: 9),
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 60,
                getTitlesWidget: (value, meta) {
                  return Text(
                    cubit.formatAmount(value),
                    style:
                        const TextStyle(fontSize: 10, color: Colors.grey),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: yMax / 4,
            getDrawingHorizontalLine: (value) {
              return FlLine(color: cs.outlineVariant, strokeWidth: 1);
            },
          ),
          borderData: FlBorderData(show: false),
        ),
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  Widget _emptyChart(String message) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 200,
      child: Center(
        child: Text(
          message,
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 15),
        ),
      ),
    );
  }

  // ── Records sheets ──────────────────────────────────────────────────────

  void _showCategoryRecords(
      BuildContext context, HomeRecordCubit cubit, HomeCategory cat) {
    final r = _activeRange();
    final records = cubit.recordsInRange(r.start, r.end, category: cat);
    _showRecordsSheet(
      context,
      cubit: cubit,
      title: cat.displayName,
      subtitle: _activeRangeLabel(),
      accentColor: cat.color,
      icon: cat.icon,
      records: records,
    );
  }

  void _showPaymentTypeRecords(
      BuildContext context, HomeRecordCubit cubit, PaymentType type) {
    final r = _activeRange();
    final records = cubit.recordsInRange(
      r.start,
      r.end,
      paymentTypeId: type.id,
      category: _filterCategory,
    );
    _showRecordsSheet(
      context,
      cubit: cubit,
      title: type.displayName,
      subtitle: _activeRangeLabel(),
      accentColor: type.color,
      icon: type.icon,
      records: records,
    );
  }

  void _showRecordsSheet(
    BuildContext context, {
    required HomeRecordCubit cubit,
    required String title,
    required String subtitle,
    required Color accentColor,
    required IconData icon,
    required List<HomeRecord> records,
  }) {
    final total = records.fold<double>(0, (s, r) => s + r.amount);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) {
        final cs = Theme.of(sheetCtx).colorScheme;
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) => Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child:
                          Icon(icon, color: accentColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '$subtitle  ·  ${records.length} record${records.length == 1 ? '' : 's'}',
                            style: TextStyle(
                                fontSize: 12, color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      cubit.formatAmount(total),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[700],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: records.isEmpty
                    ? Center(
                        child: Text(
                          'No records to show',
                          style: TextStyle(
                              color: cs.onSurfaceVariant, fontSize: 14),
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        itemCount: records.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 6),
                        itemBuilder: (_, i) {
                          final r = records[i];
                          return _RecordListTile(
                            record: r,
                            cubit: cubit,
                            onTap: () async {
                              // Close the sheet first — its cached `records`
                              // list won't reflect the edit, so dismissing
                              // avoids showing stale data.
                              Navigator.pop(sheetCtx);
                              final edited = await Navigator.push<HomeRecord>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BlocProvider.value(
                                    value: cubit,
                                    child: AddHomeRecordPage(
                                      record: r,
                                      categories: cubit.allCategories,
                                      paymentTypes: cubit.paymentTypes,
                                    ),
                                  ),
                                ),
                              );
                              if (edited != null) {
                                cubit.updateRecord(edited);
                              }
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────

/// One-shot fade + slide-up wrapper used to give the analysis page a soft
/// entrance animation when it first appears.
class _FadeSlideIn extends StatelessWidget {
  final Widget child;
  const _FadeSlideIn({required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (_, t, c) {
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 16),
            child: c,
          ),
        );
      },
      child: child,
    );
  }
}

/// Minimal trailing label for the Category Breakdown section title. Uses an
/// expense-red treatment with a subtle down-arrow to make the "spent" framing
/// obvious without taking visual weight away from the chart.
class _TotalExpenseLabel extends StatelessWidget {
  final String amount;
  const _TotalExpenseLabel({required this.amount});

  @override
  Widget build(BuildContext context) {
    final color = Colors.red.shade700;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Icon(Icons.arrow_downward_rounded, size: 14, color: color),
        const SizedBox(width: 2),
        Text(
          amount,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Compact record tile used inside the records bottom sheet. Tap to edit the
/// underlying record — see [_showRecordsSheet] for the handler.
class _RecordListTile extends StatelessWidget {
  final HomeRecord record;
  final HomeRecordCubit cubit;
  final VoidCallback? onTap;
  const _RecordListTile({
    required this.record,
    required this.cubit,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: record.category.color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(color: record.category.color, width: 3),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
        children: [
          Icon(record.category.icon, size: 18, color: record.category.color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    DateFormat('d MMM yyyy').format(record.date),
                    if (record.paymentType != null)
                      record.paymentType!.displayName,
                    if (record.quantityLabel.isNotEmpty) record.quantityLabel,
                  ].join('  ·  '),
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
            Text(
              cubit.formatAmount(record.amount),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.red[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
