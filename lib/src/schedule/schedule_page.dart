import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:my_data_app/src/schedule/model/schedule_model.dart';
import 'package:my_data_app/src/schedule/cubit/schedule_cubit.dart';
import 'package:my_data_app/src/schedule/cubit/schedule_state.dart';

class SchedulePage extends StatelessWidget {
  const SchedulePage({Key? key}) : super(key: key);

  String _daysLeftLabel(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final diff = target.difference(today).inDays;
    if (diff < 0) return '${-diff}d ago';
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff <= 7) return 'In $diff days';
    return 'In $diff days';
  }

  Color _daysLeftColor(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dateTime.year, dateTime.month, dateTime.day);
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
        final grouped = cubit.groupedByMonth;
        final total = state.entries.length;
        final pending = cubit.pendingCount;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Schedules'),
            centerTitle: true,
            elevation: 0,
          ),
          body: state.entries.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_available_rounded,
                          size: 48, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text(
                        'No schedules yet',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
                  children: [
                    // Summary
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 4),
                      child: Row(
                        children: [
                          Text(
                            '$total events',
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
                    const SizedBox(height: 4),

                    // Month groups
                    ...grouped.entries.map((monthGroup) {
                      final key = monthGroup.key;
                      final entries = monthGroup.value;
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
                          // Month header
                          Padding(
                            padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
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
                                  '${entries.length}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Entries
                          ...entries.map((entry) => _ScheduleItem(
                                entry: entry,
                                daysLeftLabel:
                                    _daysLeftLabel(entry.dateTime),
                                daysLeftColor:
                                    _daysLeftColor(entry.dateTime),
                                onToggle: () =>
                                    cubit.toggleComplete(entry.id),
                                onEdit: () async {
                                  final edited = await Navigator.push<
                                      ScheduleEntry>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          AddSchedulePage(entry: entry),
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
                                      title: const Text(
                                          'Delete Schedule'),
                                      content: Text(
                                          'Delete "${entry.title}"?'),
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
                                              foregroundColor:
                                                  Colors.red),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirmed == true) {
                                    cubit.deleteEntry(entry.id);
                                  }
                                },
                              )),
                        ],
                      );
                    }),
                  ],
                ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              final newEntry = await Navigator.push<ScheduleEntry>(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddSchedulePage(),
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

// ─── Schedule Item ───────────────────────────────────────────────────────────

class _ScheduleItem extends StatelessWidget {
  final ScheduleEntry entry;
  final String daysLeftLabel;
  final Color daysLeftColor;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ScheduleItem({
    required this.entry,
    required this.daysLeftLabel,
    required this.daysLeftColor,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cat = entry.category;
    final timeStr = DateFormat('h:mm a').format(entry.dateTime);
    final dateStr = DateFormat('EEE, d').format(entry.dateTime);

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
              // Completion toggle
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
              // Date + time column
              SizedBox(
                width: 52,
                child: Column(
                  children: [
                    Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[400],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Color bar
              Container(
                width: 4,
                height: 32,
                decoration: BoxDecoration(
                  color: cat.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
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
                    const SizedBox(height: 2),
                    Text(
                      cat.label,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              // Days left badge
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
              // Delete
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
  ScheduleCategory _category = ScheduleCategory.personal;
  late DateTime _dateTime;
  DateTime? _endTime;

  bool get _isEditing => widget.entry != null;

  @override
  void initState() {
    super.initState();
    if (widget.entry != null) {
      _titleController.text = widget.entry!.title;
      _descController.text = widget.entry!.description ?? '';
      _category = widget.entry!.category;
      _dateTime = widget.entry!.dateTime;
      _endTime = widget.entry!.endTime;
    } else {
      final d = widget.initialDate ?? DateTime.now();
      _dateTime = DateTime(d.year, d.month, d.day,
          DateTime.now().hour, DateTime.now().minute);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final entry = ScheduleEntry(
      id: widget.entry?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      description:
          _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      dateTime: _dateTime,
      endTime: _endTime,
      category: _category,
      isCompleted: widget.entry?.isCompleted ?? false,
    );
    Navigator.pop(context, entry);
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date != null) {
      setState(() {
        _dateTime = DateTime(
            date.year, date.month, date.day, _dateTime.hour, _dateTime.minute);
      });
    }
  }

  Future<void> _pickTime({bool isEnd = false}) async {
    final initial = isEnd
        ? TimeOfDay.fromDateTime(_endTime ?? _dateTime)
        : TimeOfDay.fromDateTime(_dateTime);
    final time = await showTimePicker(context: context, initialTime: initial);
    if (time != null) {
      setState(() {
        if (isEnd) {
          _endTime = DateTime(
              _dateTime.year, _dateTime.month, _dateTime.day,
              time.hour, time.minute);
        } else {
          _dateTime = DateTime(
              _dateTime.year, _dateTime.month, _dateTime.day,
              time.hour, time.minute);
        }
      });
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

                DropdownButtonFormField<ScheduleCategory>(
                  value: _category,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: ScheduleCategory.values.map((c) {
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
                ),
                const SizedBox(height: 16),

                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                    side: BorderSide(color: Colors.grey[400]!),
                  ),
                  leading: const Icon(Icons.calendar_today_rounded),
                  title: const Text('Date'),
                  subtitle: Text(
                      DateFormat('EEEE, MMM d, yyyy').format(_dateTime)),
                  onTap: _pickDate,
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                          side: BorderSide(color: Colors.grey[400]!),
                        ),
                        leading: const Icon(Icons.access_time_rounded),
                        title: const Text('Start'),
                        subtitle: Text(
                            DateFormat('h:mm a').format(_dateTime)),
                        onTap: () => _pickTime(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                          side: BorderSide(color: Colors.grey[400]!),
                        ),
                        leading:
                            const Icon(Icons.access_time_filled_rounded),
                        title: const Text('End'),
                        subtitle: Text(_endTime != null
                            ? DateFormat('h:mm a').format(_endTime!)
                            : 'Optional'),
                        onTap: () => _pickTime(isEnd: true),
                      ),
                    ),
                  ],
                ),
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
}
