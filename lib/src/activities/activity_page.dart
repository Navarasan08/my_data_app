import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:my_data_app/src/activities/cubit/activity_cubit.dart';
import 'package:my_data_app/src/activities/cubit/activity_state.dart';
import 'package:my_data_app/src/activities/model/activity_model.dart';

class ActivityPage extends StatelessWidget {
  const ActivityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ActivityCubit, ActivityState>(
      builder: (context, state) {
        final cubit = context.read<ActivityCubit>();
        final records = cubit.filtered;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Activity Log'),
            centerTitle: true,
            elevation: 0,
          ),
          body: Column(
            children: [
              // Category filter chips
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: const Text('All', style: TextStyle(fontSize: 12)),
                        selected: state.selectedCategories.isEmpty,
                        onSelected: (_) => cubit.clearCategoryFilter(),
                        showCheckmark: false,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    ...ActivityCategory.values.map((c) {
                      final selected = state.selectedCategories.contains(c);
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          avatar: Icon(c.icon, size: 14, color: c.color),
                          label: Text(c.label, style: const TextStyle(fontSize: 12)),
                          selected: selected,
                          onSelected: (_) => cubit.toggleCategory(c),
                          selectedColor: c.color.withValues(alpha: 0.2),
                          showCheckmark: false,
                          visualDensity: VisualDensity.compact,
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const Divider(height: 1),

              Expanded(
                child: records.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history_rounded, size: 56, color: Colors.grey[300]),
                            const SizedBox(height: 12),
                            Text(
                              state.selectedCategories.isNotEmpty
                                  ? 'No activities for the selected categories'
                                  : 'No activities yet',
                              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap + to log a trip, certificate or milestone',
                              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                            ),
                          ],
                        ),
                      )
                    : _buildYearGroupedList(context, cubit, records),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              final created = await Navigator.push<ActivityRecord>(
                context,
                MaterialPageRoute(builder: (_) => const AddActivityPage()),
              );
              if (created != null) cubit.addRecord(created);
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Activity'),
          ),
        );
      },
    );
  }

  Widget _buildYearGroupedList(
      BuildContext context, ActivityCubit cubit, List<ActivityRecord> records) {
    final grouped = <String, List<ActivityRecord>>{};
    for (final r in records) {
      final key = DateFormat('yyyy').format(r.startDate);
      grouped.putIfAbsent(key, () => []).add(r);
    }
    final keys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
      itemCount: keys.length,
      itemBuilder: (context, idx) {
        final year = keys[idx];
        final list = grouped[year]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(
                    year,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '(${list.length})',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            ...list.map((r) => _ActivityCard(
                  record: r,
                  onEdit: () async {
                    final edited = await Navigator.push<ActivityRecord>(
                      context,
                      MaterialPageRoute(
                          builder: (_) => AddActivityPage(record: r)),
                    );
                    if (edited != null) cubit.updateRecord(edited);
                  },
                  onDelete: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete Activity'),
                        content:
                            Text('Delete "${r.title}"? This cannot be undone.'),
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
                    if (ok == true) cubit.deleteRecord(r.id);
                  },
                )),
          ],
        );
      },
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final ActivityRecord record;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ActivityCard({
    required this.record,
    required this.onEdit,
    required this.onDelete,
  });

  String _dateLabel() {
    final start = DateFormat('d MMM').format(record.startDate);
    if (record.endDate == null || !record.isMultiDay) return start;
    final end = DateFormat('d MMM').format(record.endDate!);
    return '$start — $end (${record.durationDays}d)';
  }

  @override
  Widget build(BuildContext context) {
    final c = record.category;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: c.color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: c.color, width: 3)),
      ),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              Icon(c.icon, size: 22, color: c.color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [
                        c.label,
                        _dateLabel(),
                        if (record.location != null && record.location!.isNotEmpty)
                          record.location!,
                      ].join('  ·  '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: onDelete,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(4),
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

class AddActivityPage extends StatefulWidget {
  final ActivityRecord? record;

  const AddActivityPage({super.key, this.record});

  @override
  State<AddActivityPage> createState() => _AddActivityPageState();
}

class _AddActivityPageState extends State<AddActivityPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();

  ActivityCategory _category = ActivityCategory.trip;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _isRange = false;

  bool get _isEditing => widget.record != null;

  @override
  void initState() {
    super.initState();
    if (widget.record != null) {
      final r = widget.record!;
      _titleCtrl.text = r.title;
      _descriptionCtrl.text = r.description ?? '';
      _locationCtrl.text = r.location ?? '';
      _category = r.category;
      _startDate = r.startDate;
      _endDate = r.endDate;
      _isRange = r.endDate != null;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final now = DateTime.now();
    final record = ActivityRecord(
      id: widget.record?.id ?? now.millisecondsSinceEpoch.toString(),
      title: _titleCtrl.text.trim(),
      category: _category,
      startDate: _startDate,
      endDate: _isRange ? _endDate : null,
      description: _descriptionCtrl.text.trim().isEmpty
          ? null
          : _descriptionCtrl.text.trim(),
      location: _locationCtrl.text.trim().isEmpty
          ? null
          : _locationCtrl.text.trim(),
      createdAt: widget.record?.createdAt ?? now,
      updatedAt: now,
    );
    Navigator.pop(context, record);
  }

  Future<void> _pickStartDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(1970),
      lastDate: DateTime(2100),
    );
    if (d == null) return;
    setState(() {
      _startDate = d;
      if (_endDate != null && _endDate!.isBefore(d)) _endDate = d;
    });
  }

  Future<void> _pickEndDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate,
      firstDate: _startDate,
      lastDate: DateTime(2100),
    );
    if (d == null) return;
    setState(() => _endDate = d);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Activity' : 'Add Activity'),
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
                  controller: _titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Title *',
                    hintText: 'e.g. Trip to Goa, Applied for passport',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title_rounded),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Please enter a title' : null,
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<ActivityCategory>(
                  initialValue: _category,
                  decoration: const InputDecoration(
                    labelText: 'Category *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category_rounded),
                  ),
                  items: ActivityCategory.values
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Row(
                              children: [
                                Icon(c.icon, size: 20, color: c.color),
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
                const SizedBox(height: 16),

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Multi-day activity'),
                  subtitle: Text(
                    _isRange
                        ? 'Pick a start and end date'
                        : 'Single day — pick one date',
                    style: const TextStyle(fontSize: 12),
                  ),
                  value: _isRange,
                  onChanged: (v) {
                    setState(() {
                      _isRange = v;
                      if (!v) {
                        _endDate = null;
                      } else {
                        _endDate ??= _startDate;
                      }
                    });
                  },
                ),

                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                    side: BorderSide(color: Colors.grey[600]!),
                  ),
                  leading: const Icon(Icons.event_rounded),
                  title: Text(_isRange ? 'Start date' : 'Date'),
                  subtitle: Text(DateFormat('EEEE, d MMM yyyy').format(_startDate)),
                  onTap: _pickStartDate,
                ),
                if (_isRange) ...[
                  const SizedBox(height: 10),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                      side: BorderSide(color: Colors.grey[600]!),
                    ),
                    leading: const Icon(Icons.event_available_rounded),
                    title: const Text('End date'),
                    subtitle: Text(_endDate == null
                        ? 'Tap to pick'
                        : DateFormat('EEEE, d MMM yyyy').format(_endDate!)),
                    onTap: _pickEndDate,
                  ),
                ],
                const SizedBox(height: 16),

                TextFormField(
                  controller: _locationCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Location (optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _descriptionCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 28),

                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    _isEditing ? 'Update Activity' : 'Save Activity',
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
