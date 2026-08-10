import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_data_app/src/home/home_record_model.dart';
import 'package:my_data_app/src/home/cubit/home_record_cubit.dart';
import 'package:my_data_app/src/home/cubit/home_record_state.dart';

class HomeCategoriesPage extends StatelessWidget {
  const HomeCategoriesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeRecordCubit, HomeRecordState>(
      builder: (context, state) {
        final cs = Theme.of(context).colorScheme;
        final cubit = context.read<HomeRecordCubit>();
        final customCategories = state.customCategories;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Categories'),
            centerTitle: true,
            elevation: 0,
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showCategoryDialog(context, cubit, null),
            icon: const Icon(Icons.add),
            label: const Text('Add Category'),
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: ListView(
                padding: const EdgeInsets.only(bottom: 96),
                children: [
                  // Default categories section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'Default Expense Categories',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
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

                  // Default income categories section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Text(
                      'Default Income Categories',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 50,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: HomeCategory.incomeDefaults.map((cat) {
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
                    child: Text(
                      'Custom Categories',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
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
                            color: cs.onSurfaceVariant,
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
                            child: Icon(cat.icon, color: cat.color, size: 24),
                          ),
                          title: Text(
                            cat.displayName,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            [
                              cat.isIncome ? 'Income' : 'Expense',
                              if (inUse) 'In use',
                            ].join('  ·  '),
                            style: TextStyle(
                              fontSize: 12,
                              color: inUse
                                  ? Colors.green
                                  : cs.onSurfaceVariant,
                            ),
                          ),
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
                                onPressed: () =>
                                    _confirmDelete(context, cubit, cat, inUse),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
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
  bool _isIncome = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _nameController.text = widget.existing!.displayName;
      _selectedIconIndex = widget.existing!.iconIndex;
      _selectedColorIndex = widget.existing!.colorIndex;
      _isIncome = widget.existing!.isIncome;
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
    final previewIcon = HomeCategory.availableIcons[_selectedIconIndex];
    final previewColor = HomeCategory.availableColors[_selectedColorIndex];

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

              // Expense / Income kind. Locked when editing so existing
              // records that reference this category keep a matching kind.
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Expense')),
                  ButtonSegment(value: true, label: Text('Income')),
                ],
                selected: {_isIncome},
                onSelectionChanged: _isEditing
                    ? null
                    : (sel) => setState(() => _isIncome = sel.first),
              ),
              const SizedBox(height: 16),

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
                    color: cs.onSurface,
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
                              : cs.surfaceContainerLow,
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
                              : cs.onSurfaceVariant,
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
                    color: cs.onSurface,
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
                            : Border.all(color: cs.outline, width: 1),
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
                    isIncome: _isIncome,
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
