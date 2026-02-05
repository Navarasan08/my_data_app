import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:my_data_app/src/reminder/model/bill_model.dart';
import 'package:my_data_app/src/reminder/cubit/bill_cubit.dart';
import 'package:my_data_app/src/reminder/cubit/bill_state.dart';

class BillTaskPage extends StatelessWidget {
  const BillTaskPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BillCubit, BillState>(
      builder: (context, state) {
        final cubit = context.read<BillCubit>();
        final monthYear = DateFormat('MMMM yyyy').format(state.selectedDate);
        final tasksForMonth = cubit.tasksForSelectedMonth;
        final stats = cubit.monthStatistics;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Bills & Tasks'),
            centerTitle: true,
            elevation: 0,
          ),
          body: Column(
            children: [
              // Month Selector
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => cubit.changeMonth(-1),
                    ),
                    Text(
                      monthYear,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () => cubit.changeMonth(1),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Statistics Overview Bar
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: Colors.white,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.cancel_outlined,
                            label: 'Missed',
                            count: stats['missed'],
                            amount: stats['missedAmount'],
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.pending_outlined,
                            label: 'Pending',
                            count: stats['pending'],
                            amount: stats['pendingAmount'],
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.check_circle_outline,
                            label: 'Completed',
                            count: stats['completed'],
                            amount: null,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.receipt_long,
                                  color: Colors.blue[700], size: 18),
                              const SizedBox(width: 6),
                              Text(
                                'Total Amount',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.blue[900],
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '\$${stats['paidAmount'].toStringAsFixed(2)} / \$${stats['totalAmount'].toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[900],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Tasks List
              Expanded(
                child: tasksForMonth.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox_outlined,
                                size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No bills or tasks for this month',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: tasksForMonth.length,
                        itemBuilder: (context, index) {
                          final task = tasksForMonth[index];
                          return TaskCard(
                            task: task,
                            selectedMonth: state.selectedDate,
                            onToggle: (date) =>
                                cubit.toggleCompletion(task.id, date),
                            onEdit: () async {
                              final editedTask =
                                  await Navigator.push<BillTask>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      AddTaskPage(task: task),
                                ),
                              );
                              if (editedTask != null) {
                                cubit.updateTask(editedTask);
                              }
                            },
                            onDelete: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Task'),
                                  content: Text(
                                      'Are you sure you want to delete "${task.title}"?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      style: TextButton.styleFrom(
                                          foregroundColor: Colors.red),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true) {
                                cubit.deleteTask(task.id);
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
              final newTask = await Navigator.push<BillTask>(
                context,
                MaterialPageRoute(builder: (context) => const AddTaskPage()),
              );
              if (newTask != null) {
                cubit.addTask(newTask);
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Bill/Task'),
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final double? amount;
  final Color color;

  const _StatCard({
    Key? key,
    required this.icon,
    required this.label,
    required this.count,
    this.amount,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: color.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (amount != null && amount! > 0) ...[
            const SizedBox(height: 2),
            Text(
              '\$${amount!.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color.withOpacity(0.9),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class TaskCard extends StatelessWidget {
  final BillTask task;
  final DateTime selectedMonth;
  final Function(DateTime) onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TaskCard({
    Key? key,
    required this.task,
    required this.selectedMonth,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  String _getRecurrenceText() {
    switch (task.recurrence) {
      case RecurrenceType.daily:
        return 'Daily';
      case RecurrenceType.weekly:
        return 'Weekly (${DateFormat('EEEE').format(task.createdDate)})';
      case RecurrenceType.monthly:
        return 'Monthly (Day ${task.createdDate.day})';
      case RecurrenceType.custom:
        return 'Custom (Days: ${task.customDays?.join(', ')})';
    }
  }

  List<DateTime> _getDueDatesInMonth() {
    final daysInMonth =
        DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;
    final dueDates = <DateTime>[];

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(selectedMonth.year, selectedMonth.month, day);
      if (task.isDueForDate(date)) {
        dueDates.add(date);
      }
    }
    return dueDates;
  }

  @override
  Widget build(BuildContext context) {
    final dueDates = _getDueDatesInMonth();
    final completedCount =
        dueDates.where((date) => task.isCompletedForDate(date)).length;
    final totalCount = dueDates.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (task.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          task.description!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (task.amount != null)
                  Text(
                    '\$${task.amount!.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  color: Colors.blue[400],
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.red[400],
                  onPressed: onDelete,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.repeat, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  _getRecurrenceText(),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                const Spacer(),
                Text(
                  '$completedCount/$totalCount completed',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: dueDates.map((date) {
                final isCompleted = task.isCompletedForDate(date);
                final isPast = date.isBefore(DateTime.now()) && !isCompleted;

                return InkWell(
                  onTap: () => onToggle(date),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? Colors.green[100]
                          : isPast
                              ? Colors.red[50]
                              : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isCompleted
                            ? Colors.green
                            : isPast
                                ? Colors.red[300]!
                                : Colors.grey[300]!,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isCompleted
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          size: 16,
                          color: isCompleted
                              ? Colors.green[700]
                              : isPast
                                  ? Colors.red[400]
                                  : Colors.grey[600],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat('MMM d').format(date),
                          style: TextStyle(
                            fontSize: 13,
                            color: isCompleted
                                ? Colors.green[700]
                                : isPast
                                    ? Colors.red[700]
                                    : Colors.grey[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class AddTaskPage extends StatefulWidget {
  final BillTask? task;

  const AddTaskPage({Key? key, this.task}) : super(key: key);

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  RecurrenceType _selectedRecurrence = RecurrenceType.monthly;
  DateTime _selectedDate = DateTime.now();
  List<int> _customDays = [];

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description ?? '';
      _amountController.text = widget.task!.amount?.toString() ?? '';
      _selectedRecurrence = widget.task!.recurrence;
      _selectedDate = widget.task!.createdDate;
      _customDays = List<int>.from(widget.task!.customDays ?? []);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _saveTask() {
    if (_formKey.currentState!.validate()) {
      if (_selectedRecurrence == RecurrenceType.custom && _customDays.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Please select at least one day for custom recurrence')),
        );
        return;
      }

      final task = BillTask(
        id: widget.task?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        amount: _amountController.text.isEmpty
            ? null
            : double.tryParse(_amountController.text),
        recurrence: _selectedRecurrence,
        customDays:
            _selectedRecurrence == RecurrenceType.custom ? _customDays : null,
        createdDate: _selectedDate,
      );

      Navigator.pop(context, task);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Bill/Task' : 'Add Bill/Task'),
        elevation: 0,
      ),
      body: Form(
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
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount (optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            const Text(
              'Recurrence Pattern',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...RecurrenceType.values.map((type) {
              return RadioListTile<RecurrenceType>(
                title: Text(_getRecurrenceLabel(type)),
                value: type,
                groupValue: _selectedRecurrence,
                onChanged: (value) {
                  setState(() {
                    _selectedRecurrence = value!;
                  });
                },
              );
            }),
            if (_selectedRecurrence == RecurrenceType.weekly ||
                _selectedRecurrence == RecurrenceType.monthly) ...[
              const SizedBox(height: 16),
              ListTile(
                title: Text(
                  _selectedRecurrence == RecurrenceType.weekly
                      ? 'Select Day of Week'
                      : 'Select Day of Month',
                ),
                subtitle: Text(
                  _selectedRecurrence == RecurrenceType.weekly
                      ? DateFormat('EEEE').format(_selectedDate)
                      : 'Day ${_selectedDate.day}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (date != null) {
                    setState(() {
                      _selectedDate = date;
                    });
                  }
                },
              ),
            ],
            if (_selectedRecurrence == RecurrenceType.custom) ...[
              const SizedBox(height: 16),
              const Text(
                'Select Days of Month',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(31, (index) {
                  final day = index + 1;
                  final isSelected = _customDays.contains(day);
                  return FilterChip(
                    label: Text('$day'),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _customDays.add(day);
                          _customDays.sort();
                        } else {
                          _customDays.remove(day);
                        }
                      });
                    },
                  );
                }),
              ),
            ],
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveTask,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(_isEditing ? 'Update Task' : 'Save Task',
                  style: const TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  String _getRecurrenceLabel(RecurrenceType type) {
    switch (type) {
      case RecurrenceType.daily:
        return 'Daily';
      case RecurrenceType.weekly:
        return 'Weekly';
      case RecurrenceType.monthly:
        return 'Monthly';
      case RecurrenceType.custom:
        return 'Custom Days';
    }
  }
}
