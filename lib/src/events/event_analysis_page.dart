import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:my_data_app/src/events/model/event_model.dart';
import 'package:my_data_app/src/events/cubit/event_cubit.dart';
import 'package:my_data_app/src/events/cubit/event_state.dart';
import 'package:my_data_app/src/events/event_finance_page.dart'
    show AddExpensePage;

final _fmt = NumberFormat('#,##,###', 'en_IN');

/// Quick-pick time window for the event analysis page. A user-set
/// [DateTimeRange] overrides this when present.
enum _AnalysisPeriod { thisMonth, lastMonth, year, all }

extension _AnalysisPeriodX on _AnalysisPeriod {
  String get label {
    switch (this) {
      case _AnalysisPeriod.thisMonth:
        return 'This Month';
      case _AnalysisPeriod.lastMonth:
        return 'Last Month';
      case _AnalysisPeriod.year:
        return 'Year';
      case _AnalysisPeriod.all:
        return 'All';
    }
  }
}

/// Stable palette used to colour free-text expense categories. A category's
/// colour is its index in the event's sorted category list, wrapping around.
const _kCategoryPalette = <Color>[
  Color(0xFF5C6BC0), // indigo
  Color(0xFFEF5350), // red
  Color(0xFF26A69A), // teal
  Color(0xFFFFA726), // orange
  Color(0xFFAB47BC), // purple
  Color(0xFF66BB6A), // green
  Color(0xFF29B6F6), // light blue
  Color(0xFFEC407A), // pink
  Color(0xFF8D6E63), // brown
  Color(0xFF78909C), // blue grey
  Color(0xFFFFCA28), // amber
  Color(0xFF7E57C2), // deep purple
];

/// Icon + colour treatment for the fixed payment modes (see [kPaymentModes]).
({IconData icon, Color color}) _paymentModeStyle(String mode) {
  switch (mode) {
    case 'Cash':
      return (icon: Icons.payments_rounded, color: Colors.green);
    case 'UPI':
      return (icon: Icons.qr_code_rounded, color: Colors.deepPurple);
    case 'Debit Card':
      return (icon: Icons.credit_card_rounded, color: Colors.blue);
    case 'Credit Card':
      return (icon: Icons.credit_card_rounded, color: Colors.orange);
    case 'Bank Transfer':
      return (icon: Icons.account_balance_rounded, color: Colors.teal);
    case 'Cheque':
      return (icon: Icons.receipt_long_rounded, color: Colors.brown);
    default:
      return (icon: Icons.more_horiz_rounded, color: Colors.blueGrey);
  }
}

/// Spending analysis for a single event fund — mirrors the home-records
/// analysis page: period filters, category pie + legend, payment-mode
/// breakdown, monthly trend and top-categories bar chart, with tappable
/// drill-down sheets listing the underlying expenses.
class EventAnalysisPage extends StatefulWidget {
  final String eventId;
  const EventAnalysisPage({Key? key, required this.eventId}) : super(key: key);

  @override
  State<EventAnalysisPage> createState() => _EventAnalysisPageState();
}

class _EventAnalysisPageState extends State<EventAnalysisPage> {
  DateTimeRange? _dateRange;

  /// A specific month selected via the navigator arrows. Null unless the
  /// user has stepped to a particular month.
  DateTime? _monthAnchor;

  String? _filterCategory;
  _AnalysisPeriod _period = _AnalysisPeriod.thisMonth;

  @override
  void initState() {
    super.initState();
    // Open anchored to the month of the earliest expense — events are often
    // in the past, so "This Month" would usually show an empty page.
    final expenses = context.read<EventCubit>().expensesFor(widget.eventId);
    if (expenses.isNotEmpty) {
      final earliest = expenses
          .map((e) => e.date)
          .reduce((a, b) => a.isBefore(b) ? a : b);
      _monthAnchor = DateTime(earliest.year, earliest.month);
    }
  }

  // ── Range resolution ─────────────────────────────────────────────────────

  ({DateTime start, DateTime end}) _monthWindow(DateTime anchor) {
    return (
      start: DateTime(anchor.year, anchor.month, 1),
      end: DateTime(anchor.year, anchor.month + 1, 0, 23, 59, 59),
    );
  }

  /// Resolved [start, end] window for the current selection. An explicit
  /// [DateTimeRange] wins; then a stepped [_monthAnchor]; otherwise the
  /// window is derived from [_period].
  ({DateTime start, DateTime end}) _activeRange() {
    if (_dateRange != null) {
      // showDateRangePicker's end-date is the start-of-day — bump to
      // end-of-day so a same-day range matches all expenses that day.
      final end = DateTime(_dateRange!.end.year, _dateRange!.end.month,
          _dateRange!.end.day, 23, 59, 59);
      return (start: _dateRange!.start, end: end);
    }
    if (_monthAnchor != null) return _monthWindow(_monthAnchor!);
    final now = DateTime.now();
    switch (_period) {
      case _AnalysisPeriod.thisMonth:
        return _monthWindow(DateTime(now.year, now.month));
      case _AnalysisPeriod.lastMonth:
        return _monthWindow(DateTime(now.year, now.month - 1));
      case _AnalysisPeriod.year:
        return (
          start: DateTime(now.year, 1, 1),
          end: DateTime(now.year, 12, 31, 23, 59, 59),
        );
      case _AnalysisPeriod.all:
        return (start: DateTime(1970), end: DateTime(2100));
    }
  }

  String _activeRangeLabel() {
    if (_dateRange != null) {
      return '${DateFormat('d MMM').format(_dateRange!.start)} – ${DateFormat('d MMM yyyy').format(_dateRange!.end)}';
    }
    if (_monthAnchor != null) {
      return DateFormat('MMM yyyy').format(_monthAnchor!);
    }
    return _period.label;
  }

  /// Display string for the month navigator strip — mirrors whatever filter
  /// is currently active.
  String _navigatorLabel() {
    if (_dateRange != null) {
      final s = _dateRange!.start;
      final e = _dateRange!.end;
      final lastDayOfStartMonth = DateTime(s.year, s.month + 1, 0).day;
      final isFullSingleMonth = s.day == 1 &&
          e.day == lastDayOfStartMonth &&
          s.year == e.year &&
          s.month == e.month;
      if (isFullSingleMonth) return DateFormat('MMM yyyy').format(s);
      if (s.year == e.year) {
        return '${DateFormat('d MMM').format(s)} – ${DateFormat('d MMM yyyy').format(e)}';
      }
      return '${DateFormat('d MMM yyyy').format(s)} – ${DateFormat('d MMM yyyy').format(e)}';
    }
    if (_monthAnchor != null) {
      return DateFormat('MMM yyyy').format(_monthAnchor!);
    }
    final now = DateTime.now();
    switch (_period) {
      case _AnalysisPeriod.thisMonth:
        return DateFormat('MMM yyyy').format(now);
      case _AnalysisPeriod.lastMonth:
        return DateFormat('MMM yyyy').format(DateTime(now.year, now.month - 1));
      case _AnalysisPeriod.year:
        return '${now.year}';
      case _AnalysisPeriod.all:
        return 'All Time';
    }
  }

  /// Move the active filter by [delta] months. Always switches into a
  /// stepped single-month view.
  void _shiftMonth(int delta) {
    DateTime base;
    if (_monthAnchor != null) {
      base = _monthAnchor!;
    } else if (_dateRange != null) {
      base = DateTime(_dateRange!.start.year, _dateRange!.start.month);
    } else {
      final now = DateTime.now();
      switch (_period) {
        case _AnalysisPeriod.thisMonth:
          base = DateTime(now.year, now.month);
        case _AnalysisPeriod.lastMonth:
          base = DateTime(now.year, now.month - 1);
        case _AnalysisPeriod.year:
        case _AnalysisPeriod.all:
          base = DateTime(now.year, now.month);
      }
    }
    setState(() {
      _monthAnchor = DateTime(base.year, base.month + delta);
      _dateRange = null;
    });
  }

  // ── Aggregations ─────────────────────────────────────────────────────────

  static String _categoryKey(EventExpense e) =>
      (e.category?.trim().isEmpty ?? true) ? 'Uncategorized' : e.category!.trim();

  List<EventExpense> _expensesInRange(List<EventExpense> all,
      {String? category, String? paymentMode, bool untaggedOnly = false}) {
    final r = _activeRange();
    return all.where((e) {
      if (e.date.isBefore(r.start) || e.date.isAfter(r.end)) return false;
      final cat = category ?? _filterCategory;
      if (cat != null && _categoryKey(e) != cat) return false;
      if (untaggedOnly) {
        return e.paymentMode == null || e.paymentMode!.trim().isEmpty;
      }
      if (paymentMode != null && e.paymentMode != paymentMode) return false;
      return true;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Map<String, double> _categoryTotals(List<EventExpense> all) {
    final map = <String, double>{};
    for (final e in _expensesInRange(all)) {
      final key = _categoryKey(e);
      map[key] = (map[key] ?? 0) + e.amount;
    }
    return map;
  }

  Map<String, double> _paymentTotals(List<EventExpense> all) {
    final map = <String, double>{};
    for (final e in _expensesInRange(all)) {
      final mode = e.paymentMode?.trim();
      if (mode == null || mode.isEmpty) continue;
      map[mode] = (map[mode] ?? 0) + e.amount;
    }
    return map;
  }

  int _untaggedPaymentCount(List<EventExpense> all) =>
      _expensesInRange(all, untaggedOnly: true).length;

  /// Totals for the last [months] calendar months (oldest → newest),
  /// including empty months so the trend line has a continuous axis.
  Map<DateTime, double> _monthlyTotals(List<EventExpense> all,
      {int months = 12}) {
    final now = DateTime.now();
    final result = <DateTime, double>{};
    for (int i = months - 1; i >= 0; i--) {
      result[DateTime(now.year, now.month - i)] = 0;
    }
    for (final e in all) {
      final key = DateTime(e.date.year, e.date.month);
      if (result.containsKey(key)) {
        result[key] = result[key]! + e.amount;
      }
    }
    return result;
  }

  /// Colour for a category name, stable within the event: index into the
  /// palette by position in the sorted list of all categories seen.
  Map<String, Color> _categoryColors(List<EventExpense> all) {
    final names = all.map(_categoryKey).toSet().toList()..sort();
    return {
      for (int i = 0; i < names.length; i++)
        names[i]: _kCategoryPalette[i % _kCategoryPalette.length],
    };
  }

  /// Key used to invalidate the [AnimatedSwitcher] when any filter
  /// dimension changes — the new charts cross-fade in.
  Object _filterKey() => Object.hash(
        _period,
        _dateRange?.start,
        _dateRange?.end,
        _monthAnchor,
        _filterCategory,
      );

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EventCubit, EventState>(
      builder: (context, state) {
        final cubit = context.read<EventCubit>();
        final event = cubit.getEvent(widget.eventId);
        if (event == null) {
          return const Scaffold(body: Center(child: Text('Event not found')));
        }

        final allExpenses = cubit.expensesFor(widget.eventId);
        final colors = _categoryColors(allExpenses);
        final categoryTotals = _categoryTotals(allExpenses);
        final filteredTotal =
            categoryTotals.values.fold<double>(0, (s, v) => s + v);
        final paymentTotals = _paymentTotals(allExpenses);
        final paymentTotal =
            paymentTotals.values.fold<double>(0, (s, v) => s + v);
        final untaggedCount = _untaggedPaymentCount(allExpenses);
        final monthlyData = _monthlyTotals(allExpenses);
        final allCategories = allExpenses.map(_categoryKey).toSet().toList()
          ..sort();

        return Scaffold(
          appBar: AppBar(
            title: Text('${event.name} — Analysis'),
            centerTitle: true,
            elevation: 0,
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;
              final contentMaxWidth = isWide ? 1100.0 : double.infinity;

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentMaxWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        _buildFilterControls(context, allCategories, colors),
                        const SizedBox(height: 20),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 320),
                          switchInCurve: Curves.easeOut,
                          child: Column(
                            key: ValueKey(_filterKey()),
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (isWide)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _buildSectionTitle(
                                            'Category Breakdown',
                                            subtitle: _navigatorLabel(),
                                            trailing: _TotalSpentLabel(
                                                amount:
                                                    '₹${_fmt.format(filteredTotal)}'),
                                          ),
                                          const SizedBox(height: 12),
                                          _buildPieChart(categoryTotals,
                                              filteredTotal, colors),
                                          const SizedBox(height: 8),
                                          _buildPieLegend(cubit, event,
                                              categoryTotals, filteredTotal, colors),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 24),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _buildSectionTitle('Top Categories'),
                                          const SizedBox(height: 12),
                                          _buildBarChart(categoryTotals, colors),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              else ...[
                                _buildSectionTitle(
                                  'Category Breakdown',
                                  subtitle: _navigatorLabel(),
                                  trailing: _TotalSpentLabel(
                                      amount: '₹${_fmt.format(filteredTotal)}'),
                                ),
                                const SizedBox(height: 18),
                                _buildPieChart(
                                    categoryTotals, filteredTotal, colors),
                                const SizedBox(height: 8),
                                _buildPieLegend(cubit, event, categoryTotals,
                                    filteredTotal, colors),
                              ],
                              const SizedBox(height: 24),
                              _buildSectionTitle('Payment Mode',
                                  subtitle: _activeRangeLabel()),
                              const SizedBox(height: 12),
                              _buildPaymentBreakdown(cubit, event,
                                  paymentTotals, paymentTotal, untaggedCount),
                              const SizedBox(height: 24),
                              _buildSectionTitle('Monthly Trend'),
                              const SizedBox(height: 12),
                              _buildLineChart(monthlyData, event.color),
                              if (!isWide) ...[
                                const SizedBox(height: 24),
                                _buildSectionTitle('Top Categories'),
                                const SizedBox(height: 12),
                                _buildBarChart(categoryTotals, colors),
                              ],
                            ],
                          ),
                        ),
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

  // ── Section helpers ──────────────────────────────────────────────────────

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
          Flexible(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                '· $subtitle',
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
        if (trailing != null) ...[
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 1),
            child: trailing,
          ),
        ],
      ],
    );
  }

  Widget _buildFilterControls(BuildContext context, List<String> allCategories,
      Map<String, Color> colors) {
    final cs = Theme.of(context).colorScheme;
    final hasRange = _dateRange != null || _monthAnchor != null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<_AnalysisPeriod>(
              segments: _AnalysisPeriod.values
                  .map((p) => ButtonSegment<_AnalysisPeriod>(
                        value: p,
                        label: Text(p.label),
                      ))
                  .toList(),
              selected: hasRange
                  ? <_AnalysisPeriod>{}
                  : <_AnalysisPeriod>{_period},
              emptySelectionAllowed: true,
              showSelectedIcon: false,
              onSelectionChanged: (values) {
                if (values.isEmpty) return;
                setState(() {
                  _period = values.first;
                  _dateRange = null;
                  _monthAnchor = null;
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
          _PeriodNavigator(
            label: _navigatorLabel(),
            onPrev: () => _shiftMonth(-1),
            onNext: () => _shiftMonth(1),
            onPickRange: () async {
              final range = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
                initialDateRange: _dateRange,
              );
              if (range != null) {
                setState(() {
                  _dateRange = range;
                  _monthAnchor = null;
                });
              }
            },
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String?>(
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
                return DropdownMenuItem<String?>(
                  value: cat,
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: colors[cat],
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(cat, style: const TextStyle(fontSize: 13)),
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

  // ── Chart builders ───────────────────────────────────────────────────────

  Widget _buildPieChart(Map<String, double> totals, double grandTotal,
      Map<String, Color> colors) {
    if (totals.isEmpty || grandTotal == 0) {
      return _emptyChart('No expenses in this period');
    }

    return SizedBox(
      height: 220,
      child: PieChart(
        PieChartData(
          sections: totals.entries.map((e) {
            final percentage = (e.value / grandTotal * 100);
            return PieChartSectionData(
              value: e.value,
              title:
                  percentage >= 5 ? '${percentage.toStringAsFixed(1)}%' : '',
              color: colors[e.key],
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
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  Widget _buildPieLegend(EventCubit cubit, EventFund event,
      Map<String, double> totals, double grandTotal, Map<String, Color> colors) {
    if (totals.isEmpty) return const SizedBox();

    final cs = Theme.of(context).colorScheme;
    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sorted.map((e) {
        final pct = grandTotal > 0 ? (e.value / grandTotal * 100) : 0.0;
        return InkWell(
          onTap: () => _showExpensesSheet(
            cubit: cubit,
            event: event,
            title: e.key,
            accentColor: colors[e.key] ?? event.color,
            icon: Icons.label_rounded,
            expenses:
                _expensesInRange(cubit.expensesFor(event.id), category: e.key),
          ),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: colors[e.key],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${e.key}  ',
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        TextSpan(
                          text:
                              '₹${_fmt.format(e.value)} (${pct.toStringAsFixed(1)}%)',
                          style: const TextStyle(fontSize: 12),
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

  Widget _buildPaymentBreakdown(EventCubit cubit, EventFund event,
      Map<String, double> totals, double grandTotal, int untaggedCount) {
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
            Icon(Icons.payments_rounded, color: cs.onSurfaceVariant, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                untaggedCount > 0
                    ? 'No tagged expenses yet. $untaggedCount expense${untaggedCount == 1 ? '' : 's'} in this period have no payment mode.'
                    : 'No expenses in this period',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
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
            final style = _paymentModeStyle(e.key);
            return InkWell(
              onTap: () => _showExpensesSheet(
                cubit: cubit,
                event: event,
                title: e.key,
                accentColor: style.color,
                icon: style.icon,
                expenses: _expensesInRange(cubit.expensesFor(event.id),
                    paymentMode: e.key),
              ),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: style.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(style.icon, color: style.color, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.key,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: pct / 100),
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOutCubic,
                            builder: (_, t, _) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: t,
                                  minHeight: 6,
                                  backgroundColor: cs.surfaceContainerHighest,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      style.color),
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
                          '₹${_fmt.format(e.value)}',
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
                '$untaggedCount expense${untaggedCount == 1 ? '' : 's'} in this period without a payment mode.',
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLineChart(Map<DateTime, double> monthlyData, Color color) {
    final cs = Theme.of(context).colorScheme;
    final entries = monthlyData.entries.toList();
    if (entries.isEmpty) return _emptyChart('No data to display');

    final maxY = entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);
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
              color: color,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: color.withValues(alpha: 0.1),
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
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
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
                    '₹${_fmt.format(value)}',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
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

  Widget _buildBarChart(Map<String, double> totals, Map<String, Color> colors) {
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
                  color: colors[e.value.key],
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
                      sorted[idx].key,
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
                    '₹${_fmt.format(value)}',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
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

  // ── Expenses sheet ───────────────────────────────────────────────────────

  void _showExpensesSheet({
    required EventCubit cubit,
    required EventFund event,
    required String title,
    required Color accentColor,
    required IconData icon,
    required List<EventExpense> expenses,
  }) {
    final total = expenses.fold<double>(0, (s, e) => s + e.amount);

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
                      child: Icon(icon, color: accentColor, size: 20),
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
                            '${_activeRangeLabel()}  ·  ${expenses.length} expense${expenses.length == 1 ? '' : 's'}',
                            style: TextStyle(
                                fontSize: 12, color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '₹${_fmt.format(total)}',
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
                child: expenses.isEmpty
                    ? Center(
                        child: Text(
                          'No expenses to show',
                          style: TextStyle(
                              color: cs.onSurfaceVariant, fontSize: 14),
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        itemCount: expenses.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 6),
                        itemBuilder: (_, i) {
                          final exp = expenses[i];
                          return _ExpenseListTile(
                            expense: exp,
                            accentColor: accentColor,
                            onTap: () async {
                              // Close the sheet first — its cached `expenses`
                              // list won't reflect the edit, so dismissing
                              // avoids showing stale data.
                              Navigator.pop(sheetCtx);
                              final edited =
                                  await Navigator.push<EventExpense>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BlocProvider.value(
                                    value: cubit,
                                    child: AddExpensePage(
                                        event: event, existing: exp),
                                  ),
                                ),
                              );
                              if (edited != null) cubit.updateExpense(edited);
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

// ── Helper widgets ──────────────────────────────────────────────────────────

/// Unified period control: a pill with month-shift arrows on the sides and
/// a tappable label in the middle that opens a date range picker.
class _PeriodNavigator extends StatelessWidget {
  final String label;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onPickRange;

  const _PeriodNavigator({
    required this.label,
    required this.onPrev,
    required this.onNext,
    required this.onPickRange,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          _ArrowButton(
            icon: Icons.chevron_left_rounded,
            tooltip: 'Previous month',
            onPressed: onPrev,
          ),
          Expanded(
            child: InkWell(
              onTap: onPickRange,
              borderRadius: BorderRadius.circular(22),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (child, anim) =>
                      FadeTransition(opacity: anim, child: child),
                  child: Row(
                    key: ValueKey(label),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_rounded,
                        size: 16,
                        color: cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _ArrowButton(
            icon: Icons.chevron_right_rounded,
            tooltip: 'Next month',
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  const _ArrowButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 22, color: cs.onSurfaceVariant),
        ),
      ),
    );
  }
}

/// Minimal trailing label for the Category Breakdown section title —
/// expense-red with a down-arrow, matching the home analysis page.
class _TotalSpentLabel extends StatelessWidget {
  final String amount;
  const _TotalSpentLabel({required this.amount});

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

/// Compact expense tile used inside the drill-down bottom sheet. Tap to edit
/// the underlying expense.
class _ExpenseListTile extends StatelessWidget {
  final EventExpense expense;
  final Color accentColor;
  final VoidCallback? onTap;
  const _ExpenseListTile({
    required this.expense,
    required this.accentColor,
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
          color: accentColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(color: accentColor, width: 3),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.title,
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
                      DateFormat('d MMM yyyy').format(expense.date),
                      if (expense.category != null &&
                          expense.category!.isNotEmpty)
                        expense.category!,
                      if (expense.paymentMode != null &&
                          expense.paymentMode!.isNotEmpty)
                        expense.paymentMode!,
                      if (expense.paidTo != null && expense.paidTo!.isNotEmpty)
                        expense.paidTo!,
                    ].join('  ·  '),
                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text(
              '₹${_fmt.format(expense.amount)}',
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
