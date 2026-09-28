import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:my_data_app/src/checklist/checklist_form_page.dart';
import 'package:my_data_app/src/checklist/cubit/checklist_cubit.dart';
import 'package:my_data_app/src/checklist/cubit/checklist_state.dart';
import 'package:my_data_app/src/checklist/model/checklist_model.dart';

/// One checklist: a progress hero, an always-visible composer to add tasks,
/// the open tasks, and a collapsible Completed section.
class ChecklistDetailPage extends StatefulWidget {
  final String groupId;
  const ChecklistDetailPage({super.key, required this.groupId});

  @override
  State<ChecklistDetailPage> createState() => _ChecklistDetailPageState();
}

class _ChecklistDetailPageState extends State<ChecklistDetailPage> {
  final _composerController = TextEditingController();
  final _composerFocus = FocusNode();
  bool _showCompleted = false;

  @override
  void dispose() {
    _composerController.dispose();
    _composerFocus.dispose();
    super.dispose();
  }

  void _addItem(ChecklistCubit cubit) {
    final title = _composerController.text.trim();
    if (title.isEmpty) return;
    cubit.addItem(
      widget.groupId,
      ChecklistItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
      ),
    );
    _composerController.clear();
    // Keep the keyboard up so several tasks can be typed in a row.
    _composerFocus.requestFocus();
  }

  (Color, String) _status(ChecklistGroup group) {
    if (group.isAllCompleted) return (Colors.green, 'Completed 🎉');
    final d = group.daysLeft;
    if (d < 0) return (Colors.red, '${-d} days overdue');
    if (d == 0) return (Colors.red, 'Due today');
    if (d == 1) return (Colors.orange, '1 day left');
    if (d <= 7) return (Colors.orange, '$d days left');
    return (Colors.teal, '$d days left');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return BlocBuilder<ChecklistCubit, ChecklistState>(
      builder: (context, state) {
        final cubit = context.read<ChecklistCubit>();
        final group = cubit.getChecklistById(widget.groupId);

        if (group == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Checklist not found')),
          );
        }

        final (color, statusText) = _status(group);
        final open = group.items.where((i) => !i.isCompleted).toList();
        final done = group.items.where((i) => i.isCompleted).toList();

        return Scaffold(
          appBar: AppBar(
            title: Text(group.name),
            centerTitle: true,
            elevation: 0,
            actions: [
              PopupMenuButton<String>(
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
                      if (confirmed == true && context.mounted) {
                        cubit.deleteChecklist(group.id);
                        Navigator.pop(context);
                      }
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
          body: Column(
            children: [
              // Hero
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, Color.lerp(color, Colors.black, 0.25)!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 64,
                      height: 64,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CircularProgressIndicator(
                            value: group.progress,
                            strokeWidth: 6,
                            backgroundColor: Colors.white24,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                          Center(
                            child: Text(
                              '${(group.progress * 100).round()}%',
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
                            statusText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${group.completedItems} of ${group.totalItems} '
                            'tasks · due '
                            '${DateFormat('d MMM yyyy').format(group.targetDate)}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 12.5,
                            ),
                          ),
                          if (group.description?.isNotEmpty ?? false) ...[
                            const SizedBox(height: 4),
                            Text(
                              group.description!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Composer
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: TextField(
                  controller: _composerController,
                  focusNode: _composerFocus,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _addItem(cubit),
                  decoration: InputDecoration(
                    hintText: 'Add a task…',
                    prefixIcon: const Icon(Icons.add_rounded),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.send_rounded, size: 20),
                      onPressed: () => _addItem(cubit),
                    ),
                    isDense: true,
                    filled: true,
                    fillColor: cs.surfaceContainerLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              // Items
              Expanded(
                child: group.items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_task_rounded,
                              size: 48,
                              color: cs.outlineVariant,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No tasks yet — type one above',
                              style: TextStyle(
                                fontSize: 14,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 32),
                        children: [
                          for (final item in open)
                            _TaskTile(
                              item: item,
                              onToggle: () =>
                                  cubit.toggleItem(widget.groupId, item.id),
                              onDelete: () => cubit.deleteItem(
                                widget.groupId,
                                item.id,
                              ),
                            ),
                          if (done.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () => setState(
                                () => _showCompleted = !_showCompleted,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 4,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _showCompleted
                                          ? Icons.expand_less_rounded
                                          : Icons.expand_more_rounded,
                                      size: 20,
                                      color: cs.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Completed (${done.length})',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: cs.onSurfaceVariant,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (_showCompleted)
                              for (final item in done)
                                _TaskTile(
                                  item: item,
                                  onToggle: () => cubit.toggleItem(
                                    widget.groupId,
                                    item.id,
                                  ),
                                  onDelete: () => cubit.deleteItem(
                                    widget.groupId,
                                    item.id,
                                  ),
                                ),
                          ],
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// One task row with a round animated checkbox. Delete via swipe-away.
class _TaskTile extends StatelessWidget {
  final ChecklistItem item;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _TaskTile({
    required this.item,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: item.isCompleted ? cs.surfaceContainerLow : cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: item.isCompleted ? Colors.green : Colors.transparent,
                    border: Border.all(
                      color: item.isCompleted ? Colors.green : cs.outline,
                      width: 2,
                    ),
                  ),
                  child: item.isCompleted
                      ? const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: Colors.white,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 15,
                          decoration: item.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          color: item.isCompleted
                              ? cs.onSurfaceVariant
                              : cs.onSurface,
                        ),
                      ),
                      if (item.isCompleted && item.completedDate != null)
                        Text(
                          'Done ${DateFormat('d MMM').format(item.completedDate!)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                    ],
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
