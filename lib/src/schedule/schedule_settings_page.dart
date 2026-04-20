import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_data_app/src/schedule/model/schedule_model.dart';
import 'package:my_data_app/src/schedule/cubit/schedule_cubit.dart';
import 'package:my_data_app/src/schedule/cubit/schedule_state.dart';

class ScheduleSettingsPage extends StatelessWidget {
  const ScheduleSettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScheduleCubit, ScheduleState>(
      builder: (context, state) {
        final cubit = context.read<ScheduleCubit>();
        final customCategories = state.customCategories;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Schedule Categories'),
            centerTitle: true,
            elevation: 0,
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: ListView(
                children: [
                  // Default categories
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'Default Categories',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 50,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: ScheduleCategory.defaults.map((cat) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 8),
                          child: Chip(
                            avatar: Icon(cat.icon,
                                size: 16, color: cat.color),
                            label: Text(cat.displayName,
                                style: const TextStyle(fontSize: 12)),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const Divider(),

                  // Custom categories
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Row(
                      children: [
                        Text(
                          'Custom Categories',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () =>
                              _showCategoryDialog(context, cubit, null),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add'),
                        ),
                      ],
                    ),
                  ),

                  if (customCategories.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          'No custom categories yet',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ),
                    )
                  else
                    ...customCategories.map((cat) {
                      final inUse = cubit.isCategoryInUse(cat.id);
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: cat.color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(cat.icon,
                                color: cat.color, size: 24),
                          ),
                          title: Text(
                            cat.displayName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600),
                          ),
                          subtitle: inUse
                              ? const Text('In use',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.green))
                              : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit_outlined,
                                    color: Colors.blue[400]),
                                onPressed: () =>
                                    _showCategoryDialog(context, cubit, cat),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete_outline,
                                    color: Colors.red[400]),
                                onPressed: () => _confirmDelete(
                                    context, cubit, cat, inUse),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showCategoryDialog(BuildContext context, ScheduleCubit cubit,
      ScheduleCategory? existing) {
    showDialog(
      context: context,
      builder: (ctx) => _CategoryDialog(
        existing: existing,
        onSave: (category) {
          if (existing != null) {
            cubit.updateCustomCategory(category);
          } else {
            cubit.addCustomCategory(category);
          }
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, ScheduleCubit cubit,
      ScheduleCategory category, bool inUse) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text(
          inUse
              ? '"${category.displayName}" is used by some schedules. Those schedules will be moved to "Other". Delete anyway?'
              : 'Are you sure you want to delete "${category.displayName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              cubit.deleteCustomCategory(category.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _CategoryDialog extends StatefulWidget {
  final ScheduleCategory? existing;
  final ValueChanged<ScheduleCategory> onSave;

  const _CategoryDialog({
    this.existing,
    required this.onSave,
  });

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  final _nameController = TextEditingController();
  int _selectedIconIndex = 5;
  int _selectedColorIndex = 0;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _nameController.text = widget.existing!.displayName;
      _selectedIconIndex = widget.existing!.iconIndex;
      _selectedColorIndex = widget.existing!.colorIndex;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final previewIcon =
        ScheduleCategory.availableIcons[_selectedIconIndex];
    final previewColor =
        ScheduleCategory.availableColors[_selectedColorIndex];

    return AlertDialog(
      title: Text(_isEditing ? 'Edit Category' : 'Add Category'),
      content: SizedBox(
        width: 350,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Preview
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: previewColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: previewColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(previewIcon, color: previewColor, size: 28),
                      const SizedBox(width: 10),
                      Text(
                        _nameController.text.isEmpty
                            ? 'Preview'
                            : _nameController.text,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: previewColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Category Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),

              Text('Icon',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700])),
              const SizedBox(height: 8),
              SizedBox(
                height: 140,
                child: GridView.builder(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                  ),
                  itemCount: ScheduleCategory.availableIcons.length,
                  itemBuilder: (context, index) {
                    final isSelected = _selectedIconIndex == index;
                    return InkWell(
                      onTap: () =>
                          setState(() => _selectedIconIndex = index),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? previewColor.withValues(alpha: 0.15)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: isSelected
                              ? Border.all(color: previewColor, width: 2)
                              : null,
                        ),
                        child: Icon(
                          ScheduleCategory.availableIcons[index],
                          size: 20,
                          color: isSelected
                              ? previewColor
                              : Colors.grey[600],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              Text('Color',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700])),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(
                    ScheduleCategory.availableColors.length, (index) {
                  final color = ScheduleCategory.availableColors[index];
                  final isSelected = _selectedColorIndex == index;
                  return InkWell(
                    onTap: () =>
                        setState(() => _selectedColorIndex = index),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.black, width: 3)
                            : Border.all(
                                color: Colors.grey[300]!, width: 1),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 18)
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
                      'custom_${DateTime.now().millisecondsSinceEpoch}';
                  final category = ScheduleCategory(
                    id: id,
                    displayName: name,
                    iconIndex: _selectedIconIndex,
                    colorIndex: _selectedColorIndex,
                    isCustom: true,
                  );
                  widget.onSave(category);
                  Navigator.pop(context);
                },
          child: Text(_isEditing ? 'Update' : 'Add'),
        ),
      ],
    );
  }
}
