import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:my_data_app/src/checklist/model/checklist_model.dart';
import 'package:my_data_app/src/checklist/cubit/checklist_cubit.dart';
import 'package:my_data_app/src/checklist/cubit/checklist_state.dart';

// ─── Checklist List Page ─────────────────────────────────────────────────────

class ChecklistListPage extends StatelessWidget {
  const ChecklistListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChecklistCubit, ChecklistState>(
      builder: (context, state) {
        final cubit = context.read<ChecklistCubit>();
        final checklists = state.checklists;
        final completedCount =
            checklists.where((c) => c.isAllCompleted).length;
        final inProgressCount = checklists.length - completedCount;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Checklists'),
            centerTitle: true,
            elevation: 0,
          ),
          body: Column(
            children: [
              // Summary bar
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        title: 'Total',
                        count: checklists.length,
                        color: Colors.blue,
                        icon: Icons.checklist_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        title: 'In Progress',
                        count: inProgressCount,
                        color: Colors.orange,
                        icon: Icons.pending_actions_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        title: 'Done',
                        count: completedCount,
                        color: Colors.green,
                        icon: Icons.task_alt_rounded,
                      ),
                    ),
                  ],
                ),
              ),

              // List
              Expanded(
                child: checklists.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.checklist_rounded,
                                size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              'No checklists yet',
                              style: TextStyle(
                                  fontSize: 18, color: Colors.grey[500]),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap + to create your first checklist',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey[400]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: checklists.length,
                        itemBuilder: (context, index) {
                          final group = checklists[index];
                          return _ChecklistGroupCard(
                            group: group,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BlocProvider.value(
                                    value: cubit,
                                    child: ChecklistDetailPage(
                                        groupId: group.id),
                                  ),
                                ),
                              );
                            },
                            onEdit: () async {
                              final edited =
                                  await Navigator.push<ChecklistGroup>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      AddChecklistGroupPage(group: group),
                                ),
                              );
                              if (edited != null) {
                                cubit.updateChecklist(edited);
                              }
                            },
                            onDelete: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete Checklist'),
                                  content: Text(
                                      'Are you sure you want to delete "${group.name}"? All items will also be deleted.'),
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
                                cubit.deleteChecklist(group.id);
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
              final newGroup = await Navigator.push<ChecklistGroup>(
                context,
                MaterialPageRoute(
                    builder: (_) => const AddChecklistGroupPage()),
              );
              if (newGroup != null) {
                cubit.addChecklist(newGroup);
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('New Checklist'),
          ),
        );
      },
    );
  }
}

// ─── Summary Card ────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 11, color: color),
          ),
        ],
      ),
    );
  }
}

// ─── Checklist Group Card ────────────────────────────────────────────────────

class _ChecklistGroupCard extends StatelessWidget {
  final ChecklistGroup group;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ChecklistGroupCard({
    required this.group,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  Color _daysLeftColor() {
    if (group.isAllCompleted) return Colors.green;
    if (group.daysLeft < 0) return Colors.red;
    if (group.daysLeft <= 3) return Colors.orange;
    return Colors.blue;
  }

  String _daysLeftText() {
    if (group.isAllCompleted) return 'Completed';
    if (group.daysLeft < 0) return '${-group.daysLeft}d overdue';
    if (group.daysLeft == 0) return 'Due today';
    return '${group.daysLeft}d left';
  }

  @override
  Widget build(BuildContext context) {
    final color = _daysLeftColor();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child:
                        Icon(Icons.checklist_rounded, color: color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: color.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                _daysLeftText(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.calendar_today_rounded,
                                size: 12, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('MMM d, yyyy')
                                  .format(group.targetDate),
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    color: Colors.blue[400],
                    onPressed: onEdit,
                    iconSize: 20,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.red[400],
                    onPressed: onDelete,
                    iconSize: 20,
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: group.progress,
                  minHeight: 8,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),

              const SizedBox(height: 10),

              // Stats row
              Row(
                children: [
                  Icon(Icons.format_list_numbered_rounded,
                      size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    '${group.totalItems} items',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.check_circle_outline_rounded,
                      size: 14, color: Colors.green[400]),
                  const SizedBox(width: 4),
                  Text(
                    '${group.completedItems} done',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const Spacer(),
                  Text(
                    '${(group.progress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color,
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

// ─── Checklist Detail Page ───────────────────────────────────────────────────

class ChecklistDetailPage extends StatelessWidget {
  final String groupId;

  const ChecklistDetailPage({Key? key, required this.groupId})
      : super(key: key);

  Color _daysLeftColor(ChecklistGroup group) {
    if (group.isAllCompleted) return Colors.green;
    if (group.daysLeft < 0) return Colors.red;
    if (group.daysLeft <= 3) return Colors.orange;
    return Colors.blue;
  }

  String _daysLeftText(ChecklistGroup group) {
    if (group.isAllCompleted) return 'Completed';
    if (group.daysLeft < 0) return '${-group.daysLeft} days overdue';
    if (group.daysLeft == 0) return 'Due today';
    if (group.daysLeft == 1) return '1 day left';
    return '${group.daysLeft} days left';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChecklistCubit, ChecklistState>(
      builder: (context, state) {
        final cubit = context.read<ChecklistCubit>();
        final group = cubit.getChecklistById(groupId);

        if (group == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Checklist not found')),
          );
        }

        final color = _daysLeftColor(group);
        final uncompleted =
            group.items.where((i) => !i.isCompleted).toList();
        final completed =
            group.items.where((i) => i.isCompleted).toList();

        return Scaffold(
          appBar: AppBar(
            title: Text(group.name),
            centerTitle: true,
            elevation: 0,
          ),
          body: Column(
            children: [
              // Header card
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.15),
                      color.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _daysLeftText(group),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Target: ${DateFormat('MMM d, yyyy').format(group.targetDate)}',
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color.withValues(alpha: 0.15),
                          ),
                          child: Center(
                            child: Text(
                              '${(group.progress * 100).toInt()}%',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: group.progress,
                        minHeight: 8,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${group.completedItems} of ${group.totalItems} completed',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              if (group.description != null &&
                  group.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      group.description!,
                      style:
                          TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ),
                ),

              // Items list
              Expanded(
                child: group.items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_task_rounded,
                                size: 48, color: Colors.grey[300]),
                            const SizedBox(height: 12),
                            Text(
                              'No items yet',
                              style: TextStyle(
                                  fontSize: 16, color: Colors.grey[500]),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap + to add items',
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey[400]),
                            ),
                          ],
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        children: [
                          // Pending items
                          if (uncompleted.isNotEmpty) ...[
                            Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 8, top: 4),
                              child: Text(
                                'To Do (${uncompleted.length})',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[500],
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            ...uncompleted.map((item) => _ChecklistItemTile(
                                  item: item,
                                  onToggle: () =>
                                      cubit.toggleItem(groupId, item.id),
                                  onDelete: () =>
                                      cubit.deleteItem(groupId, item.id),
                                )),
                          ],

                          // Completed items
                          if (completed.isNotEmpty) ...[
                            Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 8, top: 16),
                              child: Text(
                                'Completed (${completed.length})',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[500],
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            ...completed.map((item) => _ChecklistItemTile(
                                  item: item,
                                  onToggle: () =>
                                      cubit.toggleItem(groupId, item.id),
                                  onDelete: () =>
                                      cubit.deleteItem(groupId, item.id),
                                )),
                          ],
                        ],
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              final title = await _showAddItemDialog(context);
              if (title != null && title.isNotEmpty) {
                cubit.addItem(
                  groupId,
                  ChecklistItem(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: title,
                  ),
                );
              }
            },
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Future<String?> _showAddItemDialog(BuildContext context) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Item'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Item title',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) => Navigator.pop(ctx, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

// ─── Checklist Item Tile ─────────────────────────────────────────────────────

class _ChecklistItemTile extends StatelessWidget {
  final ChecklistItem item;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _ChecklistItemTile({
    required this.item,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: item.isCompleted ? 0 : 1,
      color: item.isCompleted ? Colors.grey[50] : Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: Checkbox(
          value: item.isCompleted,
          onChanged: (_) => onToggle(),
          activeColor: Colors.green,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        title: Text(
          item.title,
          style: TextStyle(
            fontSize: 15,
            decoration:
                item.isCompleted ? TextDecoration.lineThrough : null,
            color: item.isCompleted ? Colors.grey[400] : Colors.grey[800],
          ),
        ),
        subtitle: item.isCompleted && item.completedDate != null
            ? Text(
                'Done ${DateFormat('MMM d, yyyy').format(item.completedDate!)}',
                style: TextStyle(fontSize: 11, color: Colors.grey[400]),
              )
            : null,
        trailing: IconButton(
          icon: Icon(Icons.close_rounded,
              size: 18, color: Colors.grey[400]),
          onPressed: onDelete,
        ),
      ),
    );
  }
}

// ─── Add / Edit Checklist Group Page ─────────────────────────────────────────

class AddChecklistGroupPage extends StatefulWidget {
  final ChecklistGroup? group;
  const AddChecklistGroupPage({Key? key, this.group}) : super(key: key);

  @override
  State<AddChecklistGroupPage> createState() => _AddChecklistGroupPageState();
}

class _AddChecklistGroupPageState extends State<AddChecklistGroupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _targetDate = DateTime.now().add(const Duration(days: 7));

  bool get _isEditing => widget.group != null;

  @override
  void initState() {
    super.initState();
    if (widget.group != null) {
      _nameController.text = widget.group!.name;
      _descriptionController.text = widget.group!.description ?? '';
      _targetDate = widget.group!.targetDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final group = ChecklistGroup(
        id: widget.group?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        targetDate: _targetDate,
        createdDate: widget.group?.createdDate ?? DateTime.now(),
        items: widget.group?.items ?? [],
      );
      Navigator.pop(context, group);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Checklist' : 'New Checklist'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.checklist_rounded),
              ),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Please enter a name' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notes_rounded),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey[400]!),
              ),
              leading: const Icon(Icons.calendar_today_rounded),
              title: const Text('Target Date'),
              subtitle: Text(
                DateFormat('EEEE, MMM d, yyyy').format(_targetDate),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _targetDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2035),
                );
                if (date != null) {
                  setState(() => _targetDate = date);
                }
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _save,
              icon: Icon(_isEditing ? Icons.save_rounded : Icons.add_rounded),
              label: Text(_isEditing ? 'Update Checklist' : 'Create Checklist'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
