import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:my_data_app/src/home/home_record_model.dart';
import 'package:my_data_app/src/home/cubit/home_record_cubit.dart';
import 'package:my_data_app/src/home/cubit/home_record_state.dart';
import 'package:my_data_app/src/home/home_record_analysis_page.dart';
import 'package:my_data_app/src/home/home_record_settings_page.dart';

class HomeRecordPage extends StatelessWidget {
  const HomeRecordPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeRecordCubit, HomeRecordState>(
      builder: (context, state) {
        final cubit = context.read<HomeRecordCubit>();
        final filteredRecords = cubit.filteredRecords;
        final displayTotal = cubit.displayTotal;


        return Scaffold(
          appBar: AppBar(
            title: const Text('Home Records'),
            centerTitle: true,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.bar_chart_rounded),
                tooltip: 'Analysis',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: cubit,
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
          body: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final isWide = width > 600;
              final isExtraWide = width > 900;
              final contentMaxWidth = isExtraWide ? 900.0 : double.infinity;
              final gridCols = isExtraWide ? 3 : isWide ? 2 : 1;

              return Column(
                children: [
                  // Month nav (only when monthly calendar enabled)
                  if (state.showMonthlyCalendar)
                    Center(
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(maxWidth: contentMaxWidth),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                    Icons.chevron_left_rounded),
                                onPressed: () =>
                                    cubit.changeMonth(-1),
                                visualDensity: VisualDensity.compact,
                              ),
                              Expanded(
                                child: Text(
                                  DateFormat('MMM yyyy')
                                      .format(state.selectedDate),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                    Icons.chevron_right_rounded),
                                onPressed: () =>
                                    cubit.changeMonth(1),
                                visualDensity: VisualDensity.compact,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                cubit.formatAmount(displayTotal),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red[700],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '(${filteredRecords.length})',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Category Filter Chips (multi-select) + filter icon
                  Center(
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(maxWidth: contentMaxWidth),
                      child: SizedBox(
                        height: 38,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 12),
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label: const Text('All',
                                    style: TextStyle(fontSize: 12)),
                                selected:
                                    state.selectedCategoryIds.isEmpty,
                                onSelected: (_) =>
                                    cubit.clearCategoryFilter(),
                                selectedColor: Colors.green[100],
                                showCheckmark: false,
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4),
                              ),
                            ),
                            ...cubit.categoriesByUsage.map((cat) {
                              final isSelected = state
                                  .selectedCategoryIds
                                  .contains(cat.id);
                              return Padding(
                                padding:
                                    const EdgeInsets.only(right: 6),
                                child: ChoiceChip(
                                  avatar: Icon(cat.icon,
                                      size: 14, color: cat.color),
                                  label: Text(cat.displayName,
                                      style: const TextStyle(
                                          fontSize: 12)),
                                  selected: isSelected,
                                  onSelected: (_) =>
                                      cubit.toggleCategory(cat),
                                  selectedColor: cat.color
                                      .withValues(alpha: 0.2),
                                  showCheckmark: false,
                                  visualDensity: VisualDensity.compact,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4),
                                ),
                              );
                            }),
                            // Trailing multi-select filter icon
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: 4, right: 6, top: 4, bottom: 4),
                              child: _FilterIconButton(
                                activeCount:
                                    state.selectedCategoryIds.length,
                                onTap: () => _openMultiSelectSheet(
                                  context,
                                  cubit,
                                  state.selectedCategoryIds,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Records List / Grid
                  Expanded(
                    child: filteredRecords.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Icon(Icons.home_outlined,
                                    size: 48,
                                    color: Colors.grey[300]),
                                const SizedBox(height: 12),
                                Text(
                                  state.selectedCategoryIds.isNotEmpty
                                      ? 'No records for the selected categories'
                                      : 'No records yet',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                  maxWidth: contentMaxWidth),
                              child: state.showMonthlyCalendar
                                  ? (gridCols > 1
                                      ? GridView.builder(
                                          padding:
                                              const EdgeInsets.fromLTRB(
                                                  12, 4, 12, 12),
                                          gridDelegate:
                                              SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: gridCols,
                                            crossAxisSpacing: 10,
                                            mainAxisSpacing: 10,
                                            childAspectRatio:
                                                isExtraWide ? 2.5 : 2.2,
                                          ),
                                          itemCount:
                                              filteredRecords.length,
                                          itemBuilder: (context, index) {
                                            return _buildRecordItem(
                                                context,
                                                cubit,
                                                filteredRecords[index]);
                                          },
                                        )
                                      : _buildWeekGroupedList(
                                          context, cubit, filteredRecords))
                                  : _buildMonthGroupedList(
                                      context, cubit, filteredRecords),
                            ),
                          ),
                  ),
                ],
              );
            },
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              final newRecord = await Navigator.push<HomeRecord>(
                context,
                MaterialPageRoute(
                    builder: (_) => AddHomeRecordPage(
                        categories: cubit.allCategories,
                        paymentTypes: cubit.paymentTypes)),
              );
              if (newRecord != null) {
                cubit.addRecord(newRecord);
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Record'),
          ),
        );
      },
    );
  }

  Widget _buildMonthGroupedList(
      BuildContext context, HomeRecordCubit cubit, List<HomeRecord> records) {
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
        final monthTotal =
            monthRecords.fold(0.0, (sum, r) => sum + r.amount);
        final monthDate = DateTime.parse('$key-01');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey[200],
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
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            ...monthRecords
                .map((r) => _buildRecordItem(context, cubit, r)),
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
      BuildContext context, HomeRecordCubit cubit, List<HomeRecord> records) {
    final now = DateTime.now();
    // Group records by week (Monday start)
    final grouped = <DateTime, List<HomeRecord>>{};
    for (final r in records) {
      final ws = _weekStart(r.date);
      grouped.putIfAbsent(ws, () => []).add(r);
    }
    // Sort week keys descending (most recent first)
    final sortedWeeks = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    final slivers = <Widget>[
      const SliverToBoxAdapter(child: SizedBox(height: 4)),
    ];

    for (final ws in sortedWeeks) {
      final weekRecords = grouped[ws]!;
      final weekTotal =
          weekRecords.fold(0.0, (sum, r) => sum + r.amount);

      slivers.add(
        SliverPersistentHeader(
          pinned: true,
          delegate: _WeekHeaderDelegate(
            label: _weekLabel(ws, now),
            count: weekRecords.length,
            formattedTotal: cubit.formatAmount(weekTotal),
          ),
        ),
      );

      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) =>
                  _buildRecordItem(context, cubit, weekRecords[i]),
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
      BuildContext context, HomeRecordCubit cubit, HomeRecord record) {
    return _RecordCard(
      record: record,
      onEdit: () async {
        final edited = await Navigator.push<HomeRecord>(
          context,
          MaterialPageRoute(
            builder: (_) => AddHomeRecordPage(
                record: record,
                categories: cubit.allCategories,
                paymentTypes: cubit.paymentTypes),
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
            content: Text(
                'Are you sure you want to delete "${record.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style:
                    TextButton.styleFrom(foregroundColor: Colors.red),
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
    final categories = cubit.categoriesByUsage;
    final selected = Set<String>.from(initial);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(builder: (ctx, setSt) {
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
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
                  child: Row(
                    children: [
                      Icon(Icons.filter_list_rounded,
                          size: 18, color: Colors.grey[700]),
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
                        controlAffinity:
                            ListTileControlAffinity.trailing,
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
                            Text(cat.displayName,
                                style: const TextStyle(fontSize: 14)),
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
                            child: Text(selected.isEmpty
                                ? 'Show all'
                                : 'Apply (${selected.length})'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }
}

class _FilterIconButton extends StatelessWidget {
  final int activeCount;
  final VoidCallback onTap;

  const _FilterIconButton({required this.activeCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasFilter = activeCount > 0;
    return Material(
      color: hasFilter ? Colors.green[600] : Colors.grey[100],
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 30,
          height: 30,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Icon(
                Icons.filter_list_rounded,
                size: 16,
                color: hasFilter ? Colors.white : Colors.grey[700],
              ),
              if (hasFilter)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: Colors.white, width: 1),
                    ),
                    constraints:
                        const BoxConstraints(minWidth: 14, minHeight: 14),
                    alignment: Alignment.center,
                    child: Text(
                      '$activeCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
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

class _WeekHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String label;
  final int count;
  final String formattedTotal;

  _WeekHeaderDelegate({
    required this.label,
    required this.count,
    required this.formattedTotal,
  });

  static const double _height = 52;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.date_range_rounded,
                size: 16, color: Colors.grey[700]),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            const Spacer(),
            Text(
              formattedTotal,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.grey[800],
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
        oldDelegate.formattedTotal != formattedTotal;
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
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: record.category.color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(
            color: record.category.color,
            width: 3,
          ),
        ),
      ),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              Icon(record.category.icon,
                  size: 20, color: record.category.color),
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
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                context.read<HomeRecordCubit>().formatAmount(record.amount),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
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
                  child: Icon(Icons.delete_outline_rounded,
                      size: 16, color: Colors.red[300]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AddHomeRecordPage extends StatefulWidget {
  final HomeRecord? record;
  final List<HomeCategory> categories;
  final List<PaymentType> paymentTypes;

  const AddHomeRecordPage({
    Key? key,
    this.record,
    required this.categories,
    this.paymentTypes = const [],
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

  bool get _isEditing => widget.record != null;

  @override
  void initState() {
    super.initState();
    if (widget.record != null) {
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

  HomeRecord? _buildRecord() {
    if (!_formKey.currentState!.validate()) return null;
    final qty = _quantityController.text.isNotEmpty
        ? double.tryParse(_quantityController.text)
        : null;
    return HomeRecord(
      id: widget.record?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
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
      _selectedCategory = HomeCategory.groceries;
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

                // Category Dropdown
                DropdownButtonFormField<HomeCategory>(
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: widget.categories.map((cat) {
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

                // Quantity & Unit row
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
                const SizedBox(height: 16),

                // Payment type picker (optional)
                _PaymentTypePicker(
                  types: widget.paymentTypes,
                  selected: _selectedPaymentType,
                  onChanged: (t) =>
                      setState(() => _selectedPaymentType = t),
                ),
                const SizedBox(height: 16),

                // Date Picker
                ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                    side: BorderSide(color: Colors.grey[600]!),
                  ),
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Date'),
                  subtitle: Text(
                    DateFormat('EEEE, MMM d, yyyy')
                        .format(_selectedDate),
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
                            padding:
                                const EdgeInsets.symmetric(vertical: 16),
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
                            padding:
                                const EdgeInsets.symmetric(vertical: 16),
                          ),
                          icon: const Icon(Icons.arrow_forward_rounded,
                              size: 18),
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
    final merged = <PaymentType>[...types];
    if (selected != null && !merged.any((t) => t.id == selected!.id)) {
      merged.add(selected!);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.payments_rounded, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 6),
            Text(
              'Payment type (optional)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (merged.isEmpty)
          Text(
            'No payment types yet — add some from Settings.',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
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
                  label: Text(t.displayName,
                      style: const TextStyle(fontSize: 12)),
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
