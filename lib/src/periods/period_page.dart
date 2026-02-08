import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:my_data_app/src/periods/model/period_model.dart';
import 'package:my_data_app/src/periods/cubit/period_cubit.dart';
import 'package:my_data_app/src/periods/cubit/period_state.dart';

// ─── Period Tracker Page ─────────────────────────────────────────────────────

class PeriodTrackerPage extends StatelessWidget {
  const PeriodTrackerPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PeriodCubit, PeriodState>(
      builder: (context, state) {
        final cubit = context.read<PeriodCubit>();
        final monthYear =
            DateFormat('MMMM yyyy').format(state.selectedMonth);
        final recentEntries = cubit.sortedEntries;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Period Tracker'),
            centerTitle: true,
            elevation: 0,
          ),
          body: ListView(
            children: [
              // Month selector
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

              // Calendar
              _CalendarGrid(
                selectedMonth: state.selectedMonth,
                cubit: cubit,
              ),

              const SizedBox(height: 8),

              // Legend
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _LegendItem(
                        color: Colors.pink[300]!, label: 'Period'),
                    _LegendItem(
                        color: Colors.pink[100]!, label: 'Predicted'),
                    _LegendItem(
                        color: Colors.green[200]!, label: 'Fertile'),
                    _LegendItem(
                        color: Colors.blue[400]!, label: 'Ovulation'),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Stats cards
              _StatsSection(cubit: cubit),

              const SizedBox(height: 16),

              // Recent entries
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              if (recentEntries.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.calendar_today_rounded,
                            size: 48, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text(
                          'No periods logged yet',
                          style: TextStyle(
                              fontSize: 16, color: Colors.grey[500]),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap + to log your first period',
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...recentEntries.map((entry) => _PeriodEntryCard(
                      entry: entry,
                      onEdit: () async {
                        final edited = await Navigator.push<PeriodEntry>(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                AddPeriodEntryPage(entry: entry),
                          ),
                        );
                        if (edited != null) {
                          cubit.updateEntry(edited);
                        }
                      },
                      onDelete: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete Entry'),
                            content: const Text(
                                'Are you sure you want to delete this period entry?'),
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
                          cubit.deleteEntry(entry.id);
                        }
                      },
                    )),

              const SizedBox(height: 80),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              final newEntry = await Navigator.push<PeriodEntry>(
                context,
                MaterialPageRoute(
                    builder: (_) => const AddPeriodEntryPage()),
              );
              if (newEntry != null) {
                cubit.addEntry(newEntry);
              }
            },
            backgroundColor: Colors.pink[400],
            icon: const Icon(Icons.add),
            label: const Text('Log Period'),
          ),
        );
      },
    );
  }
}

// ─── Legend Item ──────────────────────────────────────────────────────────────

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}

// ─── Calendar Grid ───────────────────────────────────────────────────────────

class _CalendarGrid extends StatelessWidget {
  final DateTime selectedMonth;
  final PeriodCubit cubit;

  const _CalendarGrid({required this.selectedMonth, required this.cubit});

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(selectedMonth.year, selectedMonth.month, 1);
    final daysInMonth =
        DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;
    // Monday = 1, Sunday = 7
    final startWeekday = firstDay.weekday;
    final today = DateTime.now();

    const dayHeaders = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Day headers
          Row(
            children: dayHeaders
                .map((d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[500],
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),

          // Day cells
          ...List.generate(6, (week) {
            return Row(
              children: List.generate(7, (weekday) {
                final dayIndex = week * 7 + weekday - (startWeekday - 1);
                if (dayIndex < 0 || dayIndex >= daysInMonth) {
                  return const Expanded(child: SizedBox(height: 40));
                }

                final day = dayIndex + 1;
                final date = DateTime(
                    selectedMonth.year, selectedMonth.month, day);
                final isToday = date.year == today.year &&
                    date.month == today.month &&
                    date.day == today.day;

                final isPeriod = cubit.isPeriodDay(date);
                final isPredicted = cubit.isPredictedPeriodDay(date);
                final isFertile = cubit.isFertileDay(date);
                final isOvulation = cubit.isOvulationDay(date);

                Color? bgColor;
                Color textColor = Colors.grey[800]!;

                if (isPeriod) {
                  bgColor = Colors.pink[300];
                  textColor = Colors.white;
                } else if (isPredicted) {
                  bgColor = Colors.pink[100];
                  textColor = Colors.pink[800]!;
                } else if (isOvulation) {
                  bgColor = Colors.blue[400];
                  textColor = Colors.white;
                } else if (isFertile) {
                  bgColor = Colors.green[100];
                  textColor = Colors.green[800]!;
                }

                return Expanded(
                  child: Container(
                    height: 40,
                    margin: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(8),
                      border: isToday
                          ? Border.all(color: Colors.pink[400]!, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              isToday ? FontWeight.bold : FontWeight.normal,
                          color: textColor,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Stats Section ───────────────────────────────────────────────────────────

class _StatsSection extends StatelessWidget {
  final PeriodCubit cubit;

  const _StatsSection({required this.cubit});

  @override
  Widget build(BuildContext context) {
    final nextPeriod = cubit.nextPeriodStart;
    final fertileStart = cubit.fertileWindowStart;
    final fertileEnd = cubit.fertileWindowEnd;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.loop_rounded,
                  label: 'Cycle Length',
                  value: '${cubit.averageCycleLength} days',
                  color: Colors.purple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.water_drop_rounded,
                  label: 'Period Length',
                  value: '${cubit.averagePeriodLength} days',
                  color: Colors.pink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.event_rounded,
                  label: 'Next Period',
                  value: nextPeriod != null
                      ? DateFormat('MMM d').format(nextPeriod)
                      : '—',
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.favorite_rounded,
                  label: 'Fertile Window',
                  value: fertileStart != null && fertileEnd != null
                      ? '${DateFormat('MMM d').format(fertileStart)} - ${DateFormat('d').format(fertileEnd)}'
                      : '—',
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Period Entry Card ───────────────────────────────────────────────────────

class _PeriodEntryCard extends StatelessWidget {
  final PeriodEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PeriodEntryCard({
    required this.entry,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.pink[50],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.water_drop_rounded,
              color: Colors.pink[400], size: 22),
        ),
        title: Text(
          '${DateFormat('MMM d').format(entry.startDate)} — ${DateFormat('MMM d, yyyy').format(entry.endDate)}',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          '${entry.periodLength} days${entry.notes != null && entry.notes!.isNotEmpty ? '  •  ${entry.notes}' : ''}',
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit_outlined,
                  size: 18, color: Colors.blue[400]),
              onPressed: onEdit,
            ),
            IconButton(
              icon: Icon(Icons.delete_outline,
                  size: 18, color: Colors.red[400]),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Add / Edit Period Entry Page ────────────────────────────────────────────

class AddPeriodEntryPage extends StatefulWidget {
  final PeriodEntry? entry;
  const AddPeriodEntryPage({Key? key, this.entry}) : super(key: key);

  @override
  State<AddPeriodEntryPage> createState() => _AddPeriodEntryPageState();
}

class _AddPeriodEntryPageState extends State<AddPeriodEntryPage> {
  final _notesController = TextEditingController();
  late DateTime _startDate;
  late DateTime _endDate;

  bool get _isEditing => widget.entry != null;

  @override
  void initState() {
    super.initState();
    if (widget.entry != null) {
      _startDate = widget.entry!.startDate;
      _endDate = widget.entry!.endDate;
      _notesController.text = widget.entry!.notes ?? '';
    } else {
      _startDate = DateTime.now();
      _endDate = DateTime.now().add(const Duration(days: 4));
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _save() {
    if (_endDate.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End date must be on or after start date')),
      );
      return;
    }

    final entry = PeriodEntry(
      id: widget.entry?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      startDate: _startDate,
      endDate: _endDate,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
    );
    Navigator.pop(context, entry);
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _startDate : _endDate;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        if (isStart) {
          _startDate = date;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 4));
          }
        } else {
          _endDate = date;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final duration = _endDate.difference(_startDate).inDays + 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Period' : 'Log Period'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Duration preview
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.pink[100]!, Colors.pink[50]!],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.water_drop_rounded,
                    color: Colors.pink[400], size: 28),
                const SizedBox(width: 10),
                Text(
                  '$duration day${duration != 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.pink[700],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Start date
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey[300]!),
            ),
            leading: Icon(Icons.play_circle_rounded,
                color: Colors.pink[400]),
            title: const Text('Start Date'),
            subtitle: Text(
              DateFormat('EEEE, MMM d, yyyy').format(_startDate),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            onTap: () => _pickDate(isStart: true),
          ),

          const SizedBox(height: 12),

          // End date
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey[300]!),
            ),
            leading: Icon(Icons.stop_circle_rounded,
                color: Colors.pink[400]),
            title: const Text('End Date'),
            subtitle: Text(
              DateFormat('EEEE, MMM d, yyyy').format(_endDate),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            onTap: () => _pickDate(isStart: false),
          ),

          const SizedBox(height: 16),

          // Notes
          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.notes_rounded),
            ),
            maxLines: 3,
          ),

          const SizedBox(height: 32),

          ElevatedButton.icon(
            onPressed: _save,
            icon: Icon(
                _isEditing ? Icons.save_rounded : Icons.add_rounded),
            label: Text(_isEditing ? 'Update Entry' : 'Save Entry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink[400],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
