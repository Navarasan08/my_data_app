import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_data_app/src/home/home_record_model.dart';
import 'package:my_data_app/src/home/cubit/home_record_cubit.dart';
import 'package:my_data_app/src/home/cubit/home_record_state.dart';

class HomeRecordSettingsPage extends StatelessWidget {
  const HomeRecordSettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeRecordCubit, HomeRecordState>(
      builder: (context, state) {
        final cubit = context.read<HomeRecordCubit>();
        final customCategories = state.customCategories;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Settings'),
            centerTitle: true,
            elevation: 0,
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: ListView(
                children: [
                  // Currency selection
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'Currency',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  ...HomeCurrency.all.map((c) {
                    final isSelected = state.currency == c;
                    return ListTile(
                      dense: true,
                      leading: Text(c.symbol,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.green[700]
                                : Colors.grey[600],
                          )),
                      title: Text(c.name),
                      subtitle: Text(c.code,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[500])),
                      trailing: isSelected
                          ? Icon(Icons.check_circle_rounded,
                              color: Colors.green[600], size: 20)
                          : null,
                      selected: isSelected,
                      selectedTileColor:
                          Colors.green.withValues(alpha: 0.05),
                      onTap: () => cubit.setCurrency(c),
                    );
                  }),
                  const Divider(),

                  // Default categories section
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
                      children: HomeCategory.defaults.map((cat) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 8),
                          child: Chip(
                            avatar: Icon(cat.icon, size: 16, color: cat.color),
                            label: Text(cat.displayName,
                                style: const TextStyle(fontSize: 12)),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const Divider(),

                  // Custom categories section
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
                              color: cat.color
                                  .withValues(alpha: 0.1),
                              borderRadius:
                                  BorderRadius.circular(10),
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
                                      fontSize: 12,
                                      color: Colors.green))
                              : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit_outlined,
                                    color: Colors.blue[400]),
                                onPressed: () =>
                                    _showCategoryDialog(
                                        context, cubit, cat),
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

  void _showCategoryDialog(
      BuildContext context, HomeRecordCubit cubit, HomeCategory? existing) {
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

  void _confirmDelete(BuildContext context, HomeRecordCubit cubit,
      HomeCategory category, bool inUse) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text(
          inUse
              ? '"${category.displayName}" is used by some records. Records will show a fallback category. Delete anyway?'
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
  final HomeCategory? existing;
  final ValueChanged<HomeCategory> onSave;

  const _CategoryDialog({
    Key? key,
    this.existing,
    required this.onSave,
  }) : super(key: key);

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  final _nameController = TextEditingController();
  int _selectedIconIndex = 10;
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
        HomeCategory.availableIcons[_selectedIconIndex];
    final previewColor =
        HomeCategory.availableColors[_selectedColorIndex];

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

              // Name field
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

              // Icon selector
              Text('Icon',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  )),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: GridView.builder(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                  ),
                  itemCount: HomeCategory.availableIcons.length,
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
                          HomeCategory.availableIcons[index],
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

              // Color selector
              Text('Color',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  )),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(
                    HomeCategory.availableColors.length, (index) {
                  final color = HomeCategory.availableColors[index];
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
                  final category = HomeCategory(
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
