import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:my_data_app/src/home/home_record_model.dart';
import 'package:my_data_app/src/home/cubit/home_record_cubit.dart';
import 'package:my_data_app/src/home/cubit/home_record_state.dart';
import 'package:my_data_app/src/home/home_record_analysis_page.dart';
import 'package:my_data_app/src/home/home_record_settings_page.dart';

class HomeRecordPage extends StatelessWidget {
  const HomeRecordPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeRecordCubit, HomeRecordState>(
      builder: (context, state) {
        final cubit = context.read<HomeRecordCubit>();
        final filteredRecords = cubit.filteredRecords;
        final displayTotal = cubit.displayTotal;


        return Scaffold(
          appBar: AppBar(
            title: const Text('Home Records'),
            centerTitle: true,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.bar_chart_rounded),
                tooltip: 'Analysis',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: cubit,
                      child: const HomeRecordAnalysisPage(),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings_rounded),
                tooltip: 'Category Settings',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: cubit,
                      child: const HomeRecordSettingsPage(),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final isWide = width > 600;
              final isExtraWide = width > 900;
              final contentMaxWidth = isExtraWide ? 900.0 : double.infinity;
              final gridCols = isExtraWide ? 3 : isWide ? 2 : 1;

              return Column(
                children: [
                  // Month nav + total in one row
                  Center(
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(maxWidth: contentMaxWidth),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                  Icons.chevron_left_rounded),
                              onPressed: () =>
                                  cubit.changeMonth(-1),
                              visualDensity: VisualDensity.compact,
                            ),
                            Expanded(
                              child: Text(
                                DateFormat('MMM yyyy')
                                    .format(state.selectedDate),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                  Icons.chevron_right_rounded),
                              onPressed: () =>
                                  cubit.changeMonth(1),
                              visualDensity: VisualDensity.compact,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${cubit.currencySymbol}${displayTotal.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '(${filteredRecords.length})',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Category Filter Chips
                  Center(
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(maxWidth: contentMaxWidth),
                      child: SizedBox(
                        height: 38,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 12),
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label: const Text('All',
                                    style: TextStyle(fontSize: 12)),
                                selected:
                                    state.selectedCategory == null,
                                onSelected: (_) =>
                                    cubit.setCategory(null),
                                selectedColor: Colors.green[100],
                                showCheckmark: false,
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4),
                              ),
                            ),
                            ...cubit.allCategories.map((cat) {
                              final isSelected =
                                  state.selectedCategory == cat;
                              return Padding(
                                padding:
                                    const EdgeInsets.only(right: 6),
                                child: ChoiceChip(
                                  avatar: Icon(cat.icon,
                                      size: 14, color: cat.color),
                                  label: Text(cat.displayName,
                                      style: const TextStyle(
                                          fontSize: 12)),
                                  selected: isSelected,
                                  onSelected: (_) =>
                                      cubit.setCategory(
                                    isSelected ? null : cat,
                                  ),
                                  selectedColor: cat.color
                                      .withValues(alpha: 0.2),
                                  showCheckmark: false,
                                  visualDensity: VisualDensity.compact,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Records List / Grid
                  Expanded(
                    child: filteredRecords.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Icon(Icons.home_outlined,
                                    size: 48,
                                    color: Colors.grey[300]),
                                const SizedBox(height: 12),
                                Text(
                                  state.selectedCategory != null
                                      ? 'No ${state.selectedCategory!.displayName} records this month'
                                      : 'No records for this month',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                  maxWidth: contentMaxWidth),
                              child: gridCols > 1
                                  ? GridView.builder(
                                      padding:
                                          const EdgeInsets.fromLTRB(
                                              12, 4, 12, 12),
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: gridCols,
                                        crossAxisSpacing: 10,
                                        mainAxisSpacing: 10,
                                        childAspectRatio:
                                            isExtraWide ? 2.5 : 2.2,
                                      ),
                                      itemCount:
                                          filteredRecords.length,
                                      itemBuilder: (context, index) {
                                        return _buildRecordItem(
                                            context,
                                            cubit,
                                            filteredRecords[index]);
                                      },
                                    )
                                  : ListView.builder(
                                      padding:
                                          const EdgeInsets.fromLTRB(
                                              12, 4, 12, 12),
                                      itemCount:
                                          filteredRecords.length,
                                      itemBuilder: (context, index) {
                                        return _buildRecordItem(
                                            context,
                                            cubit,
                                            filteredRecords[index]);
                                      },
                                    ),
                            ),
                          ),
                  ),
                ],
              );
            },
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              final newRecord = await Navigator.push<HomeRecord>(
                context,
                MaterialPageRoute(
                    builder: (_) => AddHomeRecordPage(
                        categories: cubit.allCategories)),
              );
              if (newRecord != null) {
                cubit.addRecord(newRecord);
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Record'),
          ),
        );
      },
    );
  }

  Widget _buildRecordItem(
      BuildContext context, HomeRecordCubit cubit, HomeRecord record) {
    return _RecordCard(
      record: record,
      onEdit: () async {
        final edited = await Navigator.push<HomeRecord>(
          context,
          MaterialPageRoute(
            builder: (_) => AddHomeRecordPage(
                record: record, categories: cubit.allCategories),
          ),
        );
        if (edited != null) {
          cubit.updateRecord(edited);
        }
      },
      onDelete: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Record'),
            content: Text(
                'Are you sure you want to delete "${record.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style:
                    TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          cubit.deleteRecord(record.id);
        }
      },
    );
  }
}

class _RecordCard extends StatelessWidget {
  final HomeRecord record;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RecordCard({
    Key? key,
    required this.record,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: record.category.color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(
            color: record.category.color,
            width: 3,
          ),
        ),
      ),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              Icon(record.category.icon,
                  size: 20, color: record.category.color),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${record.category.displayName}  ·  ${DateFormat('d MMM').format(record.date)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${context.read<HomeRecordCubit>().currencySymbol}${record.amount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: onDelete,
                borderRadius: BorderRadius.circular(12),
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

class AddHomeRecordPage extends StatefulWidget {
  final HomeRecord? record;
  final List<HomeCategory> categories;

  const AddHomeRecordPage({
    Key? key,
    this.record,
    required this.categories,
  }) : super(key: key);

  @override
  State<AddHomeRecordPage> createState() => _AddHomeRecordPageState();
}

class _AddHomeRecordPageState extends State<AddHomeRecordPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();

  HomeCategory _selectedCategory = HomeCategory.groceries;
  DateTime _selectedDate = DateTime.now();

  bool get _isEditing => widget.record != null;

  @override
  void initState() {
    super.initState();
    if (widget.record != null) {
      _titleController.text = widget.record!.title;
      _amountController.text = widget.record!.amount.toString();
      _descriptionController.text = widget.record!.description ?? '';
      _notesController.text = widget.record!.notes ?? '';
      _selectedCategory = widget.record!.category;
      _selectedDate = widget.record!.date;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _saveRecord() {
    if (_formKey.currentState!.validate()) {
      final record = HomeRecord(
        id: widget.record?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text,
        category: _selectedCategory,
        amount: double.parse(_amountController.text),
        date: _selectedDate,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        notes:
            _notesController.text.isEmpty ? null : _notesController.text,
      );
      Navigator.pop(context, record);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Record' : 'Add Record'),
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
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Category Dropdown
                DropdownButtonFormField<HomeCategory>(
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: widget.categories.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Row(
                        children: [
                          Icon(cat.icon, size: 20, color: cat.color),
                          const SizedBox(width: 8),
                          Text(cat.displayName),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedCategory = value);
                    }
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an amount';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Date Picker
                ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                    side: BorderSide(color: Colors.grey[600]!),
                  ),
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Date'),
                  subtitle: Text(
                    DateFormat('EEEE, MMM d, yyyy')
                        .format(_selectedDate),
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) {
                      setState(() => _selectedDate = date);
                    }
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.note),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: _saveRecord,
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    _isEditing ? 'Update Record' : 'Save Record',
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
