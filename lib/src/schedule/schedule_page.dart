import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:my_data_app/src/schedule/model/schedule_model.dart';
import 'package:my_data_app/src/schedule/cubit/schedule_cubit.dart';
import 'package:my_data_app/src/schedule/cubit/schedule_state.dart';
import 'package:my_data_app/src/schedule/schedule_settings_page.dart';

class SchedulePage extends StatelessWidget {
  const SchedulePage({Key? key}) : super(key: key);

  String _daysLeftLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;
    if (diff < 0) return '${-diff}d ago';
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    return 'In $diff days';
  }

  Color _daysLeftColor(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;
    if (diff < 0) return Colors.red;
    if (diff == 0) return Colors.orange;
    if (diff <= 3) return Colors.amber[700]!;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScheduleCubit, ScheduleState>(
      builder: (context, state) {
        final cubit = context.read<ScheduleCubit>();
        final grouped = cubit.groupedFilteredByMonth;
        final totalOccurrences = cubit.filteredCount;
        final pending = cubit.pendingCount;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Schedules'),
            centerTitle: true,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_rounded),
                tooltip: 'Category Settings',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: cubit,
                      child: const ScheduleSettingsPage(),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All',
                      selected: state.filter == ScheduleFilter.all,
                      onTap: () => cubit.setFilter(ScheduleFilter.all),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'This Month',
                      selected: state.filter == ScheduleFilter.thisMonth,
                      onTap: () => cubit.setFilter(ScheduleFilter.thisMonth),
                    ),
                    const Spacer(),
                    Text(
                      '$totalOccurrences events',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[500],
                      ),
                    ),
                    if (pending > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$pending pending',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange[700],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Divider(height: 1),

              Expanded(
                child: grouped.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_available_rounded,
                                size: 48, color: Colors.grey[300]),
                            const SizedBox(height: 12),
                            Text(
                              state.filter == ScheduleFilter.thisMonth
                                  ? 'No schedules this month'
                                  : 'No schedules yet',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView(
                        padding:
                            const EdgeInsets.fromLTRB(12, 8, 12, 80),
                        children: grouped.entries.map((monthGroup) {
                          final key = monthGroup.key;
                          final occ = monthGroup.value;
                          final monthDate = DateTime(
                            int.parse(key.split('-')[0]),
                            int.parse(key.split('-')[1]),
                          );
                          final monthLabel =
                              DateFormat('MMMM yyyy').format(monthDate);
                          final now = DateTime.now();
                          final isCurrentMonth = monthDate.year == now.year &&
                              monthDate.month == now.month;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(4, 12, 4, 8),
                                child: Row(
                                  children: [
                                    Text(
                                      monthLabel,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: isCurrentMonth
                                            ? Colors.blue[700]
                                            : Colors.grey[700],
                                      ),
                                    ),
                                    if (isCurrentMonth) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.blue,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'NOW',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                    const Spacer(),
                                    Text(
                                      '${occ.length}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ...occ.map((o) => _ScheduleItem(
                                    entry: o.entry,
                                    occurrenceDate: o.date,
                                    daysLeftLabel: _daysLeftLabel(o.date),
                                    daysLeftColor: _daysLeftColor(o.date),
                                    onToggle: () =>
                                        cubit.toggleComplete(o.entry.id),
                                    onEdit: () async {
                                      final edited = await Navigator.push<
                                          ScheduleEntry>(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => BlocProvider.value(
                                            value: cubit,
                                            child: AddSchedulePage(
                                                entry: o.entry),
                                          ),
                                        ),
                                      );
                                      if (edited != null) {
                                        cubit.updateEntry(edited);
                                      }
                                    },
                                    onDelete: () async {
                                      final confirmed =
                                          await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Delete Schedule'),
                                          content: Text(
                                              'Delete "${o.entry.title}"?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, false),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, true),
                                              style: TextButton.styleFrom(
                                                  foregroundColor: Colors.red),
                                              child: const Text('Delete'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirmed == true) {
                                        cubit.deleteEntry(o.entry.id);
                                      }
                                    },
                                  )),
                            ],
                          );
                        }).toList(),
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              final newEntry = await Navigator.push<ScheduleEntry>(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: cubit,
                    child: const AddSchedulePage(),
                  ),
                ),
              );
              if (newEntry != null) {
                cubit.addEntry(newEntry);
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Schedule'),
          ),
        );
      },
    );
  }
}

// ─── Filter Chip ─────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.blue[700] : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }
}

// ─── Schedule Item ───────────────────────────────────────────────────────────

class _ScheduleItem extends StatelessWidget {
  final ScheduleEntry entry;
  final DateTime occurrenceDate;
  final String daysLeftLabel;
  final Color daysLeftColor;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ScheduleItem({
    required this.entry,
    required this.occurrenceDate,
    required this.daysLeftLabel,
    required this.daysLeftColor,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cat = entry.category;
    final dateStr = DateFormat('EEE, d MMM').format(occurrenceDate);
    final repeatLabel = entry.repeatLabel();
    final endLabel = entry.endLabel();

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              GestureDetector(
                onTap: onToggle,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: entry.isCompleted
                        ? cat.color.withValues(alpha: 0.15)
                        : Colors.transparent,
                    border: Border.all(
                      color:
                          entry.isCompleted ? cat.color : Colors.grey[300]!,
                      width: 2,
                    ),
                  ),
                  child: entry.isCompleted
                      ? Icon(Icons.check_rounded,
                          size: 14, color: cat.color)
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 64,
                child: Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 4,
                height: 32,
                decoration: BoxDecoration(
                  color: cat.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              decoration: entry.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: entry.isCompleted
                                  ? Colors.grey[400]
                                  : Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (entry.isRecurring) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.repeat_rounded,
                              size: 12, color: Colors.grey[500]),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      repeatLabel.isNotEmpty
                          ? '$repeatLabel$endLabel'
                          : cat.label,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              if (!entry.isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: daysLeftColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    daysLeftLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: daysLeftColor,
                    ),
                  ),
                )
              else
                Icon(Icons.check_circle_rounded,
                    size: 18, color: Colors.green[400]),
              const SizedBox(width: 6),
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
                      size: 14, color: Colors.red[300]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Add / Edit Schedule Page ────────────────────────────────────────────────

class AddSchedulePage extends StatefulWidget {
  final ScheduleEntry? entry;
  final DateTime? initialDate;

  const AddSchedulePage({Key? key, this.entry, this.initialDate})
      : super(key: key);

  @override
  State<AddSchedulePage> createState() => _AddSchedulePageState();
}

class _AddSchedulePageState extends State<AddSchedulePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _intervalController = TextEditingController();
  late ScheduleCategory _category;
  late DateTime _startDate;
  DateTime? _endDate;
  RepeatMode _repeatMode = RepeatMode.none;
  List<int> _customDays = [];

  bool get _isEditing => widget.entry != null;

  @override
  void initState() {
    super.initState();
    _category = ScheduleCategory.personal;
    if (widget.entry != null) {
      final e = widget.entry!;
      _titleController.text = e.title;
      _descController.text = e.description ?? '';
      _category = e.category;
      _startDate = _dateOnly(e.startDate);
      _endDate = e.endDate != null ? _dateOnly(e.endDate!) : null;
      _repeatMode = e.repeatMode;
      _customDays = List<int>.from(e.customDays ?? []);
      if (e.interval != null) {
        _intervalController.text = e.interval.toString();
      }
    } else {
      final d = widget.initialDate ?? DateTime.now();
      _startDate = DateTime(d.year, d.month, d.day);
    }
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _intervalController.dispose();
    super.dispose();
  }

  bool get _needsInterval =>
      _repeatMode == RepeatMode.everyNDays ||
      _repeatMode == RepeatMode.everyNWeeks ||
      _repeatMode == RepeatMode.everyNMonths;

  bool get _needsCustomDays =>
      _repeatMode == RepeatMode.weeklyOnDays ||
      _repeatMode == RepeatMode.monthlyOnDays;

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_needsCustomDays && _customDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one day'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final entry = ScheduleEntry(
      id: widget.entry?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      description: _descController.text.trim().isEmpty
          ? null
          : _descController.text.trim(),
      startDate: _startDate,
      endDate: _endDate,
      category: _category,
      isCompleted: widget.entry?.isCompleted ?? false,
      repeatMode: _repeatMode,
      customDays: _needsCustomDays ? List<int>.from(_customDays) : null,
      interval: _needsInterval ? int.tryParse(_intervalController.text) : null,
    );
    Navigator.pop(context, entry);
  }

  Future<void> _pickStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (date != null) {
      setState(() {
        _startDate = DateTime(date.year, date.month, date.day);
        if (_endDate != null && _endDate!.isBefore(_startDate)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate.add(const Duration(days: 30)),
      firstDate: _startDate,
      lastDate: DateTime(2035),
    );
    if (date != null) {
      setState(() => _endDate = DateTime(date.year, date.month, date.day));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Schedule' : 'Add Schedule'),
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
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                Builder(
                  builder: (ctx) {
                    final categories =
                        ctx.read<ScheduleCubit>().allCategories;
                    // Ensure selected value is present in items
                    final selected = categories.contains(_category)
                        ? _category
                        : categories.first;
                    if (selected != _category) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) setState(() => _category = selected);
                      });
                    }
                    return DropdownButtonFormField<ScheduleCategory>(
                      initialValue: selected,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: categories.map((c) {
                        return DropdownMenuItem(
                          value: c,
                          child: Row(
                            children: [
                              Icon(c.icon, size: 18, color: c.color),
                              const SizedBox(width: 8),
                              Text(c.label),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _category = v);
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Start date
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                    side: BorderSide(color: Colors.grey[400]!),
                  ),
                  leading: const Icon(Icons.calendar_today_rounded),
                  title: const Text('Start Date *'),
                  subtitle: Text(
                      DateFormat('EEEE, MMM d, yyyy').format(_startDate)),
                  onTap: _pickStartDate,
                ),
                const SizedBox(height: 12),

                // End date (optional)
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                    side: BorderSide(color: Colors.grey[400]!),
                  ),
                  leading: const Icon(Icons.event_rounded),
                  title: const Text('End Date'),
                  subtitle: Text(_endDate != null
                      ? DateFormat('EEEE, MMM d, yyyy').format(_endDate!)
                      : 'Optional — leave blank for ongoing'),
                  trailing: _endDate != null
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => setState(() => _endDate = null),
                        )
                      : null,
                  onTap: _pickEndDate,
                ),
                const SizedBox(height: 16),

                // Repeat mode
                Text('Repeat',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700])),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: RepeatMode.values.map((m) {
                    final selected = _repeatMode == m;
                    return ChoiceChip(
                      label: Text(m.label,
                          style: const TextStyle(fontSize: 12)),
                      selected: selected,
                      showCheckmark: false,
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                      onSelected: (_) {
                        setState(() {
                          _repeatMode = m;
                          _customDays.clear();
                          _intervalController.clear();
                        });
                      },
                    );
                  }).toList(),
                ),

                // Interval input (every N …)
                if (_needsInterval) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _intervalController,
                    decoration: InputDecoration(
                      labelText: _intervalHint(),
                      hintText: 'e.g. 2',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.repeat_one_rounded),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (!_needsInterval) return null;
                      final n = int.tryParse(v ?? '');
                      if (n == null || n <= 0) {
                        return 'Enter a valid number (1 or more)';
                      }
                      return null;
                    },
                  ),
                ],

                // Weekly days selector
                if (_repeatMode == RepeatMode.weeklyOnDays) ...[
                  const SizedBox(height: 12),
                  Text('Days of week *',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700])),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    children: List.generate(7, (i) {
                      final day = i + 1;
                      const names = [
                        'Mon',
                        'Tue',
                        'Wed',
                        'Thu',
                        'Fri',
                        'Sat',
                        'Sun'
                      ];
                      final selected = _customDays.contains(day);
                      return FilterChip(
                        label: Text(names[i],
                            style: const TextStyle(fontSize: 11)),
                        selected: selected,
                        showCheckmark: false,
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                        onSelected: (v) {
                          setState(() {
                            if (v) {
                              _customDays.add(day);
                            } else {
                              _customDays.remove(day);
                            }
                            _customDays.sort();
                          });
                        },
                      );
                    }),
                  ),
                ],

                // Monthly days selector
                if (_repeatMode == RepeatMode.monthlyOnDays) ...[
                  const SizedBox(height: 12),
                  Text('Days of month *',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700])),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: List.generate(31, (i) {
                      final day = i + 1;
                      final selected = _customDays.contains(day);
                      return FilterChip(
                        label: Text('$day',
                            style: const TextStyle(fontSize: 11)),
                        selected: selected,
                        showCheckmark: false,
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                        onSelected: (v) {
                          setState(() {
                            if (v) {
                              _customDays.add(day);
                            } else {
                              _customDays.remove(day);
                            }
                            _customDays.sort();
                          });
                        },
                      );
                    }),
                  ),
                ],
                const SizedBox(height: 16),

                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    _isEditing ? 'Update Schedule' : 'Save Schedule',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _intervalHint() {
    switch (_repeatMode) {
      case RepeatMode.everyNDays: return 'Every N days';
      case RepeatMode.everyNWeeks: return 'Every N weeks';
      case RepeatMode.everyNMonths: return 'Every N months';
      default: return 'N';
    }
  }
}
