import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_data_app/src/checklist/model/checklist_model.dart';

/// Create or edit a checklist: name, optional description and a target
/// date with quick-pick chips.
class AddChecklistGroupPage extends StatefulWidget {
  final ChecklistGroup? group;
  const AddChecklistGroupPage({super.key, this.group});

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
    final g = widget.group;
    if (g != null) {
      _nameController.text = g.name;
      _descriptionController.text = g.description ?? '';
      _targetDate = g.targetDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final group = ChecklistGroup(
      id: widget.group?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      targetDate: _targetDate,
      createdDate: widget.group?.createdDate ?? DateTime.now(),
      items: widget.group?.items ?? [],
    );
    Navigator.pop(context, group);
  }

  void _setDaysFromNow(int days) {
    setState(() => _targetDate = DateTime.now().add(Duration(days: days)));
  }

  bool _isDaysFromNow(int days) {
    final d = DateTime.now().add(Duration(days: days));
    return _targetDate.year == d.year &&
        _targetDate.month == d.month &&
        _targetDate.day == d.day;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Checklist' : 'New Checklist'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            TextFormField(
              controller: _nameController,
              autofocus: !_isEditing,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Name *',
                prefixIcon: const Icon(Icons.checklist_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Please enter a name'
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _descriptionController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Description (optional)',
                prefixIcon: const Icon(Icons.notes_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            Text(
              'TARGET DATE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Today'),
                  selected: _isDaysFromNow(0),
                  onSelected: (_) => _setDaysFromNow(0),
                ),
                ChoiceChip(
                  label: const Text('Tomorrow'),
                  selected: _isDaysFromNow(1),
                  onSelected: (_) => _setDaysFromNow(1),
                ),
                ChoiceChip(
                  label: const Text('1 week'),
                  selected: _isDaysFromNow(7),
                  onSelected: (_) => _setDaysFromNow(7),
                ),
                ChoiceChip(
                  label: const Text('1 month'),
                  selected: _isDaysFromNow(30),
                  onSelected: (_) => _setDaysFromNow(30),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: cs.outlineVariant),
              ),
              leading: const Icon(Icons.calendar_today_rounded),
              title: Text(
                DateFormat('EEEE, d MMM yyyy').format(_targetDate),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              trailing: const Icon(Icons.edit_calendar_rounded, size: 20),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _targetDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2035),
                );
                if (date != null) setState(() => _targetDate = date);
              },
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _save,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: Icon(_isEditing ? Icons.save_rounded : Icons.add_rounded),
              label: Text(
                _isEditing ? 'Update Checklist' : 'Create Checklist',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
