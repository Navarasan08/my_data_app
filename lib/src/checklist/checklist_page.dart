import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:my_data_app/src/checklist/checklist_detail_page.dart';
import 'package:my_data_app/src/checklist/checklist_form_page.dart';
import 'package:my_data_app/src/checklist/cubit/checklist_cubit.dart';
import 'package:my_data_app/src/checklist/cubit/checklist_state.dart';
import 'package:my_data_app/src/checklist/model/checklist_model.dart';

// The module used to be one file; keep its public pages importable from here.
export 'package:my_data_app/src/checklist/checklist_detail_page.dart';
export 'package:my_data_app/src/checklist/checklist_form_page.dart';

/// All checklists in three buckets — In Progress, Upcoming, Completed — with
/// an overall progress hero on top. Everything about one list (items,
/// editing, deleting) lives in [ChecklistDetailPage].
class ChecklistListPage extends StatelessWidget {
  const ChecklistListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChecklistCubit, ChecklistState>(
      builder: (context, state) {
        final cubit = context.read<ChecklistCubit>();
        final inProgress = cubit.inProgress;
        final upcoming = cubit.upcoming;
        final completed = cubit.completed;

        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Checklists'),
              centerTitle: true,
              elevation: 0,
            ),
            body: Column(
              children: [
                _OverallProgressCard(checklists: state.checklists),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                  child: _PillTabBar(
                    tabs: [
                      ('In Progress', inProgress.length),
                      ('Upcoming', upcoming.length),
                      ('Completed', completed.length),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _ChecklistTab(
                        checklists: inProgress,
                        emptyIcon: Icons.rocket_launch_rounded,
                        emptyText: 'Nothing in progress',
                        emptyHint: 'Lists you\'ve started or that are due '
                            'show up here',
                      ),
                      _ChecklistTab(
                        checklists: upcoming,
                        emptyIcon: Icons.event_note_rounded,
                        emptyText: 'Nothing coming up',
                        emptyHint: 'Fresh lists with a future target date '
                            'wait here',
                      ),
                      _ChecklistTab(
                        checklists: completed,
                        emptyIcon: Icons.emoji_events_rounded,
                        emptyText: 'Nothing finished yet',
                        emptyHint: 'Fully ticked-off lists land here',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () async {
                final newGroup = await Navigator.push<ChecklistGroup>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddChecklistGroupPage(),
                  ),
                );
                if (newGroup != null) cubit.addChecklist(newGroup);
              },
              icon: const Icon(Icons.add),
              label: const Text('New Checklist'),
            ),
          ),
        );
      },
    );
  }
}

/// Gradient hero: how much of everything is done, plus item totals.
class _OverallProgressCard extends StatelessWidget {
  final List<ChecklistGroup> checklists;
  const _OverallProgressCard({required this.checklists});

  @override
  Widget build(BuildContext context) {
    final totalItems = checklists.fold(0, (s, c) => s + c.totalItems);
    final doneItems = checklists.fold(0, (s, c) => s + c.completedItems);
    final progress = totalItems == 0 ? 0.0 : doneItems / totalItems;
    final dueSoon = checklists
        .where((c) => !c.isAllCompleted && c.daysLeft >= 0 && c.daysLeft <= 7)
        .length;
    final overdue = checklists
        .where((c) => !c.isAllCompleted && c.daysLeft < 0)
        .length;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade600, Colors.green.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 62,
            height: 62,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 6,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Colors.white,
                  ),
                ),
                Center(
                  child: Text(
                    '${(progress * 100).round()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$doneItems of $totalItems tasks done',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  overdue > 0
                      ? '$overdue overdue · $dueSoon due this week'
                      : dueSoon > 0
                      ? '$dueSoon due this week'
                      : 'All on track',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12.5,
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

/// Segmented pill tab bar with per-tab counts.
class _PillTabBar extends StatelessWidget {
  final List<(String, int)> tabs;
  const _PillTabBar({required this.tabs});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TabBar(
        labelColor: cs.primary,
        unselectedLabelColor: cs.onSurfaceVariant,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        indicator: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 4,
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: [
          for (final (label, count) in tabs)
            Tab(height: 42, text: '$label ($count)'),
        ],
      ),
    );
  }
}

class _ChecklistTab extends StatelessWidget {
  final List<ChecklistGroup> checklists;
  final IconData emptyIcon;
  final String emptyText;
  final String emptyHint;

  const _ChecklistTab({
    required this.checklists,
    required this.emptyIcon,
    required this.emptyText,
    required this.emptyHint,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (checklists.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(emptyIcon, size: 56, color: cs.outlineVariant),
              const SizedBox(height: 14),
              Text(
                emptyText,
                style: TextStyle(fontSize: 16, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 6),
              Text(
                emptyHint,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: cs.outline),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
      itemCount: checklists.length,
      itemBuilder: (context, i) => _ChecklistCard(group: checklists[i]),
    );
  }
}

class _ChecklistCard extends StatelessWidget {
  final ChecklistGroup group;
  const _ChecklistCard({required this.group});

  (Color, String) _dueChip() {
    if (group.isAllCompleted) return (Colors.green, 'Done');
    final d = group.daysLeft;
    if (d < 0) return (Colors.red, '${-d}d overdue');
    if (d == 0) return (Colors.red, 'Due today');
    if (d == 1) return (Colors.orange, 'Tomorrow');
    if (d <= 7) return (Colors.orange, '$d days left');
    return (Colors.blueGrey, DateFormat('d MMM').format(group.targetDate));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cubit = context.read<ChecklistCubit>();
    final (chipColor, chipText) = _dueChip();
    final ringColor = group.isAllCompleted
        ? Colors.green
        : group.daysLeft < 0
        ? Colors.red
        : Colors.teal;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: cubit,
              child: ChecklistDetailPage(groupId: group.id),
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
          child: Row(
            children: [
              SizedBox(
                width: 46,
                height: 46,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: group.progress,
                      strokeWidth: 4.5,
                      backgroundColor: cs.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(ringColor),
                    ),
                    Center(
                      child: group.isAllCompleted
                          ? Icon(
                              Icons.check_rounded,
                              size: 20,
                              color: ringColor,
                            )
                          : Text(
                              '${(group.progress * 100).round()}%',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: ringColor,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${group.completedItems}/${group.totalItems} tasks'
                      '${(group.description?.isNotEmpty ?? false) ? ' · ${group.description}' : ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: chipColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        chipText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: chipColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  size: 20,
                  color: cs.onSurfaceVariant,
                ),
                onSelected: (action) async {
                  switch (action) {
                    case 'edit':
                      final edited = await Navigator.push<ChecklistGroup>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddChecklistGroupPage(group: group),
                        ),
                      );
                      if (edited != null) cubit.updateChecklist(edited);
                    case 'delete':
                      if (!context.mounted) return;
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Checklist'),
                          content: Text(
                            'Delete "${group.name}" and all its items?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) cubit.deleteChecklist(group.id);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit_outlined),
                      title: Text('Edit'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete_outline, color: Colors.red),
                      title: Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
