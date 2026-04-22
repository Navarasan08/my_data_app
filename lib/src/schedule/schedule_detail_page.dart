import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:my_data_app/src/schedule/model/schedule_model.dart';
import 'package:my_data_app/src/schedule/cubit/schedule_cubit.dart';
import 'package:my_data_app/src/schedule/cubit/schedule_state.dart';
import 'package:my_data_app/src/schedule/schedule_page.dart';

/// Detail page for a single schedule entry.
///
/// Shows summary stats (completed / skipped / streak / next due),
/// the full list of completed and skipped occurrences, and provides
/// edit and delete actions (with this/series scope when recurring).
class ScheduleDetailPage extends StatelessWidget {
  final String entryId;
  const ScheduleDetailPage({super.key, required this.entryId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScheduleCubit, ScheduleState>(
      builder: (context, state) {
        final cubit = context.read<ScheduleCubit>();
        final entry = state.entries.firstWhere(
          (e) => e.id == entryId,
          orElse: () => state.entries.isEmpty
              ? _placeholder()
              : state.entries.first,
        );

        // If the entry was deleted, pop back.
        if (!state.entries.any((e) => e.id == entryId)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (Navigator.canPop(context)) Navigator.pop(context);
          });
          return const Scaffold();
        }

        final cat = entry.category;
        final completed = List<DateTime>.from(entry.completedDates)
          ..sort((a, b) => b.compareTo(a));
        final skipped = List<DateTime>.from(entry.skippedDates)
          ..sort((a, b) => b.compareTo(a));
        final streak = _currentStreak(entry, completed);
        final nextDue = _nextDue(entry);

        return Scaffold(
          appBar: AppBar(
            title: Text(
              entry.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_rounded),
                tooltip: 'Edit',
                onPressed: () => _onEdit(context, cubit, entry),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                tooltip: 'Delete',
                onPressed: () => _onDelete(context, cubit, entry),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(14),
            children: [
              // Header card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cat.color.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border(
                    left: BorderSide(color: cat.color, width: 4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: cat.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(cat.icon, size: 18, color: cat.color),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          cat.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: cat.color,
                          ),
                        ),
                        const Spacer(),
                        if (entry.isRecurring)
                          Icon(Icons.repeat_rounded,
                              size: 14, color: Colors.grey[500]),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      entry.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (entry.description != null &&
                        entry.description!.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        entry.description!,
                        style:
                            TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                    ],
                    const SizedBox(height: 10),
                    _MetaRow(
                      icon: Icons.event_rounded,
                      label: 'Started',
                      value: DateFormat('EEE, d MMM yyyy')
                          .format(entry.startDate),
                    ),
                    if (entry.endDate != null) ...[
                      const SizedBox(height: 4),
                      _MetaRow(
                        icon: Icons.event_busy_rounded,
                        label: 'Ends',
                        value: DateFormat('EEE, d MMM yyyy')
                            .format(entry.endDate!),
                      ),
                    ],
                    if (entry.isRecurring) ...[
                      const SizedBox(height: 4),
                      _MetaRow(
                        icon: Icons.repeat_rounded,
                        label: 'Repeats',
                        value: entry.repeatLabel(),
                      ),
                    ],
                    if (nextDue != null) ...[
                      const SizedBox(height: 4),
                      _MetaRow(
                        icon: Icons.upcoming_rounded,
                        label: 'Next due',
                        value: DateFormat('EEE, d MMM yyyy').format(nextDue),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Summary stats
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Completed',
                      value: '${completed.length}',
                      icon: Icons.check_circle_rounded,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatCard(
                      label: 'Skipped',
                      value: '${skipped.length}',
                      icon: Icons.cancel_rounded,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatCard(
                      label: 'Streak',
                      value: '$streak',
                      icon: Icons.local_fire_department_rounded,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Completed list
              _SectionTitle(
                title: 'Completed',
                count: completed.length,
                icon: Icons.check_circle_outline_rounded,
                color: Colors.green,
              ),
              if (completed.isEmpty)
                _EmptyHint(text: 'No occurrences completed yet')
              else
                ...completed.map((d) => _OccurrenceTile(
                      date: d,
                      icon: Icons.check_rounded,
                      color: Colors.green,
                      onUndo: () => cubit.toggleCompleteOn(entry.id, d),
                    )),
              const SizedBox(height: 16),

              // Skipped list
              _SectionTitle(
                title: 'Skipped',
                count: skipped.length,
                icon: Icons.skip_next_rounded,
                color: Colors.orange,
              ),
              if (skipped.isEmpty)
                _EmptyHint(text: 'No skipped occurrences')
              else
                ...skipped.map((d) => _OccurrenceTile(
                      date: d,
                      icon: Icons.close_rounded,
                      color: Colors.orange,
                      onUndo: () {
                        // restore by removing from skippedDates
                        final next = entry.skippedDates
                            .where((s) =>
                                DateTime(s.year, s.month, s.day) !=
                                DateTime(d.year, d.month, d.day))
                            .toList();
                        cubit.updateEntry(entry.copyWith(skippedDates: next));
                      },
                    )),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  /// Find the next future due date for this entry.
  DateTime? _nextDue(ScheduleEntry entry) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final occ = entry.occurrencesInRange(
      today,
      DateTime(today.year + 2, today.month, today.day),
    );
    return occ.isNotEmpty ? occ.first : null;
  }

  /// Count consecutive completed occurrences ending at the most recent due date.
  int _currentStreak(ScheduleEntry entry, List<DateTime> completedDesc) {
    if (completedDesc.isEmpty) return 0;
    if (!entry.isRecurring) return 1;
    int streak = 0;
    final pastOcc = entry.occurrencesInRange(
      DateTime(entry.startDate.year - 5, 1, 1),
      DateTime.now(),
    )..sort((a, b) => b.compareTo(a));
    for (final d in pastOcc) {
      final dKey = DateTime(d.year, d.month, d.day);
      if (entry.isCompletedOn(dKey)) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  Future<void> _onEdit(BuildContext context, ScheduleCubit cubit,
      ScheduleEntry entry) async {
    final edited = await Navigator.push<ScheduleEntry>(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: AddSchedulePage(entry: entry),
        ),
      ),
    );
    if (edited != null) cubit.updateEntry(edited);
  }

  Future<void> _onDelete(BuildContext context, ScheduleCubit cubit,
      ScheduleEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Series'),
        content: Text(
            'Delete "${entry.title}" and all of its occurrences?'),
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
      cubit.deleteEntry(entry.id);
      if (context.mounted) Navigator.pop(context);
    }
  }

  ScheduleEntry _placeholder() => ScheduleEntry(
        id: '',
        title: '',
        startDate: DateTime.now(),
        category: ScheduleCategory.other,
      );
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetaRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Text('$label: ',
            style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color.withValues(alpha: 0.85),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color color;

  const _SectionTitle(
      {required this.title,
      required this.count,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                )),
          ),
        ],
      ),
    );
  }
}

class _OccurrenceTile extends StatelessWidget {
  final DateTime date;
  final IconData icon;
  final Color color;
  final VoidCallback onUndo;

  const _OccurrenceTile(
      {required this.date,
      required this.icon,
      required this.color,
      required this.onUndo});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 12, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              DateFormat('EEE, d MMM yyyy').format(date),
              style: const TextStyle(fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: onUndo,
            style: TextButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: const Size(0, 28),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Undo', style: TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[500],
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
