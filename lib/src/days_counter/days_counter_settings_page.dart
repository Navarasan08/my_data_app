import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:my_data_app/src/days_counter/cubit/days_counter_cubit.dart';
import 'package:my_data_app/src/days_counter/cubit/days_counter_state.dart';
import 'package:my_data_app/src/days_counter/model/days_counter_model.dart';

class DaysCounterSettingsPage extends StatelessWidget {
  const DaysCounterSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return BlocBuilder<DaysCounterCubit, DaysCounterState>(
      builder: (context, state) {
        final cubit = context.read<DaysCounterCubit>();
        final types = state.eventTypes;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Event Types'),
            centerTitle: true,
            elevation: 0,
          ),
          body: ListView(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Row(
                  children: [
                    Text(
                      'Event Types',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => _openDialog(context, cubit, null),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add'),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "Tag events as Birthday, Death Anniversary, Festival, etc. Events keep their tag even if the type is later removed here.",
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ),
              const SizedBox(height: 8),
              if (types.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      'No event types yet',
                      style:
                          TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
                    ),
                  ),
                )
              else
                ...types.map((t) {
                  final inUse = cubit.isEventTypeInUse(t.id);
                  return Card(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: t.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(t.icon, color: t.color, size: 22),
                      ),
                      title: Text(
                        t.displayName,
                        style:
                            const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: inUse
                          ? const Text(
                              'In use',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.green),
                            )
                          : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit_outlined,
                                color: Colors.blue[400]),
                            onPressed: () => _openDialog(context, cubit, t),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline,
                                color: Colors.red[400]),
                            onPressed: () =>
                                _confirmDelete(context, cubit, t, inUse),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  void _openDialog(BuildContext context, DaysCounterCubit cubit,
      DaysCounterEventType? existing) {
    showDialog(
      context: context,
      builder: (ctx) => _EventTypeDialog(
        existing: existing,
        onSave: (t) {
          if (existing != null) {
            cubit.updateEventType(t);
          } else {
            cubit.addEventType(t);
          }
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, DaysCounterCubit cubit,
      DaysCounterEventType t, bool inUse) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Event Type'),
        content: Text(
          inUse
              ? '"${t.displayName}" is used by some events. They will keep showing this label, but it won\'t appear in the picker. Delete?'
              : 'Are you sure you want to delete "${t.displayName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              cubit.deleteEventType(t.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _EventTypeDialog extends StatefulWidget {
  final DaysCounterEventType? existing;
  final ValueChanged<DaysCounterEventType> onSave;
  const _EventTypeDialog({this.existing, required this.onSave});

  @override
  State<_EventTypeDialog> createState() => _EventTypeDialogState();
}

class _EventTypeDialogState extends State<_EventTypeDialog> {
  final _nameController = TextEditingController();
  int _iconIndex = 0;
  int _colorIndex = 0;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _nameController.text = widget.existing!.displayName;
      _iconIndex = widget.existing!.iconIndex;
      _colorIndex = widget.existing!.colorIndex;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final previewIcon = DaysCounterEventType.availableIcons[_iconIndex];
    final previewColor = DaysCounterEventType.availableColors[_colorIndex];

    return AlertDialog(
      title: Text(_isEditing ? 'Edit Event Type' : 'Add Event Type'),
      content: SizedBox(
        width: 350,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: previewColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: previewColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(previewIcon, color: previewColor, size: 24),
                      const SizedBox(width: 10),
                      Text(
                        _nameController.text.isEmpty
                            ? 'Preview'
                            : _nameController.text,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: previewColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'e.g. Graduation Day',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label_rounded),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),
              Text('Icon',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface)),
              const SizedBox(height: 6),
              SizedBox(
                height: 110,
                child: GridView.builder(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                  ),
                  itemCount: DaysCounterEventType.availableIcons.length,
                  itemBuilder: (_, i) {
                    final selected = _iconIndex == i;
                    return InkWell(
                      onTap: () => setState(() => _iconIndex = i),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: selected
                              ? previewColor.withValues(alpha: 0.15)
                              : cs.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(8),
                          border: selected
                              ? Border.all(color: previewColor, width: 2)
                              : null,
                        ),
                        child: Icon(
                          DaysCounterEventType.availableIcons[i],
                          size: 20,
                          color: selected
                              ? previewColor
                              : cs.onSurfaceVariant,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              Text('Color',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(
                    DaysCounterEventType.availableColors.length, (i) {
                  final c = DaysCounterEventType.availableColors[i];
                  final selected = _colorIndex == i;
                  return InkWell(
                    onTap: () => setState(() => _colorIndex = i),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: selected
                            ? Border.all(color: cs.onSurface, width: 3)
                            : Border.all(
                                color: cs.outline, width: 1),
                      ),
                      child: selected
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 16)
                          : null,
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _nameController.text.trim().isEmpty
              ? null
              : () {
                  final name = _nameController.text.trim();
                  final id = widget.existing?.id ??
                      'dct_${DateTime.now().millisecondsSinceEpoch}';
                  widget.onSave(DaysCounterEventType(
                    id: id,
                    displayName: name,
                    iconIndex: _iconIndex,
                    colorIndex: _colorIndex,
                  ));
                  Navigator.pop(context);
                },
          child: Text(_isEditing ? 'Update' : 'Add'),
        ),
      ],
    );
  }
}
