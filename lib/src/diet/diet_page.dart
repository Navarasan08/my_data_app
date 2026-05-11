import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:my_data_app/src/diet/cubit/diet_cubit.dart';
import 'package:my_data_app/src/diet/cubit/diet_state.dart';
import 'package:my_data_app/src/diet/diet_analysis_page.dart';
import 'package:my_data_app/src/diet/model/diet_model.dart';

class DietPage extends StatelessWidget {
  const DietPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DietCubit, DietState>(
      builder: (context, state) {
        final cubit = context.read<DietCubit>();
        final isCurrentMonth = _isSameMonth(state.selectedMonth, DateTime.now());

        return Scaffold(
          appBar: AppBar(
            title: const Text('Diet Tracker'),
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
                      child: const DietAnalysisPage(),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              // Month nav
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded),
                      onPressed: () => cubit.changeMonth(-1),
                      visualDensity: VisualDensity.compact,
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          DateFormat('MMMM yyyy').format(state.selectedMonth),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded),
                      onPressed: () => cubit.changeMonth(1),
                      visualDensity: VisualDensity.compact,
                    ),
                    if (!isCurrentMonth)
                      TextButton(
                        onPressed: cubit.resetToCurrentMonth,
                        child: const Text('Today',
                            style: TextStyle(fontSize: 12)),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),

              Expanded(
                child: state.items.isEmpty
                    ? _EmptyState(
                        onAdd: () => _openAddItem(context, cubit),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 90),
                        itemCount: state.items.length,
                        itemBuilder: (_, i) {
                          final item = state.items[i];
                          return _FoodItemCard(
                            item: item,
                            cubit: cubit,
                            onTap: () => _openItemDetail(context, cubit, item),
                            onLogTap: () =>
                                _openAddEntry(context, cubit, item),
                          );
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'diet_fab',
            onPressed: () => _openAddItem(context, cubit),
            icon: const Icon(Icons.add),
            label: const Text('Add Food'),
          ),
        );
      },
    );
  }

  static bool _isSameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  // ── Bottom sheets / navigation ──────────────────────────────────────────

  Future<void> _openAddItem(BuildContext context, DietCubit cubit,
      {FoodItem? existing}) async {
    final result = await showModalBottomSheet<FoodItem>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _FoodItemForm(existing: existing),
    );
    if (result == null) return;
    if (existing != null) {
      cubit.updateItem(result);
    } else {
      cubit.addItem(result);
    }
  }

  Future<void> _openAddEntry(
      BuildContext context, DietCubit cubit, FoodItem item) async {
    final result = await showModalBottomSheet<FoodEntry>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _FoodEntryForm(item: item),
    );
    if (result != null) cubit.addEntry(result);
  }

  void _openItemDetail(
      BuildContext context, DietCubit cubit, FoodItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: _FoodItemDetailPage(itemId: item.id),
        ),
      ),
    );
  }
}

// ── Food item card ──────────────────────────────────────────────────────────

class _FoodItemCard extends StatelessWidget {
  final FoodItem item;
  final DietCubit cubit;
  final VoidCallback onTap;
  final VoidCallback onLogTap;

  const _FoodItemCard({
    required this.item,
    required this.cubit,
    required this.onTap,
    required this.onLogTap,
  });

  @override
  Widget build(BuildContext context) {
    final consumed = cubit.consumedThisMonth(item.id);
    final remaining = cubit.remainingThisMonth(item);
    final limit = item.monthlyLimit;
    final exceeded = limit != null && consumed > limit;
    final progress =
        limit != null && limit > 0 ? (consumed / limit).clamp(0, 1).toDouble() : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: item.color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: item.color.withValues(alpha: 0.18)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, size: 22, color: item.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (limit != null)
                          _RemainingBadge(
                            remaining: remaining ?? 0,
                            exceeded: exceeded,
                            unitLabel: item.unitLabel,
                          )
                        else
                          Text(
                            item.quantityLabel(consumed),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey[800],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (limit != null)
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: progress),
                        duration: const Duration(milliseconds: 450),
                        curve: Curves.easeOutCubic,
                        builder: (_, t, _) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: t,
                              minHeight: 6,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                exceeded ? Colors.red : item.color,
                              ),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 4),
                    Text(
                      limit != null
                          ? '${item.quantityLabel(consumed)} of ${item.quantityLabel(limit)} this month'
                          : 'No limit set',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: item.color,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: onLogTap,
                  customBorder: const CircleBorder(),
                  child: const SizedBox(
                    width: 36,
                    height: 36,
                    child: Icon(Icons.add, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RemainingBadge extends StatelessWidget {
  final double remaining;
  final bool exceeded;
  final String? unitLabel;
  const _RemainingBadge({
    required this.remaining,
    required this.exceeded,
    required this.unitLabel,
  });

  @override
  Widget build(BuildContext context) {
    final qStr = remaining % 1 == 0
        ? remaining.toInt().toString()
        : remaining.toStringAsFixed(1);
    final label =
        unitLabel == null || unitLabel!.isEmpty ? '' : ' $unitLabel';
    final color = exceeded ? Colors.red : Colors.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        exceeded ? 'Over' : '$qStr$label left',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant_menu_rounded,
              size: 64, color: Colors.grey[300]),
          const SizedBox(height: 12),
          const Text(
            'No food items yet',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'Add a food, drink or habit to start tracking',
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add your first item'),
          ),
        ],
      ),
    );
  }
}

// ── Add / edit food item form ───────────────────────────────────────────────

class _FoodItemForm extends StatefulWidget {
  final FoodItem? existing;
  const _FoodItemForm({this.existing});

  @override
  State<_FoodItemForm> createState() => _FoodItemFormState();
}

class _FoodItemFormState extends State<_FoodItemForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _unitCtrl = TextEditingController();
  final _limitCtrl = TextEditingController();
  int _iconIndex = 0;
  int _colorIndex = 0;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameCtrl.text = e.name;
      _unitCtrl.text = e.unitLabel ?? '';
      _limitCtrl.text =
          e.monthlyLimit == null ? '' : _stripTrailing(e.monthlyLimit!);
      _iconIndex = e.iconIndex;
      _colorIndex = e.colorIndex;
    }
  }

  static String _stripTrailing(double v) =>
      v % 1 == 0 ? v.toInt().toString() : v.toString();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _unitCtrl.dispose();
    _limitCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final now = DateTime.now();
    final limit = double.tryParse(_limitCtrl.text.trim());
    final unit = _unitCtrl.text.trim();
    final item = FoodItem(
      id: widget.existing?.id ?? now.millisecondsSinceEpoch.toString(),
      name: _nameCtrl.text.trim(),
      iconIndex: _iconIndex,
      colorIndex: _colorIndex,
      unitLabel: unit.isEmpty ? null : unit,
      monthlyLimit: limit,
      createdAt: widget.existing?.createdAt ?? now,
      updatedAt: now,
    );
    Navigator.pop(context, item);
  }

  @override
  Widget build(BuildContext context) {
    final previewColor = FoodItem.availableColors[_colorIndex];
    final previewIcon = FoodItem.availableIcons[_iconIndex];

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _isEditing ? 'Edit Food Item' : 'Add Food Item',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Preview
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: previewColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: previewColor.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(previewIcon, color: previewColor, size: 26),
                        const SizedBox(width: 10),
                        Text(
                          _nameCtrl.text.isEmpty
                              ? 'Preview'
                              : _nameCtrl.text,
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
                const SizedBox(height: 16),

                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Name *',
                    hintText: 'e.g. Coffee, Pizza slice, Banana',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.label_rounded),
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Please enter a name'
                      : null,
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _unitCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Unit (optional)',
                          hintText: 'cup, slice, piece',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.straighten_rounded),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _limitCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Monthly limit',
                          hintText: 'e.g. 30',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.flag_rounded),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          final n = double.tryParse(v.trim());
                          if (n == null || n < 0) {
                            return 'Invalid number';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Text(
                  'Icon',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 8,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                  ),
                  itemCount: FoodItem.availableIcons.length,
                  itemBuilder: (_, i) {
                    final selected = _iconIndex == i;
                    return InkWell(
                      onTap: () => setState(() => _iconIndex = i),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: selected
                              ? previewColor.withValues(alpha: 0.15)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: selected
                              ? Border.all(color: previewColor, width: 2)
                              : null,
                        ),
                        child: Icon(
                          FoodItem.availableIcons[i],
                          size: 20,
                          color:
                              selected ? previewColor : Colors.grey[600],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                Text(
                  'Color',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(
                      FoodItem.availableColors.length, (i) {
                    final c = FoodItem.availableColors[i];
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
                              ? Border.all(color: Colors.black, width: 3)
                              : Border.all(
                                  color: Colors.grey[300]!, width: 1),
                        ),
                        child: selected
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 16)
                            : null,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 22),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child:
                            Text(_isEditing ? 'Update' : 'Add Item'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Add entry form ──────────────────────────────────────────────────────────

class _FoodEntryForm extends StatefulWidget {
  final FoodItem item;
  final FoodEntry? existing;
  const _FoodEntryForm({required this.item, this.existing});

  @override
  State<_FoodEntryForm> createState() => _FoodEntryFormState();
}

class _FoodEntryFormState extends State<_FoodEntryForm> {
  final _formKey = GlobalKey<FormState>();
  final _quantityCtrl = TextEditingController(text: '1');
  final _descriptionCtrl = TextEditingController();
  DateTime _date = DateTime.now();

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _quantityCtrl.text = widget.existing!.quantity % 1 == 0
          ? widget.existing!.quantity.toInt().toString()
          : widget.existing!.quantity.toString();
      _descriptionCtrl.text = widget.existing!.description ?? '';
      _date = widget.existing!.date;
    }
  }

  @override
  void dispose() {
    _quantityCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final qty = double.parse(_quantityCtrl.text.trim());
    final now = DateTime.now();
    final entry = FoodEntry(
      id: widget.existing?.id ?? now.millisecondsSinceEpoch.toString(),
      foodItemId: widget.item.id,
      quantity: qty,
      date: _date,
      description: _descriptionCtrl.text.trim().isEmpty
          ? null
          : _descriptionCtrl.text.trim(),
      createdAt: widget.existing?.createdAt ?? now,
    );
    Navigator.pop(context, entry);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(item.icon, color: item.color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEditing
                              ? 'Edit entry'
                              : 'Log ${item.name}',
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          item.unitLabel == null
                              ? 'Quantity counts as "times eaten"'
                              : 'Unit: ${item.unitLabel}',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              TextFormField(
                controller: _quantityCtrl,
                decoration: InputDecoration(
                  labelText: 'Quantity *',
                  hintText: '1',
                  suffixText: item.unitLabel,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.numbers_rounded),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Please enter a quantity';
                  }
                  final n = double.tryParse(v.trim());
                  if (n == null || n <= 0) return 'Must be > 0';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                  side: BorderSide(color: Colors.grey[600]!),
                ),
                leading: const Icon(Icons.event_rounded),
                title: const Text('Date'),
                subtitle: Text(
                  DateFormat('EEEE, d MMM yyyy').format(_date),
                ),
                onTap: _pickDate,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _descriptionCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Where, with whom, how it felt…',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 22),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: item.color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(_isEditing ? 'Update' : 'Log entry'),
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

// ── Item detail page ────────────────────────────────────────────────────────

class _FoodItemDetailPage extends StatelessWidget {
  final String itemId;
  const _FoodItemDetailPage({required this.itemId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DietCubit, DietState>(
      builder: (context, state) {
        final cubit = context.read<DietCubit>();
        final item = cubit.itemById(itemId);
        if (item == null) {
          return const Scaffold(
            body: Center(child: Text('Item not found')),
          );
        }
        final entries = cubit.entriesForItemInMonth(item.id);
        final consumed = cubit.consumedThisMonth(item.id);
        final remaining = cubit.remainingThisMonth(item);
        final limit = item.monthlyLimit;
        final exceeded = limit != null && consumed > limit;

        return Scaffold(
          appBar: AppBar(
            title: Text(item.name),
            centerTitle: true,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_rounded),
                tooltip: 'Edit',
                onPressed: () async {
                  final result = await showModalBottomSheet<FoodItem>(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                          top: Radius.circular(16)),
                    ),
                    builder: (_) => _FoodItemForm(existing: item),
                  );
                  if (result != null) cubit.updateItem(result);
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                tooltip: 'Delete',
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete food item'),
                      content: Text(
                          'Delete "${item.name}" and all its entries?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: TextButton.styleFrom(
                              foregroundColor: Colors.red),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (ok == true) {
                    cubit.deleteItem(item.id);
                    if (context.mounted) Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: item.color.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: item.color.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(item.icon,
                            size: 28, color: item.color),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Consumed: ${item.quantityLabel(consumed)}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                            if (limit != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                exceeded
                                    ? 'Over limit by ${item.quantityLabel(consumed - limit)}'
                                    : '${item.quantityLabel(remaining ?? 0)} left of ${item.quantityLabel(limit)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      exceeded ? Colors.red : Colors.green[700],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    const Text(
                      'Entries this month',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Text(
                      '${entries.length}',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: entries.isEmpty
                    ? Center(
                        child: Text(
                          'No entries this month',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      )
                    : ListView.separated(
                        padding:
                            const EdgeInsets.fromLTRB(16, 4, 16, 90),
                        itemCount: entries.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 6),
                        itemBuilder: (_, i) {
                          final e = entries[i];
                          return Dismissible(
                            key: ValueKey(e.id),
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16),
                              color: Colors.red[100],
                              child: const Icon(Icons.delete_outline,
                                  color: Colors.red),
                            ),
                            direction: DismissDirection.endToStart,
                            onDismissed: (_) => cubit.deleteEntry(e.id),
                            child: InkWell(
                              onTap: () async {
                                final updated =
                                    await showModalBottomSheet<FoodEntry>(
                                  context: context,
                                  isScrollControlled: true,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(16)),
                                  ),
                                  builder: (_) => _FoodEntryForm(
                                      item: item, existing: e),
                                );
                                if (updated != null) {
                                  cubit.updateEntry(updated);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: Colors.grey[200]!),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: item.color,
                                        borderRadius:
                                            BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.quantityLabel(e.quantity),
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          if (e.description != null &&
                                              e.description!.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 2),
                                              child: Text(
                                                e.description!,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                                maxLines: 2,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      DateFormat('d MMM').format(e.date),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'diet_detail_fab',
            backgroundColor: item.color,
            foregroundColor: Colors.white,
            onPressed: () async {
              final entry = await showModalBottomSheet<FoodEntry>(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (_) => _FoodEntryForm(item: item),
              );
              if (entry != null) cubit.addEntry(entry);
            },
            icon: const Icon(Icons.add),
            label: const Text('Log entry'),
          ),
        );
      },
    );
  }
}
