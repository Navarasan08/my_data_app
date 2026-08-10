import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:my_data_app/src/home/home_record_model.dart';
import 'package:my_data_app/src/home/cubit/home_record_cubit.dart';
import 'package:my_data_app/src/home/cubit/home_record_state.dart';
import 'package:my_data_app/src/home/home_record_analysis_page.dart';
import 'package:my_data_app/src/home/home_record_settings_page.dart';
import 'package:my_data_app/src/events/cubit/event_cubit.dart';
import 'package:my_data_app/src/events/model/event_model.dart';
import 'package:my_data_app/src/events/event_finance_page.dart'
    show EventDetailPage;

/// Push the [EventDetailPage] for [eventId], re-providing [EventCubit] since
/// the target route sits above the shell's provider scope. No-op if the event
/// no longer exists (e.g. it was deleted after the record was linked).
void _openLinkedEvent(BuildContext context, String eventId) {
  final eventCubit = context.read<EventCubit>();
  if (eventCubit.getEvent(eventId) == null) return;
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => BlocProvider.value(
        value: eventCubit,
        child: EventDetailPage(eventId: eventId),
      ),
    ),
  );
}

class HomeRecordPage extends StatefulWidget {
  const HomeRecordPage({Key? key}) : super(key: key);

  @override
  State<HomeRecordPage> createState() => _HomeRecordPageState();
}

class _HomeRecordPageState extends State<HomeRecordPage> {
  /// FAB is hidden while the list sits at its bottom edge (so it doesn't
  /// cover the last record) and animates back the moment the user scrolls
  /// up again. A [ValueNotifier] (rather than setState) keeps scroll
  /// handling jank-free: only the FAB subtree rebuilds, never the lists.
  final ValueNotifier<bool> _fabVisible = ValueNotifier(true);

  bool _handleScroll(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;
    final m = notification.metrics;
    final atBottom =
        m.maxScrollExtent > 0 && m.pixels >= m.maxScrollExtent - 24;
    _fabVisible.value = !atBottom;
    return false;
  }

  @override
  void dispose() {
    _fabVisible.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return BlocBuilder<HomeRecordCubit, HomeRecordState>(
      builder: (context, state) {
        final cubit = context.read<HomeRecordCubit>();
        final filteredRecords = cubit.filteredRecords;
        final displayTotal = cubit.displayTotal;
        final displayIncome = cubit.displayIncomeTotal;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Expense Tracker'),
            centerTitle: false,
            elevation: 0,
            actions: [
              IconButton(
                icon: Icon(
                  state.isCalendarView
                      ? Icons.view_list_rounded
                      : Icons.calendar_month_rounded,
                ),
                tooltip: state.isCalendarView ? 'List view' : 'Calendar view',
                onPressed: cubit.toggleCalendarView,
              ),
              IconButton(
                icon: const Icon(Icons.bar_chart_rounded),
                tooltip: 'Analysis',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MultiBlocProvider(
                      providers: [
                        BlocProvider.value(value: cubit),
                        BlocProvider.value(value: context.read<EventCubit>()),
                      ],
                      child: const HomeRecordAnalysisPage(),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings_rounded),
                tooltip: 'Category Settings',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: cubit,
                      child: const HomeRecordSettingsPage(),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: NotificationListener<ScrollNotification>(
            onNotification: _handleScroll,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final isWide = width > 600;
                final isExtraWide = width > 900;
                final contentMaxWidth = isExtraWide ? 900.0 : double.infinity;
                final gridCols = isExtraWide
                    ? 3
                    : isWide
                    ? 2
                    : 1;

                return Column(
                  children: [
                    // Income / Expenses / Overall — the page's main totals
                    // line now that the header carries only the title.
                    Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: contentMaxWidth),
                        child: _KindSummaryBar(
                          formattedIncome:
                              '+${cubit.formatAmount(displayIncome)}',
                          formattedExpense: cubit.formatAmount(displayTotal),
                          overall: displayIncome - displayTotal,
                          formatAmount: cubit.formatAmount,
                        ),
                      ),
                    ),

                    // Date range + month navigation with the filter button on
                    // its right, directly under the summary line. The filter
                    // button always renders (it's the only way into the filter
                    // sheet); the period pill only in monthly/calendar mode.
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (state.showMonthlyCalendar ||
                              state.isCalendarView) ...[
                            _PeriodNavBar(
                              label: cubit.selectedPeriodLabel,
                              count: filteredRecords.length,
                              onPrevious: () => cubit.changeMonth(-1),
                              onNext: () => cubit.changeMonth(1),
                              onJumpToToday: () =>
                                  cubit.selectDate(DateTime.now()),
                            ),
                            const SizedBox(width: 8),
                          ],
                          _FilterButton(
                            activeCount: state.selectedCategoryIds.length,
                            onTap: () => _openMultiSelectSheet(
                              context,
                              cubit,
                              state.selectedCategoryIds,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Active-filter pill — only rendered when a filter is
                    // applied, since the chips strip moved into the menu's
                    // Filters popup.
                    if (state.selectedCategoryIds.isNotEmpty)
                      Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: contentMaxWidth,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                            child: Row(
                              children: [
                                _ActiveFilterChip(
                                  count: state.selectedCategoryIds.length,
                                  onTap: () => _openMultiSelectSheet(
                                    context,
                                    cubit,
                                    state.selectedCategoryIds,
                                  ),
                                  onClear: cubit.clearCategoryFilter,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),

                    // Records List / Grid / Calendar
                    Expanded(
                      child: state.isCalendarView
                          ? Center(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: contentMaxWidth,
                                ),
                                child: _MonthCalendarView(cubit: cubit),
                              ),
                            )
                          : filteredRecords.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.home_outlined,
                                    size: 48,
                                    color: cs.outline,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    state.selectedCategoryIds.isNotEmpty
                                        ? 'No records for the selected categories'
                                        : 'No records yet',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Center(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: contentMaxWidth,
                                ),
                                child: state.showMonthlyCalendar
                                    ? (gridCols > 1
                                          ? GridView.builder(
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                    12,
                                                    4,
                                                    12,
                                                    12,
                                                  ),
                                              gridDelegate:
                                                  SliverGridDelegateWithFixedCrossAxisCount(
                                                    crossAxisCount: gridCols,
                                                    crossAxisSpacing: 10,
                                                    mainAxisSpacing: 10,
                                                    childAspectRatio:
                                                        isExtraWide ? 2.5 : 2.2,
                                                  ),
                                              itemCount: filteredRecords.length,
                                              itemBuilder: (context, index) {
                                                return _buildRecordItem(
                                                  context,
                                                  cubit,
                                                  filteredRecords[index],
                                                );
                                              },
                                            )
                                          : _buildWeekGroupedList(
                                              context,
                                              cubit,
                                              filteredRecords,
                                            ))
                                    : _buildMonthGroupedList(
                                        context,
                                        cubit,
                                        filteredRecords,
                                      ),
                              ),
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
          // Slides down + fades out at the bottom of the scroll, comes back
          // as soon as the user scrolls upward. ValueListenableBuilder keeps
          // the rebuild scoped to the FAB so scrolling stays smooth.
          floatingActionButton: ValueListenableBuilder<bool>(
            valueListenable: _fabVisible,
            builder: (context, visible, fab) => AnimatedSlide(
              offset: visible ? Offset.zero : const Offset(0, 2),
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: AnimatedOpacity(
                opacity: visible ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: IgnorePointer(
                  ignoring: !visible,
                  child: fab,
                ),
              ),
            ),
            child: FloatingActionButton(
              tooltip: 'Add Record',
              onPressed: () async {
                final newRecord = await Navigator.push<HomeRecord>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: cubit,
                      child: AddHomeRecordPage(
                        categories: cubit.allCategories,
                        paymentTypes: cubit.paymentTypes,
                        groups: context.read<EventCubit>().activeEvents,
                        groupTotals:
                            context.read<EventCubit>().activeEventTotals,
                        initialDate: cubit.state.selectedDate,
                      ),
                    ),
                  ),
                );
                if (newRecord != null) {
                  cubit.addRecord(newRecord);
                }
              },
              child: const Icon(Icons.add),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMonthGroupedList(
    BuildContext context,
    HomeRecordCubit cubit,
    List<HomeRecord> records,
  ) {
    final cs = Theme.of(context).colorScheme;
    final grouped = <String, List<HomeRecord>>{};
    for (final r in records) {
      final key = DateFormat('yyyy-MM').format(r.date);
      grouped.putIfAbsent(key, () => []).add(r);
    }
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 80),
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final key = sortedKeys[index];
        final monthRecords = grouped[key]!;
        final monthTotal = monthRecords
            .where((r) => !r.isIncome)
            .fold(0.0, (sum, r) => sum + r.amount);
        final monthIncome = monthRecords
            .where((r) => r.isIncome)
            .fold(0.0, (sum, r) => sum + r.amount);
        final monthDate = DateTime.parse('$key-01');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(
                    DateFormat('MMMM yyyy').format(monthDate),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (monthIncome > 0) ...[
                    Text(
                      '+${cubit.formatAmount(monthIncome)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    cubit.formatAmount(monthTotal),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[700],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '(${monthRecords.length})',
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            ...monthRecords.map((r) => _buildRecordItem(context, cubit, r)),
          ],
        );
      },
    );
  }

  /// Returns the Monday of the week containing [date].
  DateTime _weekStart(DateTime date) {
    final diff = date.weekday - DateTime.monday;
    return DateTime(date.year, date.month, date.day - diff);
  }

  String _weekLabel(DateTime weekStart, DateTime now) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    final todayWeek = _weekStart(now);
    if (weekStart == todayWeek) return 'This Week';
    if (weekStart == todayWeek.subtract(const Duration(days: 7))) {
      return 'Last Week';
    }
    return '${DateFormat('d MMM').format(weekStart)} – ${DateFormat('d MMM').format(weekEnd)}';
  }

  Widget _buildWeekGroupedList(
    BuildContext context,
    HomeRecordCubit cubit,
    List<HomeRecord> records,
  ) {
    final now = DateTime.now();
    // Group records by week (Monday start)
    final grouped = <DateTime, List<HomeRecord>>{};
    for (final r in records) {
      final ws = _weekStart(r.date);
      grouped.putIfAbsent(ws, () => []).add(r);
    }
    // Sort week keys descending (most recent first)
    final sortedWeeks = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    final slivers = <Widget>[
      const SliverToBoxAdapter(child: SizedBox(height: 4)),
    ];

    for (final ws in sortedWeeks) {
      final weekRecords = grouped[ws]!;
      final weekTotal = weekRecords
          .where((r) => !r.isIncome)
          .fold(0.0, (sum, r) => sum + r.amount);
      final weekIncome = weekRecords
          .where((r) => r.isIncome)
          .fold(0.0, (sum, r) => sum + r.amount);

      slivers.add(
        SliverPersistentHeader(
          pinned: true,
          delegate: _WeekHeaderDelegate(
            label: _weekLabel(ws, now),
            count: weekRecords.length,
            formattedTotal: cubit.formatAmount(weekTotal),
            formattedIncome: weekIncome > 0
                ? '+${cubit.formatAmount(weekIncome)}'
                : null,
          ),
        ),
      );

      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => _buildRecordItem(context, cubit, weekRecords[i]),
              childCount: weekRecords.length,
            ),
          ),
        ),
      );
    }

    slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 12)));

    return CustomScrollView(slivers: slivers);
  }

  Widget _buildRecordItem(
    BuildContext context,
    HomeRecordCubit cubit,
    HomeRecord record,
  ) {
    return _RecordCard(
      record: record,
      onEdit: () async {
        final edited = await Navigator.push<HomeRecord>(
          context,
          MaterialPageRoute(
            builder: (_) => AddHomeRecordPage(
              record: record,
              categories: cubit.allCategories,
              paymentTypes: cubit.paymentTypes,
              groups: context.read<EventCubit>().activeEvents,
              groupTotals: context.read<EventCubit>().activeEventTotals,
            ),
          ),
        );
        if (edited != null) {
          cubit.updateRecord(edited);
        }
      },
      onDelete: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Record'),
            content: Text('Are you sure you want to delete "${record.title}"?'),
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
        if (confirmed == true) {
          cubit.deleteRecord(record.id);
        }
      },
    );
  }

  /// Open a multi-select bottom sheet listing every category with checkboxes.
  /// Result is committed only when the user taps "Apply" — gives a clear
  /// commit step compared to chip-tap toggling.
  Future<void> _openMultiSelectSheet(
    BuildContext context,
    HomeRecordCubit cubit,
    Set<String> initial,
  ) async {
    final cs = Theme.of(context).colorScheme;
    final categories = cubit.categoriesByUsage;
    final selected = Set<String>.from(initial);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSt) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.4,
              maxChildSize: 0.92,
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
                    padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.filter_list_rounded,
                          size: 18,
                          color: cs.onSurface,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Filter by category',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: selected.isEmpty
                              ? null
                              : () => setSt(() => selected.clear()),
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: categories.length,
                      itemBuilder: (_, i) {
                        final cat = categories[i];
                        final checked = selected.contains(cat.id);
                        return CheckboxListTile(
                          dense: true,
                          controlAffinity: ListTileControlAffinity.trailing,
                          value: checked,
                          onChanged: (v) {
                            setSt(() {
                              if (v == true) {
                                selected.add(cat.id);
                              } else {
                                selected.remove(cat.id);
                              }
                            });
                          },
                          title: Row(
                            children: [
                              Icon(cat.icon, size: 18, color: cat.color),
                              const SizedBox(width: 10),
                              Text(
                                cat.displayName,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                          activeColor: cat.color,
                        );
                      },
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(sheetCtx),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                cubit.setCategoryIds(selected);
                                Navigator.pop(sheetCtx);
                              },
                              child: Text(
                                selected.isEmpty
                                    ? 'Show all'
                                    : 'Apply (${selected.length})',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// Round filter button next to the period navigator. Opens the category
/// multi-select sheet; shows a count badge and a green tint while a filter
/// is active.
class _FilterButton extends StatelessWidget {
  final int activeCount;
  final VoidCallback onTap;

  const _FilterButton({required this.activeCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasFilter = activeCount > 0;
    return Tooltip(
      message: 'Filter by category',
      child: Material(
        color: hasFilter
            ? Colors.green.withValues(alpha: 0.12)
            : cs.surfaceContainerLow,
        shape: CircleBorder(
          side: BorderSide(color: hasFilter ? Colors.green : cs.outlineVariant),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: Badge(
              isLabelVisible: hasFilter,
              label: Text('$activeCount'),
              child: Icon(
                Icons.filter_list_rounded,
                size: 18,
                color: hasFilter ? Colors.green[800] : cs.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pill-style period navigator shown under the summary line:
/// `‹  📅 1 Aug – 31 Aug  (12)  ›`. Chevrons step a month back/forward;
/// tapping the centre label jumps back to the current month.
class _PeriodNavBar extends StatelessWidget {
  final String label;
  final int count;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onJumpToToday;

  const _PeriodNavBar({
    required this.label,
    required this.count,
    required this.onPrevious,
    required this.onNext,
    required this.onJumpToToday,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget chevron(IconData icon, String tooltip, VoidCallback onTap) =>
        Tooltip(
          message: tooltip,
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(icon, size: 20, color: cs.onSurface),
            ),
          ),
        );

    return Material(
      color: cs.surfaceContainerLow,
      shape: StadiumBorder(side: BorderSide(color: cs.outlineVariant)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          chevron(Icons.chevron_left_rounded, 'Previous month', onPrevious),
          Tooltip(
            message: 'Jump to current month',
            child: InkWell(
              onTap: onJumpToToday,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_month_rounded,
                      size: 14,
                      color: cs.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: cs.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          chevron(Icons.chevron_right_rounded, 'Next month', onNext),
        ],
      ),
    );
  }
}

/// Compact three-column summary line — Income (green), Expenses (red) and
/// Overall (income − expenses, green when positive) — for the records shown
/// in the current period. Rendered below the category filter chips in both
/// the list and calendar views.
class _KindSummaryBar extends StatelessWidget {
  final String formattedIncome;
  final String formattedExpense;
  final double overall;
  final String Function(double amount, {int decimals}) formatAmount;

  const _KindSummaryBar({
    required this.formattedIncome,
    required this.formattedExpense,
    required this.overall,
    required this.formatAmount,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final overallColor = overall >= 0 ? Colors.green[700]! : Colors.red[700]!;
    final overallText = overall >= 0
        ? '+${formatAmount(overall)}'
        : '-${formatAmount(-overall)}';

    Widget item(String label, String value, Color color) => Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );

    final divider = Container(width: 1, height: 26, color: cs.outlineVariant);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Row(
          children: [
            item('Income', formattedIncome, Colors.green[700]!),
            divider,
            item('Expenses', formattedExpense, Colors.red[700]!),
            divider,
            item('Overall', overallText, overallColor),
          ],
        ),
      ),
    );
  }
}

/// Small pill shown in the totals strip when a category filter is active,
/// now that the filter chips strip lives inside the menu's Filters popup.
/// Tapping the pill reopens the filter sheet; the trailing × clears it.
class _ActiveFilterChip extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _ActiveFilterChip({
    required this.count,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.green.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.filter_list_rounded,
                size: 14,
                color: Colors.green[800],
              ),
              const SizedBox(width: 5),
              Text(
                '$count filter${count == 1 ? '' : 's'}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.green[800],
                ),
              ),
              const SizedBox(width: 4),
              InkWell(
                onTap: onClear,
                borderRadius: BorderRadius.circular(10),
                child: Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: Colors.green[800],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeekHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String label;
  final int count;
  final String formattedTotal;

  /// Pre-formatted income total (with leading `+`), or null when the week
  /// has no income records.
  final String? formattedIncome;

  _WeekHeaderDelegate({
    required this.label,
    required this.count,
    required this.formattedTotal,
    this.formattedIncome,
  });

  static const double _height = 52;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.date_range_rounded, size: 16, color: cs.onSurface),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: cs.onSurfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: cs.surface,
                ),
              ),
            ),
            const Spacer(),
            if (formattedIncome != null) ...[
              Text(
                formattedIncome!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.green[700],
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              formattedTotal,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _WeekHeaderDelegate oldDelegate) {
    return oldDelegate.label != label ||
        oldDelegate.count != count ||
        oldDelegate.formattedTotal != formattedTotal ||
        oldDelegate.formattedIncome != formattedIncome;
  }
}

class _RecordCard extends StatelessWidget {
  final HomeRecord record;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RecordCard({
    Key? key,
    required this.record,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // Resolve the linked event (if any) for the navigation chip. Falls back to
    // the stored name when the event was archived/removed after linking.
    final linkedEvent = record.eventId != null
        ? context.read<EventCubit>().getEvent(record.eventId!)
        : null;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: record.category.color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(color: record.category.color, width: 3),
        ),
      ),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              Icon(
                record.category.icon,
                size: 20,
                color: record.category.color,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        record.category.displayName,
                        if (record.quantityLabel.isNotEmpty)
                          record.quantityLabel,
                        if (record.paymentType != null)
                          record.paymentType!.displayName,
                        DateFormat('d MMM').format(record.date),
                      ].join('  ·  '),
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    if (record.eventId != null) ...[
                      const SizedBox(height: 4),
                      _LinkedEventChip(
                        event: linkedEvent,
                        fallbackName: record.eventName,
                        onTap: linkedEvent != null
                            ? () => _openLinkedEvent(context, record.eventId!)
                            : null,
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                (record.isIncome ? '+' : '') +
                    context.read<HomeRecordCubit>().formatAmount(record.amount),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: record.isIncome ? Colors.green[700] : Colors.red,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: onDelete,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    size: 16,
                    color: Colors.red[300],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small pill on a record showing the event/group it's linked to. Tapping it
/// navigates to that event's detail page (via [onTap]); when the event no
/// longer exists [onTap] is null and the chip renders as a muted, static tag.
class _LinkedEventChip extends StatelessWidget {
  final EventFund? event;
  final String? fallbackName;
  final VoidCallback? onTap;

  const _LinkedEventChip({
    required this.event,
    required this.fallbackName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = event?.color ?? cs.onSurfaceVariant;
    final label = event?.name ?? fallbackName ?? 'Linked event';
    final icon = event?.icon ?? Icons.event_busy_rounded;

    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 2),
            Icon(Icons.chevron_right_rounded, size: 13, color: color),
          ],
        ],
      ),
    );

    if (onTap == null) return chip;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: chip,
    );
  }
}

class AddHomeRecordPage extends StatefulWidget {
  final HomeRecord? record;
  final List<HomeCategory> categories;
  final List<PaymentType> paymentTypes;

  /// Active event funds the record can be linked to. Shown as an optional
  /// picker; passed in (like [categories]) so the form doesn't depend on
  /// [EventCubit] being in its route's provider scope.
  final List<EventFund> groups;

  /// Total spent per event id. When the user links the record to an event,
  /// the amount field is auto-filled with that event's total.
  final Map<String, double> groupTotals;

  /// Pre-fill the date field when opening the page in "add" mode (ignored in
  /// edit mode — the existing record's date wins). Used when the user taps a
  /// calendar cell and then hits "Add Record" so the form opens on that day.
  final DateTime? initialDate;

  const AddHomeRecordPage({
    Key? key,
    this.record,
    required this.categories,
    this.paymentTypes = const [],
    this.groups = const [],
    this.groupTotals = const {},
    this.initialDate,
  }) : super(key: key);

  @override
  State<AddHomeRecordPage> createState() => _AddHomeRecordPageState();
}

class _AddHomeRecordPageState extends State<AddHomeRecordPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  final _quantityController = TextEditingController();

  HomeCategory _selectedCategory = HomeCategory.groceries;
  DateTime _selectedDate = DateTime.now();
  MeasureUnit? _selectedUnit;
  PaymentType? _selectedPaymentType;
  String? _selectedEventId;
  bool _isIncome = false;

  bool get _isEditing => widget.record != null;

  /// Categories matching the currently selected kind (expense vs income),
  /// plus the record's own category if it's missing from that list (e.g. a
  /// legacy custom category) so editing never silently drops it.
  List<HomeCategory> get _kindCategories {
    final list = widget.categories
        .where((c) => c.isIncome == _isIncome)
        .toList();
    if (!list.any((c) => c.id == _selectedCategory.id)) {
      list.add(_selectedCategory);
    }
    return list;
  }

  void _setKind(bool income) {
    if (income == _isIncome) return;
    setState(() {
      _isIncome = income;
      // Snap the category to the first default of the new kind unless the
      // current one already matches (legacy/custom edge cases).
      if (_selectedCategory.isIncome != income) {
        _selectedCategory = income
            ? HomeCategory.salary
            : HomeCategory.groceries;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.record != null) {
      _isIncome = widget.record!.isIncome;
      _titleController.text = widget.record!.title;
      _amountController.text = widget.record!.amount.toString();
      _descriptionController.text = widget.record!.description ?? '';
      _notesController.text = widget.record!.notes ?? '';
      _selectedCategory = widget.record!.category;
      _selectedDate = widget.record!.date;
      if (widget.record!.quantity != null) {
        _quantityController.text = widget.record!.quantity.toString();
      }
      _selectedUnit = widget.record!.unit;
      _selectedPaymentType = widget.record!.paymentType;
      _selectedEventId = widget.record!.eventId;
    } else {
      if (widget.initialDate != null) {
        _selectedDate = widget.initialDate!;
      }
      // Default new records to UPI when it's available in the user's list.
      // Falls back to null if the user has deleted UPI from settings.
      final upiMatches = widget.paymentTypes.where((p) => p.id == 'upi');
      if (upiMatches.isNotEmpty) {
        _selectedPaymentType = upiMatches.first;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  /// Handle a change in the linked event. Picking an event auto-fills the
  /// amount with that event's total spent (whole numbers shown without a
  /// trailing `.0`); clearing the link leaves the amount untouched.
  void _onEventChanged(String? id) {
    setState(() {
      _selectedEventId = id;
      if (id != null) {
        final total = widget.groupTotals[id];
        if (total != null) {
          _amountController.text = total % 1 == 0
              ? total.toInt().toString()
              : total.toString();
        }
      }
    });
  }

  HomeRecord? _buildRecord() {
    if (!_formKey.currentState!.validate()) return null;
    // Quantity/unit and event links only apply to expenses.
    final qty = !_isIncome && _quantityController.text.isNotEmpty
        ? double.tryParse(_quantityController.text)
        : null;
    if (_isIncome) _selectedEventId = null;
    // Resolve the linked event's name for a resilient snapshot. Falls back to
    // the record's existing name if the event isn't in the passed list (e.g.
    // it was archived after linking).
    String? eventName;
    if (_selectedEventId != null) {
      final match = widget.groups.where((g) => g.id == _selectedEventId);
      eventName = match.isNotEmpty
          ? match.first.name
          : widget.record?.eventName;
    }
    return HomeRecord(
      id: widget.record?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text,
      category: _selectedCategory,
      amount: double.parse(_amountController.text),
      date: _selectedDate,
      description: _descriptionController.text.isEmpty
          ? null
          : _descriptionController.text,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      quantity: qty,
      unit: qty != null ? (_selectedUnit ?? MeasureUnit.piece) : null,
      paymentType: _selectedPaymentType,
      eventId: _selectedEventId,
      eventName: eventName,
      isIncome: _isIncome,
    );
  }

  void _saveRecord() {
    final record = _buildRecord();
    if (record != null) Navigator.pop(context, record);
  }

  /// Save the current entry directly through the cubit and reset the form so
  /// the user can keep adding more without leaving the page. Date stays as-is
  /// to speed up multi-entry on the same day.
  void _saveAndContinue() {
    final record = _buildRecord();
    if (record == null) return;
    context.read<HomeRecordCubit>().addRecord(record);

    setState(() {
      _titleController.clear();
      _amountController.clear();
      _descriptionController.clear();
      _notesController.clear();
      _quantityController.clear();
      // Keep the current kind so multi-entry of the same type stays fast.
      _selectedCategory = _isIncome
          ? HomeCategory.salary
          : HomeCategory.groceries;
      _selectedUnit = null;
      _selectedPaymentType = null;
      // _selectedDate is intentionally preserved.
    });
    _formKey.currentState?.reset();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Saved "${record.title}"'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Record' : 'Add Record'),
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Expense / Income kind toggle
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: false,
                      icon: Icon(Icons.arrow_upward_rounded, size: 16),
                      label: Text('Expense'),
                    ),
                    ButtonSegment(
                      value: true,
                      icon: Icon(Icons.arrow_downward_rounded, size: 16),
                      label: Text('Income'),
                    ),
                  ],
                  selected: {_isIncome},
                  onSelectionChanged: (sel) => _setKind(sel.first),
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: _isIncome
                        ? Colors.green.withValues(alpha: 0.15)
                        : Colors.red.withValues(alpha: 0.12),
                    selectedForegroundColor: _isIncome
                        ? Colors.green[800]
                        : Colors.red[700],
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Category Dropdown (filtered to the selected kind)
                DropdownButtonFormField<HomeCategory>(
                  key: ValueKey(_isIncome),
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: _kindCategories.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Row(
                        children: [
                          Icon(cat.icon, size: 20, color: cat.color),
                          const SizedBox(width: 8),
                          Text(cat.displayName),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedCategory = value);
                    }
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an amount';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Date Picker
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                    side: BorderSide(color: cs.outline),
                  ),
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Date'),
                  subtitle: Text(
                    DateFormat('EEEE, MMM d, yyyy').format(_selectedDate),
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) {
                      setState(() => _selectedDate = date);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Quantity & Unit row (expenses only)
                if (!_isIncome)
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _quantityController,
                          decoration: const InputDecoration(
                            labelText: 'Quantity',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.numbers_rounded),
                            hintText: 'e.g. 2',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<MeasureUnit>(
                          initialValue: _selectedUnit,
                          decoration: const InputDecoration(
                            labelText: 'Unit',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.straighten_rounded),
                          ),
                          items: MeasureUnit.values.map((u) {
                            return DropdownMenuItem(
                              value: u,
                              child: Text('${u.label} (${u.name})'),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() => _selectedUnit = val);
                          },
                        ),
                      ),
                    ],
                  ),
                if (!_isIncome) const SizedBox(height: 16),

                // Payment type picker (optional)
                _PaymentTypePicker(
                  types: widget.paymentTypes,
                  selected: _selectedPaymentType,
                  onChanged: (t) => setState(() => _selectedPaymentType = t),
                ),
                const SizedBox(height: 16),

                // Event / group link (optional, expenses only). Hidden when
                // there are no events to link to — unless this record already
                // has a link (e.g. to an archived event) to keep editable.
                if (!_isIncome &&
                    (widget.groups.isNotEmpty || _selectedEventId != null)) ...[
                  _EventGroupPicker(
                    groups: widget.groups,
                    selectedId: _selectedEventId,
                    fallbackName: widget.record?.eventName,
                    onChanged: _onEventChanged,
                  ),
                  const SizedBox(height: 16),
                ],

                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.note),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 32),

                if (_isEditing)
                  ElevatedButton(
                    onPressed: _saveRecord,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Update Record',
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saveRecord,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'Save',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _saveAndContinue,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          icon: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                          ),
                          label: const Text(
                            'Continue',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Inline picker for the optional [PaymentType] on a record.
///
/// The list shows every type currently in the user's managed list plus the
/// record's stored type even if it's no longer in that list — so editing an
/// old record never silently drops the value just because the type was
/// deleted from settings.
class _PaymentTypePicker extends StatelessWidget {
  final List<PaymentType> types;
  final PaymentType? selected;
  final ValueChanged<PaymentType?> onChanged;

  const _PaymentTypePicker({
    required this.types,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final merged = <PaymentType>[...types];
    if (selected != null && !merged.any((t) => t.id == selected!.id)) {
      merged.add(selected!);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.payments_rounded, size: 16, color: cs.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              'Payment type (optional)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (merged.isEmpty)
          Text(
            'No payment types yet — add some from Settings.',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          )
        else
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              ChoiceChip(
                label: const Text('None', style: TextStyle(fontSize: 12)),
                selected: selected == null,
                onSelected: (_) => onChanged(null),
                showCheckmark: false,
                visualDensity: VisualDensity.compact,
              ),
              ...merged.map((t) {
                final isSelected = selected?.id == t.id;
                return ChoiceChip(
                  avatar: Icon(t.icon, size: 14, color: t.color),
                  label: Text(
                    t.displayName,
                    style: const TextStyle(fontSize: 12),
                  ),
                  selected: isSelected,
                  onSelected: (_) => onChanged(isSelected ? null : t),
                  selectedColor: t.color.withValues(alpha: 0.2),
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                );
              }),
            ],
          ),
      ],
    );
  }
}

/// Optional dropdown linking a record to an event/group fund (`EventFund`).
///
/// The list is "No event" plus each active event. If the record is linked to
/// an event that isn't in the active list (e.g. it was archived after
/// linking), that link is kept as an extra item using the stored
/// [fallbackName] so editing a record never silently drops it.
class _EventGroupPicker extends StatelessWidget {
  final List<EventFund> groups;
  final String? selectedId;
  final String? fallbackName;
  final ValueChanged<String?> onChanged;

  const _EventGroupPicker({
    required this.groups,
    required this.selectedId,
    required this.fallbackName,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final selectedInList =
        selectedId != null && groups.any((g) => g.id == selectedId);

    return DropdownButtonFormField<String?>(
      initialValue: selectedId,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Link to event (optional)',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.event_note_rounded),
      ),
      items: [
        const DropdownMenuItem<String?>(value: null, child: Text('No event')),
        ...groups.map((g) {
          return DropdownMenuItem<String?>(
            value: g.id,
            child: Row(
              children: [
                Icon(g.icon, size: 18, color: g.color),
                const SizedBox(width: 8),
                Expanded(child: Text(g.name, overflow: TextOverflow.ellipsis)),
              ],
            ),
          );
        }),
        // Keep a link to an archived / removed event visible & selectable.
        if (selectedId != null && !selectedInList)
          DropdownMenuItem<String?>(
            value: selectedId,
            child: Row(
              children: [
                Icon(
                  Icons.event_busy_rounded,
                  size: 18,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    fallbackName ?? 'Linked event',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
      ],
      onChanged: onChanged,
    );
  }
}

/// Month-grid calendar view: 7-column layout (Mon → Sun) where each cell
/// shows the day-of-month plus the total expense for that day. Tapping a
/// cell selects that day; the list of records for the selected day is
/// rendered below the grid.
class _MonthCalendarView extends StatelessWidget {
  final HomeRecordCubit cubit;
  const _MonthCalendarView({required this.cubit});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final state = cubit.state;
    final sel = DateTime(
      state.selectedDate.year,
      state.selectedDate.month,
      state.selectedDate.day,
    );
    // The grid spans the selected cycle, which begins on the configured
    // monthly start date and may cross calendar months.
    final start = cubit.selectedCycleStart;
    final end = cubit.selectedCycleEnd;
    // Days in the cycle, via hours/24 so a DST shift can't drop/add a day.
    final totalDays = (end.difference(start).inHours / 24).round();
    // Monday=1 .. Sunday=7. Leading blanks put Monday at column 0.
    final leading = start.weekday - 1;
    final totalCells = ((leading + totalDays + 6) ~/ 7) * 7;
    final rows = totalCells ~/ 7;
    final dailyTotals = cubit.dailyTotalsForSelectedCycle;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    const dowLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    final dayRecords = cubit.recordsForSelectedDay;
    final dayTotal = dayRecords
        .where((r) => !r.isIncome)
        .fold<double>(0, (s, r) => s + r.amount);
    final dayIncome = dayRecords
        .where((r) => r.isIncome)
        .fold<double>(0, (s, r) => s + r.amount);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Compute the exact grid height so the calendar takes only the
        // space it actually needs and the records list below grows freely.
        const hPad = 8.0;
        const spacing = 4.0;
        const aspect = 0.95;
        final cellWidth = (constraints.maxWidth - hPad * 2 - spacing * 6) / 7;
        final cellHeight = cellWidth / aspect;
        final gridHeight = rows * cellHeight + (rows - 1) * spacing;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Row(
                children: dowLabels
                    .map(
                      (d) => Expanded(
                        child: Center(
                          child: Text(
                            d,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            SizedBox(
              height: gridHeight + 8,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(hPad, 0, hPad, 8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: spacing,
                  crossAxisSpacing: spacing,
                  childAspectRatio: aspect,
                ),
                itemCount: totalCells,
                itemBuilder: (context, i) {
                  final offset = i - leading;
                  if (offset < 0 || offset >= totalDays) {
                    return const SizedBox.shrink();
                  }
                  final date = DateTime(
                    start.year,
                    start.month,
                    start.day + offset,
                  );
                  final amount = dailyTotals[date] ?? 0;
                  final isToday = date == today;
                  final isSelected = date == sel;
                  return _DayCell(
                    day: date.day,
                    isToday: isToday,
                    isSelected: isSelected,
                    amountLabel: amount > 0 ? cubit.formatAmount(amount) : '',
                    onTap: () => cubit.selectDate(date),
                  );
                },
              ),
            ),
            const Divider(height: 1),

            // Selected-day summary header
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
              child: Row(
                children: [
                  Icon(Icons.event_rounded, size: 16, color: cs.onSurface),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      DateFormat('EEEE, d MMM yyyy').format(sel),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (dayRecords.isNotEmpty) ...[
                    if (dayIncome > 0) ...[
                      Text(
                        '+${cubit.formatAmount(dayIncome)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      cubit.formatAmount(dayTotal),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[700],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '(${dayRecords.length})',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Records for the selected day
            Expanded(
              child: dayRecords.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.event_busy_rounded,
                            size: 36,
                            color: cs.outline,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No records on this day',
                            style: TextStyle(
                              fontSize: 13,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 80),
                      itemCount: dayRecords.length,
                      itemBuilder: (_, i) {
                        final r = dayRecords[i];
                        return _RecordCard(
                          record: r,
                          onEdit: () async {
                            final edited = await Navigator.push<HomeRecord>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddHomeRecordPage(
                                  record: r,
                                  categories: cubit.allCategories,
                                  paymentTypes: cubit.paymentTypes,
                                  groups: context
                                      .read<EventCubit>()
                                      .activeEvents,
                                  groupTotals: context
                                      .read<EventCubit>()
                                      .activeEventTotals,
                                ),
                              ),
                            );
                            if (edited != null) {
                              cubit.updateRecord(edited);
                            }
                          },
                          onDelete: () async {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (dctx) => AlertDialog(
                                title: const Text('Delete Record'),
                                content: Text(
                                  'Are you sure you want to delete "${r.title}"?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(dctx, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(dctx, true),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                            if (ok == true) cubit.deleteRecord(r.id);
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final bool isToday;
  final bool isSelected;
  final String amountLabel;
  final VoidCallback? onTap;

  const _DayCell({
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.amountLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasExpense = amountLabel.isNotEmpty;

    // Border priority: selected (thick blue) > today (thin blue) > default.
    final Color borderColor;
    final double borderWidth;
    if (isSelected) {
      borderColor = Colors.blue[700]!;
      borderWidth = 2;
    } else if (isToday) {
      borderColor = Colors.blue;
      borderWidth = 1.4;
    } else {
      borderColor = cs.outlineVariant;
      borderWidth = 1;
    }

    final Color bg;
    if (isSelected) {
      bg = Colors.blue.withValues(alpha: 0.18);
    } else if (isToday) {
      bg = Colors.blue.withValues(alpha: 0.10);
    } else if (hasExpense) {
      bg = Colors.red.withValues(alpha: 0.05);
    } else {
      bg = cs.surfaceContainerLow;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: borderWidth),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$day',
              style: TextStyle(
                fontSize: 12,
                fontWeight: (isToday || isSelected)
                    ? FontWeight.bold
                    : FontWeight.w600,
                color: (isToday || isSelected)
                    ? Colors.blue[800]
                    : cs.onSurface,
              ),
            ),
            const Spacer(),
            if (hasExpense)
              Align(
                alignment: Alignment.bottomRight,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.bottomRight,
                  child: Text(
                    amountLabel,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.red[700],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
