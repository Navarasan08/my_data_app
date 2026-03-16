import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:my_data_app/src/schedule/model/schedule_model.dart';
import 'package:my_data_app/src/schedule/cubit/schedule_cubit.dart';
import 'package:my_data_app/src/schedule/cubit/schedule_state.dart';

class SchedulePage extends StatelessWidget {
  const SchedulePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScheduleCubit, ScheduleState>(
      builder: (context, state) {
        final cubit = context.read<ScheduleCubit>();
        final dayEntries = cubit.entriesForSelectedDate;
        final sel = state.selectedDate;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Schedules'),
            centerTitle: true,
            elevation: 0,
          ),
          body: Column(
            children: [
              // Week strip
              _WeekStrip(
                selectedDate: sel,
                onDateSelected: (d) => cubit.changeDate(d),
              ),
              // Date label + count
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      DateFormat('EEEE, MMM d').format(sel),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${dayEntries.length} event${dayEntries.length != 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              // Entries list
              Expanded(
                child: dayEntries.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_available_rounded,
                                size: 48, color: Colors.grey[300]),
                            const SizedBox(height: 12),
                            Text(
                              'No schedules for this day',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        itemCount: dayEntries.length,
                        itemBuilder: (context, index) {
                          final entry = dayEntries[index];
                          return _ScheduleItem(
                            entry: entry,
                            onToggle: () =>
                                cubit.toggleComplete(entry.id),
                            onEdit: () async {
                              final edited =
                                  await Navigator.push<ScheduleEntry>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AddSchedulePage(
                                      entry: entry),
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
                                  title:
                                      const Text('Delete Schedule'),
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
                          );
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              final newEntry =
                  await Navigator.push<ScheduleEntry>(
                context,
                MaterialPageRoute(
                  builder: (_) => AddSchedulePage(
                      initialDate: sel),
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

// ─── Week Strip ──────────────────────────────────────────────────────────────

class _WeekStrip extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const _WeekStrip({
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    // Show 7 days centered around selected date
    final startOfWeek =
        selectedDate.subtract(Duration(days: selectedDate.weekday - 1));

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, size: 20),
            onPressed: () =>
                onDateSelected(selectedDate.subtract(const Duration(days: 7))),
            visualDensity: VisualDensity.compact,
          ),
          ...List.generate(7, (i) {
            final date = startOfWeek.add(Duration(days: i));
            final isSelected = date.day == selectedDate.day &&
                date.month == selectedDate.month &&
                date.year == selectedDate.year;
            final isToday = date.day == today.day &&
                date.month == today.month &&
                date.year == today.year;

            return Expanded(
              child: GestureDetector(
                onTap: () => onDateSelected(date),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.blue[600]
                        : isToday
                            ? Colors.blue[50]
                            : null,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        DateFormat('E').format(date).substring(0, 2),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? Colors.white70
                              : Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : isToday
                                  ? Colors.blue[700]
                                  : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded, size: 20),
            onPressed: () =>
                onDateSelected(selectedDate.add(const Duration(days: 7))),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

// ─── Schedule Item ───────────────────────────────────────────────────────────

class _ScheduleItem extends StatelessWidget {
  final ScheduleEntry entry;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ScheduleItem({
    required this.entry,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cat = entry.category;
    final timeStr = DateFormat('h:mm a').format(entry.dateTime);
    final endStr = entry.endTime != null
        ? ' — ${DateFormat('h:mm a').format(entry.endTime!)}'
        : '';

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
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: entry.isCompleted
                        ? cat.color.withValues(alpha: 0.15)
                        : Colors.transparent,
                    border: Border.all(
                      color: entry.isCompleted
                          ? cat.color
                          : Colors.grey[300]!,
                      width: 2,
                    ),
                  ),
                  child: entry.isCompleted
                      ? Icon(Icons.check_rounded,
                          size: 16, color: cat.color)
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              // Time column
              SizedBox(
                width: 56,
                child: Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Category dot + content
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
                      '${cat.label}$endStr',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
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

                // Category
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

                // Date
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

                // Start time
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
                        leading: const Icon(Icons.access_time_filled_rounded),
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
