import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:my_data_app/src/diet/cubit/diet_cubit.dart';
import 'package:my_data_app/src/diet/cubit/diet_state.dart';
import 'package:my_data_app/src/diet/model/diet_model.dart';

class DietAnalysisPage extends StatefulWidget {
  const DietAnalysisPage({super.key});

  @override
  State<DietAnalysisPage> createState() => _DietAnalysisPageState();
}

class _DietAnalysisPageState extends State<DietAnalysisPage> {
  String? _selectedItemId;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return BlocBuilder<DietCubit, DietState>(
      builder: (context, state) {
        final cubit = context.read<DietCubit>();
        // Default the trend selector to the first item once items exist.
        if (_selectedItemId == null && state.items.isNotEmpty) {
          _selectedItemId = state.items.first.id;
        }
        final selectedItem = _selectedItemId == null
            ? null
            : cubit.itemById(_selectedItemId!);

        final totals = cubit.totalsLastNMonths(months: 12);
        final sorted = totals.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final totalAll = totals.values.fold<double>(0, (s, v) => s + v);

        final monthlyEntriesCount = cubit.entriesThisMonthCount;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Diet Analysis'),
            centerTitle: true,
            elevation: 0,
          ),
          body: _FadeSlideIn(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _summaryCards(state, monthlyEntriesCount, totalAll),
                  const SizedBox(height: 20),

                  _sectionTitle(context, 'Top items',
                      subtitle: 'Last 12 months'),
                  const SizedBox(height: 10),
                  if (sorted.isEmpty)
                    _emptyBox(context, 'No entries yet')
                  else
                    _topItemsList(context, sorted, totalAll, cubit),
                  const SizedBox(height: 24),

                  _sectionTitle(context, 'Monthly trend'),
                  const SizedBox(height: 10),
                  if (state.items.isEmpty)
                    _emptyBox(context, 'Add some items first')
                  else ...[
                    _itemPicker(state.items),
                    const SizedBox(height: 8),
                    if (selectedItem != null)
                      _trendChart(context, selectedItem, cubit)
                    else
                      _emptyBox(context, 'Pick an item to see its trend'),
                  ],

                  const SizedBox(height: 24),
                  _sectionTitle(context, 'This month'),
                  const SizedBox(height: 10),
                  _monthBreakdown(context, state, cubit),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Summary cards ───────────────────────────────────────────────────────

  Widget _summaryCards(DietState state, int entriesThisMonth, double total12) {
    final monthLabel = DateFormat('MMM yyyy').format(state.selectedMonth);
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            icon: Icons.restaurant_menu_rounded,
            label: 'Items',
            value: '${state.items.length}',
            color: Colors.indigo,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryCard(
            icon: Icons.event_repeat_rounded,
            label: 'Entries · $monthLabel',
            value: '$entriesThisMonth',
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryCard(
            icon: Icons.bar_chart_rounded,
            label: 'Total 12 mo.',
            value: _fmtQty(total12),
            color: Colors.deepOrange,
          ),
        ),
      ],
    );
  }

  // ── Top items leaderboard ───────────────────────────────────────────────

  Widget _topItemsList(
    BuildContext context,
    List<MapEntry<String, double>> sorted,
    double total,
    DietCubit cubit,
  ) {
    final cs = Theme.of(context).colorScheme;
    final top = sorted.take(8).toList();
    return Column(
      children: top.map((e) {
        final item = cubit.itemById(e.key);
        if (item == null) return const SizedBox.shrink();
        final pct = total > 0 ? (e.value / total * 100) : 0;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(item.icon, color: item.color, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: total > 0 ? e.value / total : 0),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                      builder: (_, t, _) => ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: t,
                          minHeight: 6,
                          backgroundColor: cs.surfaceContainerHighest,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(item.color),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    item.quantityLabel(e.value),
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '${pct.toStringAsFixed(1)}%',
                    style:
                        TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── Item picker + trend chart ───────────────────────────────────────────

  Widget _itemPicker(List<FoodItem> items) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: items.map((i) {
          final selected = _selectedItemId == i.id;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              avatar: Icon(i.icon, size: 14, color: i.color),
              label: Text(i.name, style: const TextStyle(fontSize: 12)),
              selected: selected,
              onSelected: (_) => setState(() => _selectedItemId = i.id),
              showCheckmark: false,
              selectedColor: i.color.withValues(alpha: 0.2),
              visualDensity: VisualDensity.compact,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _trendChart(BuildContext context, FoodItem item, DietCubit cubit) {
    final cs = Theme.of(context).colorScheme;
    final series = cubit.monthlySeries(item.id);
    final entries = series.entries.toList();
    final hasAny = entries.any((e) => e.value > 0);
    if (!hasAny) return _emptyBox(context, 'No entries in the last 12 months');

    final maxY = entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final yMax = maxY == 0 ? 1.0 : maxY * 1.2;

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          maxY: yMax,
          barGroups: entries.asMap().entries.map((idx) {
            return BarChartGroupData(
              x: idx.key,
              barRods: [
                BarChartRodData(
                  toY: idx.value.value,
                  color: item.color,
                  width: 16,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }).toList(),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (v, _) => Text(
                  _fmtQty(v),
                  style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= entries.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      DateFormat('MMM').format(entries[i].key),
                      style: TextStyle(
                          fontSize: 10, color: cs.onSurfaceVariant),
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: yMax / 4,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: cs.outlineVariant, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
        ),
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  // ── Selected-month breakdown ────────────────────────────────────────────

  Widget _monthBreakdown(BuildContext context, DietState state, DietCubit cubit) {
    final cs = Theme.of(context).colorScheme;
    final consumed = cubit.consumedInMonth(
        state.selectedMonth.year, state.selectedMonth.month);
    if (state.items.isEmpty) return _emptyBox(context, 'No items yet');
    final monthLabel =
        DateFormat('MMMM yyyy').format(state.selectedMonth);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    size: 14, color: cs.onSurface),
                const SizedBox(width: 6),
                Text(
                  monthLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
          ...state.items.map((item) {
            final used = consumed[item.id] ?? 0;
            final limit = item.monthlyLimit;
            final exceeded = limit != null && used > limit;
            final ratio = limit != null && limit > 0
                ? (used / limit).clamp(0, 1).toDouble()
                : 0.0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(item.icon, size: 16, color: item.color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 3),
                        if (limit != null)
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: ratio),
                            duration: const Duration(milliseconds: 450),
                            curve: Curves.easeOutCubic,
                            builder: (_, t, _) => ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: t,
                                minHeight: 5,
                                backgroundColor: cs.outlineVariant,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    exceeded ? Colors.red : item.color),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    limit != null
                        ? '${item.quantityLabel(used)} / ${item.quantityLabel(limit)}'
                        : item.quantityLabel(used),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: exceeded ? Colors.red : cs.onSurface,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Misc helpers ────────────────────────────────────────────────────────

  Widget _sectionTitle(BuildContext context, String title, {String? subtitle}) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            )),
        if (subtitle != null) ...[
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 1.5),
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
      ],
    );
  }

  Widget _emptyBox(BuildContext context, String message) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
        ),
      ),
    );
  }

  static String _fmtQty(double v) {
    return v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(1);
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            child: Text(
              value,
              key: ValueKey(value),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _FadeSlideIn extends StatelessWidget {
  final Widget child;
  const _FadeSlideIn({required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (_, t, c) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, (1 - t) * 16), child: c),
      ),
      child: child,
    );
  }
}
