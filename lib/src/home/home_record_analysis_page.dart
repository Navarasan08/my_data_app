import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:my_data_app/src/home/home_record_model.dart';
import 'package:my_data_app/src/home/cubit/home_record_cubit.dart';
import 'package:my_data_app/src/home/cubit/home_record_state.dart';

class HomeRecordAnalysisPage extends StatefulWidget {
  const HomeRecordAnalysisPage({Key? key}) : super(key: key);

  @override
  State<HomeRecordAnalysisPage> createState() =>
      _HomeRecordAnalysisPageState();
}

class _HomeRecordAnalysisPageState extends State<HomeRecordAnalysisPage> {
  DateTimeRange? _dateRange;
  HomeCategory? _filterCategory;
  bool _isYearly = false;

  Map<HomeCategory, double> _getFilteredCategoryTotals(
      HomeRecordCubit cubit) {
    if (_dateRange != null) {
      final totals =
          cubit.categoryTotalsInRange(_dateRange!.start, _dateRange!.end);
      if (_filterCategory != null) {
        final val = totals[_filterCategory];
        if (val != null) return {_filterCategory!: val};
        return {};
      }
      return totals;
    }
    if (_isYearly) {
      final now = DateTime.now();
      final start = DateTime(now.year, 1, 1);
      final end = DateTime(now.year, 12, 31);
      final totals = cubit.categoryTotalsInRange(start, end);
      if (_filterCategory != null) {
        final val = totals[_filterCategory];
        if (val != null) return {_filterCategory!: val};
        return {};
      }
      return totals;
    }
    final totals = cubit.allTimeCategoryTotals();
    if (_filterCategory != null) {
      final val = totals[_filterCategory];
      if (val != null) return {_filterCategory!: val};
      return {};
    }
    return totals;
  }

  double _getFilteredTotal(Map<HomeCategory, double> totals) {
    return totals.values.fold(0.0, (sum, v) => sum + v);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeRecordCubit, HomeRecordState>(
      builder: (context, state) {
        final cubit = context.read<HomeRecordCubit>();
        final categoryTotals = _getFilteredCategoryTotals(cubit);
        final filteredTotal = _getFilteredTotal(categoryTotals);
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
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentMaxWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Summary Cards
                        _buildSummaryCards(cubit, filteredTotal, categoryTotals),
                        const SizedBox(height: 20),

                        // Filter Controls
                        _buildFilterControls(context),
                        const SizedBox(height: 20),

                        // Charts: side-by-side on wide screens
                        if (isWide) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildSectionTitle('Category Breakdown'),
                                    const SizedBox(height: 12),
                                    _buildPieChart(categoryTotals, filteredTotal),
                                    const SizedBox(height: 8),
                                    _buildPieLegend(categoryTotals, filteredTotal),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildSectionTitle('Top Categories'),
                                    const SizedBox(height: 12),
                                    _buildBarChart(categoryTotals),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _buildSectionTitle('Monthly Trend'),
                          const SizedBox(height: 12),
                          _buildLineChart(monthlyData),
                        ] else ...[
                          // Stacked on mobile
                          _buildSectionTitle('Category Breakdown'),
                          const SizedBox(height: 12),
                          _buildPieChart(categoryTotals, filteredTotal),
                          const SizedBox(height: 8),
                          _buildPieLegend(categoryTotals, filteredTotal),
                          const SizedBox(height: 24),

                          _buildSectionTitle('Monthly Trend'),
                          const SizedBox(height: 12),
                          _buildLineChart(monthlyData),
                          const SizedBox(height: 24),

                          _buildSectionTitle('Top Categories'),
                          const SizedBox(height: 12),
                          _buildBarChart(categoryTotals),
                        ],
                        const SizedBox(height: 32),
                      ],
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.grey[800],
      ),
    );
  }

  Widget _buildSummaryCards(HomeRecordCubit cubit, double filteredTotal,
      Map<HomeCategory, double> categoryTotals) {
    final highest = categoryTotals.isNotEmpty
        ? categoryTotals.entries.reduce((a, b) => a.value > b.value ? a : b)
        : null;

    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            icon: Icons.account_balance_wallet_rounded,
            label: 'Total Spent',
            value: '\$${filteredTotal.toStringAsFixed(0)}',
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryCard(
            icon: Icons.trending_up_rounded,
            label: 'Avg/Month',
            value: '\$${cubit.averagePerMonth.toStringAsFixed(0)}',
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryCard(
            icon: Icons.star_rounded,
            label: 'Top Category',
            value: highest?.key.displayName ?? '-',
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterControls(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Date Range Picker
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.date_range, size: 18),
                  label: Text(
                    _dateRange != null
                        ? '${DateFormat('MMM d').format(_dateRange!.start)} - ${DateFormat('MMM d').format(_dateRange!.end)}'
                        : 'Date Range',
                    style: const TextStyle(fontSize: 12),
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
              if (_dateRange != null) ...[
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
          Row(
            children: [
              // Category Filter
              Expanded(
                child: DropdownButtonFormField<HomeCategory?>(
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
                    ...HomeCategory.values.map((cat) {
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
              ),
              const SizedBox(width: 8),
              // Monthly/Yearly Toggle
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('All')),
                  ButtonSegment(value: true, label: Text('Year')),
                ],
                selected: {_isYearly},
                onSelectionChanged: (value) {
                  setState(() {
                    _isYearly = value.first;
                    if (_isYearly) _dateRange = null;
                  });
                },
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  textStyle: WidgetStatePropertyAll(
                    const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(
      Map<HomeCategory, double> totals, double grandTotal) {
    if (totals.isEmpty || grandTotal == 0) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'No data to display',
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
          ),
        ),
      );
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
      ),
    );
  }

  Widget _buildPieLegend(
      Map<HomeCategory, double> totals, double grandTotal) {
    if (totals.isEmpty) return const SizedBox();

    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: sorted.map((e) {
        final pct =
            grandTotal > 0 ? (e.value / grandTotal * 100) : 0.0;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: e.key.color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '${e.key.displayName} \$${e.value.toStringAsFixed(0)} (${pct.toStringAsFixed(1)}%)',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildLineChart(Map<DateTime, double> monthlyData) {
    final entries = monthlyData.entries.toList();
    if (entries.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'No data to display',
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
          ),
        ),
      );
    }

    final maxY = entries.map((e) => e.value).reduce(
        (a, b) => a > b ? a : b);
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
                reservedSize: 50,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '\$${value.toInt()}',
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
              return FlLine(
                color: Colors.grey[300]!,
                strokeWidth: 1,
              );
            },
          ),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  Widget _buildBarChart(Map<HomeCategory, double> totals) {
    if (totals.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'No data to display',
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
          ),
        ),
      );
    }

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
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(6)),
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
                reservedSize: 50,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '\$${value.toInt()}',
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
              return FlLine(
                color: Colors.grey[300]!,
                strokeWidth: 1,
              );
            },
          ),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryCard({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
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
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
