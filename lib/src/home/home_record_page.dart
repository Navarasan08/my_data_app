import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:my_data_app/src/home/home_record_model.dart';
import 'package:my_data_app/src/home/cubit/home_record_cubit.dart';
import 'package:my_data_app/src/home/cubit/home_record_state.dart';
import 'package:my_data_app/src/home/home_record_analysis_page.dart';

class HomeRecordPage extends StatelessWidget {
  const HomeRecordPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeRecordCubit, HomeRecordState>(
      builder: (context, state) {
        final cubit = context.read<HomeRecordCubit>();
        final monthYear = DateFormat('MMMM yyyy').format(state.selectedDate);
        final filteredRecords = cubit.filteredRecords;
        final monthlyTotal = cubit.monthlyTotal;
        final categoryTotals = cubit.categoryTotals;

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
                  // Month Selector
                  Center(
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(maxWidth: contentMaxWidth),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        color: Colors.white,
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left),
                              onPressed: () => cubit.changeMonth(-1),
                            ),
                            Text(
                              monthYear,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: () => cubit.changeMonth(1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Divider(height: 1),

                  // Monthly Total Summary
                  Center(
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(maxWidth: contentMaxWidth),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        color: Colors.white,
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius:
                                      BorderRadius.circular(8),
                                  border: Border.all(
                                      color: Colors.green[200]!),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.home_rounded,
                                            color: Colors.green[700],
                                            size: 18),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Monthly Total',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.green[900],
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '\$${monthlyTotal.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green[900],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(8),
                                border:
                                    Border.all(color: Colors.blue[200]!),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    '${filteredRecords.length}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[900],
                                    ),
                                  ),
                                  Text(
                                    'records',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.blue[700],
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
                  const Divider(height: 1),

                  // Category Filter Chips
                  Center(
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(maxWidth: contentMaxWidth),
                      child: Container(
                        color: Colors.white,
                        height: 50,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 12),
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 8),
                              child: FilterChip(
                                label: const Text('All'),
                                selected:
                                    state.selectedCategory == null,
                                onSelected: (_) =>
                                    cubit.setCategory(null),
                                selectedColor: Colors.green[100],
                              ),
                            ),
                            ...HomeCategory.values.map((cat) {
                              final catTotal = categoryTotals[cat];
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 8),
                                child: FilterChip(
                                  avatar: Icon(cat.icon,
                                      size: 16, color: cat.color),
                                  label: Text(cat.displayName),
                                  selected:
                                      state.selectedCategory == cat,
                                  onSelected: (_) =>
                                      cubit.setCategory(
                                    state.selectedCategory == cat
                                        ? null
                                        : cat,
                                  ),
                                  selectedColor: cat.color
                                      .withValues(alpha: 0.15),
                                  tooltip: catTotal != null
                                      ? '\$${catTotal.toStringAsFixed(0)}'
                                      : null,
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Divider(height: 1),

                  // Records List / Grid
                  Expanded(
                    child: filteredRecords.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Icon(Icons.home_outlined,
                                    size: 64,
                                    color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  state.selectedCategory != null
                                      ? 'No ${state.selectedCategory!.displayName} records this month'
                                      : 'No home records for this month',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap + to add a record',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[400],
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
                                          const EdgeInsets.all(16),
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: gridCols,
                                        crossAxisSpacing: 12,
                                        mainAxisSpacing: 12,
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
                                          const EdgeInsets.all(16),
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
                    builder: (_) => const AddHomeRecordPage()),
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
            builder: (_) => AddHomeRecordPage(record: record),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: record.category.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                record.category.icon,
                color: record.category.color,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: record.category.color
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          record.category.displayName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: record.category.color,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('MMM d, yyyy').format(record.date),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  if (record.description != null &&
                      record.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      record.description!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${record.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: onEdit,
                      child: Icon(Icons.edit_outlined,
                          size: 20, color: Colors.blue[400]),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: onDelete,
                      child: Icon(Icons.delete_outline,
                          size: 20, color: Colors.red[400]),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AddHomeRecordPage extends StatefulWidget {
  final HomeRecord? record;

  const AddHomeRecordPage({Key? key, this.record}) : super(key: key);

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
                  items: HomeCategory.values.map((cat) {
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
