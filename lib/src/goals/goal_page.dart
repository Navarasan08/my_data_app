import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:my_data_app/src/goals/model/goal_model.dart';
import 'package:my_data_app/src/goals/cubit/goal_cubit.dart';
import 'package:my_data_app/src/goals/cubit/goal_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 1. GoalListPage
// ─────────────────────────────────────────────────────────────────────────────

class GoalListPage extends StatelessWidget {
  const GoalListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GoalCubit, GoalState>(
      builder: (context, state) {
        final cubit = context.read<GoalCubit>();
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Goal Tracker'),
              centerTitle: true,
              elevation: 0,
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'Active'),
                  Tab(text: 'Archived'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _GoalTab(
                  goals: cubit.activeGoals,
                  emptyIcon: Icons.flag_outlined,
                  emptyLabel: 'No active goals yet',
                ),
                _GoalTab(
                  goals: cubit.archivedGoals,
                  emptyIcon: Icons.archive_outlined,
                  emptyLabel: 'No archived goals',
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () async {
                final goal = await Navigator.push<Goal>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddGoalPage(),
                  ),
                );
                if (goal != null) {
                  cubit.addGoal(goal);
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Goal'),
            ),
          ),
        );
      },
    );
  }
}

class _GoalTab extends StatelessWidget {
  final List<Goal> goals;
  final IconData emptyIcon;
  final String emptyLabel;

  const _GoalTab({
    Key? key,
    required this.goals,
    required this.emptyIcon,
    required this.emptyLabel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (goals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              emptyLabel,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: goals.length,
      itemBuilder: (context, index) => _GoalCard(goal: goals[index]),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final Goal goal;
  const _GoalCard({Key? key, required this.goal}) : super(key: key);

  List<_DaySquare> _last7DueDates() {
    final today = DateTime.now();
    final squares = <_DaySquare>[];
    var cursor = today;
    while (squares.length < 7) {
      if (goal.isDueForDate(cursor)) {
        final status = goal.statusForDate(cursor);
        squares.add(_DaySquare(date: cursor, status: status));
      }
      cursor = cursor.subtract(const Duration(days: 1));
      // Safety: don't scan more than 60 days back
      if (today.difference(cursor).inDays > 60) break;
    }
    return squares.reversed.toList();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<GoalCubit>();
    final catColor = goal.category.color;
    final rate = (goal.successRate * 100).round();
    final miniDays = _last7DueDates();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: cubit,
              child: GoalDetailPage(goalId: goal.id),
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(goal.category.icon, size: 20, color: catColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(goal.frequency.icon,
                              size: 12, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            goal.frequency.label,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[500]),
                          ),
                          if (goal.currentStreak > 0) ...[
                            const SizedBox(width: 8),
                            Text(
                              '${goal.currentStreak} streak',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Success rate circle
                SizedBox(
                  width: 44,
                  height: 44,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: goal.successRate,
                        strokeWidth: 4,
                        backgroundColor: Colors.grey[200],
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.green[600]!),
                      ),
                      Text(
                        '$rate%',
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Mini calendar row
            if (miniDays.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: miniDays.map((sq) {
                  Color bg;
                  Color border;
                  if (sq.status == GoalDayStatus.success) {
                    bg = Colors.green[400]!;
                    border = Colors.green[400]!;
                  } else if (sq.status == GoalDayStatus.failure) {
                    bg = Colors.red[400]!;
                    border = Colors.red[400]!;
                  } else if (sq.status == GoalDayStatus.skip) {
                    bg = Colors.grey[400]!;
                    border = Colors.grey[400]!;
                  } else {
                    bg = Colors.transparent;
                    border = Colors.grey[400]!;
                  }
                  return Container(
                    width: 18,
                    height: 18,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: border, width: 1.5),
                    ),
                  );
                }).toList(),
              ),
            ],

            // Stats row
            const SizedBox(height: 8),
            Row(
              children: [
                _MiniStat(
                    emoji: '\u{1F525}', value: '${goal.currentStreak}'),
                const SizedBox(width: 12),
                _MiniStat(
                    emoji: '\u2705', value: '${goal.successCount}'),
                const SizedBox(width: 12),
                _MiniStat(
                    emoji: '\u274C', value: '${goal.failureCount}'),
                const Spacer(),
                InkWell(
                  onTap: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete Goal'),
                        content: Text(
                            'Are you sure you want to delete "${goal.title}"?'),
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
                      cubit.deleteGoal(goal.id);
                    }
                  },
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
          ],
        ),
      ),
    );
  }
}

class _DaySquare {
  final DateTime date;
  final GoalDayStatus? status;
  const _DaySquare({required this.date, this.status});
}

class _MiniStat extends StatelessWidget {
  final String emoji;
  final String value;
  const _MiniStat({Key? key, required this.emoji, required this.value})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 3),
        Text(value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. GoalDetailPage
// ─────────────────────────────────────────────────────────────────────────────

class GoalDetailPage extends StatefulWidget {
  final String goalId;
  const GoalDetailPage({Key? key, required this.goalId}) : super(key: key);

  @override
  State<GoalDetailPage> createState() => _GoalDetailPageState();
}

class _GoalDetailPageState extends State<GoalDetailPage> {
  late DateTime _viewMonth;

  @override
  void initState() {
    super.initState();
    _viewMonth = DateTime(DateTime.now().year, DateTime.now().month);
  }

  void _changeMonth(int delta) {
    setState(() {
      _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + delta);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GoalCubit, GoalState>(
      builder: (context, state) {
        final cubit = context.read<GoalCubit>();
        final goal = cubit.getGoalById(widget.goalId);
        if (goal == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Goal not found')),
          );
        }

        final rate = (goal.successRate * 100).round();
        final sortedLogs = List<GoalLog>.from(goal.logs)
          ..sort((a, b) => b.date.compareTo(a.date));

        return Scaffold(
          appBar: AppBar(
            title: Text(goal.title),
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () async {
                  final edited = await Navigator.push<Goal>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddGoalPage(goal: goal),
                    ),
                  );
                  if (edited != null) {
                    cubit.updateGoal(edited);
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.archive_outlined),
                onPressed: () {
                  cubit.archiveGoal(goal.id);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Stats dashboard
              Row(
                children: [
                  _StatTile(
                      label: 'Streak', value: '${goal.currentStreak}'),
                  _StatTile(
                      label: 'Longest', value: '${goal.longestStreak}'),
                  _StatTile(label: 'Rate', value: '$rate%'),
                  _StatTile(
                      label: 'Total', value: '${goal.totalTracked}'),
                ],
              ),

              // Deadline badge
              if (goal.deadline != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: goal.daysLeft >= 0
                        ? Colors.orange[50]
                        : Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: goal.daysLeft >= 0
                          ? Colors.orange[300]!
                          : Colors.red[300]!,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.timer_outlined,
                          size: 16,
                          color: goal.daysLeft >= 0
                              ? Colors.orange[700]
                              : Colors.red[700]),
                      const SizedBox(width: 6),
                      Text(
                        goal.daysLeft >= 0
                            ? '${goal.daysLeft} days left'
                            : 'Deadline passed',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: goal.daysLeft >= 0
                              ? Colors.orange[800]
                              : Colors.red[800],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Calendar header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => _changeMonth(-1),
                  ),
                  Text(
                    DateFormat('MMMM yyyy').format(_viewMonth),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => _changeMonth(1),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Weekday labels
              Row(
                children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                    .map((d) => Expanded(
                          child: Center(
                            child: Text(d,
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey[500])),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 4),

              // Calendar grid
              _buildCalendarGrid(goal, cubit),

              const SizedBox(height: 20),

              // Logs list
              if (sortedLogs.isNotEmpty) ...[
                const Text(
                  'Activity Log',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...sortedLogs.map((log) {
                  IconData icon;
                  Color color;
                  String label;
                  switch (log.status) {
                    case GoalDayStatus.success:
                      icon = Icons.check_circle_rounded;
                      color = Colors.green;
                      label = 'Success';
                    case GoalDayStatus.failure:
                      icon = Icons.cancel_rounded;
                      color = Colors.red;
                      label = 'Failure';
                    case GoalDayStatus.skip:
                      icon = Icons.skip_next_rounded;
                      color = Colors.grey;
                      label = 'Skipped';
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Icon(icon, size: 18, color: color),
                        const SizedBox(width: 8),
                        Text(log.date,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w500)),
                        const SizedBox(width: 8),
                        Text(label,
                            style:
                                TextStyle(fontSize: 12, color: Colors.grey[600])),
                        if (log.note != null && log.note!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              log.note!,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[500]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildCalendarGrid(Goal goal, GoalCubit cubit) {
    final firstDay =
        DateTime(_viewMonth.year, _viewMonth.month, 1);
    final daysInMonth =
        DateTime(_viewMonth.year, _viewMonth.month + 1, 0).day;
    // Monday = 1, so offset is weekday - 1
    final startOffset = firstDay.weekday - 1;

    final cells = <Widget>[];
    // Leading empties
    for (int i = 0; i < startOffset; i++) {
      cells.add(const SizedBox());
    }
    final now = DateTime.now();
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_viewMonth.year, _viewMonth.month, day);
      final isDue = goal.isDueForDate(date);
      final status = goal.statusForDate(date);
      final isToday = date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;

      Color? bg;
      Color? borderColor;
      if (!isDue) {
        bg = null;
        borderColor = isToday ? Colors.blue[300] : null;
      } else if (status == GoalDayStatus.success) {
        bg = Colors.green[400];
        borderColor = isToday ? Colors.blue[800] : Colors.green[400];
      } else if (status == GoalDayStatus.failure) {
        bg = Colors.red[400];
        borderColor = isToday ? Colors.blue[800] : Colors.red[400];
      } else if (status == GoalDayStatus.skip) {
        bg = Colors.grey[400];
        borderColor = isToday ? Colors.blue[800] : Colors.grey[400];
      } else {
        // Due but not logged
        bg = isToday ? Colors.blue[50] : Colors.transparent;
        borderColor = isToday ? Colors.blue : Colors.grey[500];
      }

      cells.add(
        GestureDetector(
          onTap: isDue ? () => _cycleStatus(goal, date, status, cubit) : null,
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: borderColor ?? Colors.transparent,
                width: isToday ? 2.5 : 1.5,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              '$day',
              style: TextStyle(
                fontSize: 12,
                fontWeight: isDue || isToday
                    ? FontWeight.w700
                    : FontWeight.normal,
                color: (status != null && isDue)
                    ? Colors.white
                    : isToday
                        ? Colors.blue[800]
                        : isDue
                            ? Colors.grey[800]
                            : Colors.grey[400],
              ),
            ),
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1,
      children: cells,
    );
  }

  /// Cycle: unlogged → success → failure → skip → unlogged
  void _cycleStatus(
      Goal goal, DateTime date, GoalDayStatus? current, GoalCubit cubit) {
    switch (current) {
      case null:
        cubit.logDay(goal.id, date, GoalDayStatus.success);
      case GoalDayStatus.success:
        cubit.logDay(goal.id, date, GoalDayStatus.failure);
      case GoalDayStatus.failure:
        cubit.logDay(goal.id, date, GoalDayStatus.skip);
      case GoalDayStatus.skip:
        cubit.removeLog(goal.id, date);
    }
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  const _StatTile({Key? key, required this.label, required this.value})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. AddGoalPage
// ─────────────────────────────────────────────────────────────────────────────

class AddGoalPage extends StatefulWidget {
  final Goal? goal;
  const AddGoalPage({Key? key, this.goal}) : super(key: key);

  @override
  State<AddGoalPage> createState() => _AddGoalPageState();
}

class _AddGoalPageState extends State<AddGoalPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  GoalCategory _category = GoalCategory.habit;
  GoalFrequency _frequency = GoalFrequency.daily;
  List<int> _customDays = [];
  DateTime _startDate = DateTime.now();
  DateTime? _deadline;
  bool _hasDeadline = false;

  bool get _isEditing => widget.goal != null;

  @override
  void initState() {
    super.initState();
    if (widget.goal != null) {
      final g = widget.goal!;
      _titleController.text = g.title;
      _descriptionController.text = g.description ?? '';
      _category = g.category;
      _frequency = g.frequency;
      _customDays = List<int>.from(g.customDays ?? []);
      _startDate = g.startDate;
      _deadline = g.deadline;
      _hasDeadline = g.deadline != null;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_frequency == GoalFrequency.custom && _customDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one day')),
      );
      return;
    }

    final goal = Goal(
      id: widget.goal?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      category: _category,
      frequency: _frequency,
      customDays: _frequency == GoalFrequency.custom ? _customDays : null,
      startDate: _startDate,
      deadline: _hasDeadline ? _deadline : null,
      isArchived: widget.goal?.isArchived ?? false,
      logs: widget.goal?.logs ?? [],
    );

    Navigator.pop(context, goal);
  }

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Goal' : 'Add Goal'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter a title' : null,
            ),
            const SizedBox(height: 16),

            // Description
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

            // Category dropdown
            DropdownButtonFormField<GoalCategory>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: GoalCategory.values
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Row(
                          children: [
                            Icon(c.icon, size: 18, color: c.color),
                            const SizedBox(width: 8),
                            Text(c.label),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _category = v);
              },
            ),
            const SizedBox(height: 24),

            // Frequency
            const Text('Frequency',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SegmentedButton<GoalFrequency>(
              segments: GoalFrequency.values
                  .map((f) => ButtonSegment(
                        value: f,
                        label: Text(f.label),
                        icon: Icon(f.icon),
                      ))
                  .toList(),
              selected: {_frequency},
              onSelectionChanged: (s) =>
                  setState(() => _frequency = s.first),
            ),

            // Custom weekday chips
            if (_frequency == GoalFrequency.custom) ...[
              const SizedBox(height: 16),
              const Text('Select Days',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(7, (i) {
                  final dayNum = i + 1; // 1=Mon..7=Sun
                  final selected = _customDays.contains(dayNum);
                  return FilterChip(
                    label: Text(_weekdays[i]),
                    selected: selected,
                    onSelected: (sel) {
                      setState(() {
                        if (sel) {
                          _customDays.add(dayNum);
                          _customDays.sort();
                        } else {
                          _customDays.remove(dayNum);
                        }
                      });
                    },
                  );
                }),
              ),
            ],
            const SizedBox(height: 16),

            // Start date
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Start Date'),
              subtitle: Text(DateFormat('d MMM yyyy').format(_startDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (picked != null) setState(() => _startDate = picked);
              },
            ),
            const Divider(),

            // Deadline switch + picker
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Set Deadline'),
              value: _hasDeadline,
              onChanged: (v) => setState(() {
                _hasDeadline = v;
                _deadline ??= _startDate.add(const Duration(days: 30));
              }),
            ),
            if (_hasDeadline)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Deadline'),
                subtitle: Text(
                    DateFormat('d MMM yyyy').format(_deadline ?? _startDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _deadline ?? _startDate,
                    firstDate: _startDate,
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) setState(() => _deadline = picked);
                },
              ),

            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(_isEditing ? 'Update Goal' : 'Save Goal',
                  style: const TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
