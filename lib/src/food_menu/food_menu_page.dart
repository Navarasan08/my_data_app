import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_data_app/src/food_menu/model/food_menu_model.dart';
import 'package:my_data_app/src/food_menu/cubit/food_menu_cubit.dart';
import 'package:my_data_app/src/food_menu/cubit/food_menu_state.dart';

class FoodMenuPage extends StatelessWidget {
  const FoodMenuPage({Key? key}) : super(key: key);

  Future<void> _addMeal(BuildContext context, FoodMenuCubit cubit,
      int weekday, MealType type) async {
    final result = await Navigator.push<MealEntry>(
      context,
      MaterialPageRoute(
        builder: (_) => AddMealPage(weekday: weekday, mealType: type),
      ),
    );
    if (result != null) cubit.addEntry(result);
  }

  Future<void> _editMeal(
      BuildContext context, FoodMenuCubit cubit, MealEntry meal) async {
    final edited = await Navigator.push<MealEntry>(
      context,
      MaterialPageRoute(builder: (_) => AddMealPage(entry: meal)),
    );
    if (edited != null) cubit.updateEntry(edited);
  }

  Future<void> _deleteMeal(BuildContext context, FoodMenuCubit cubit,
      MealEntry meal, String label) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Item'),
        content: Text('Remove "${meal.items}" from $label?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true) cubit.deleteEntry(meal.id);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FoodMenuCubit, FoodMenuState>(
      builder: (context, state) {
        final cubit = context.read<FoodMenuCubit>();
        final sel = state.selectedWeekday;

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            title: const Text('Food Menu'),
            centerTitle: true,
            elevation: 0,
          ),
          body: Column(
            children: [
              // Weekday selector
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
                child: Row(
                  children: List.generate(7, (i) {
                    final wd = i + 1;
                    final isSelected = wd == sel;
                    final isToday = wd == DateTime.now().weekday;
                    final count = cubit.mealsCountForDay(wd);

                    return Expanded(
                      child: GestureDetector(
                        onTap: () => cubit.selectWeekday(wd),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.deepOrange
                                : isToday
                                    ? Colors.orange.withValues(alpha: 0.08)
                                    : null,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Text(
                                MealEntry.weekdayName(wd),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : isToday
                                          ? Colors.deepOrange
                                          : Colors.grey[500],
                                ),
                              ),
                              const SizedBox(height: 2),
                              // Meal type dots
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: MealType.values.map((mt) {
                                  final has = cubit.getMeals(wd, mt).isNotEmpty;
                                  return Container(
                                    width: 5,
                                    height: 5,
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 1, vertical: 2),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: has
                                          ? (isSelected
                                              ? Colors.white
                                              : mt.color)
                                          : (isSelected
                                              ? Colors.white
                                                  .withValues(alpha: 0.3)
                                              : Colors.grey[300]),
                                    ),
                                  );
                                }).toList(),
                              ),
                              if (count > 0) ...[
                                const SizedBox(height: 1),
                                Text(
                                  '$count',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white70
                                        : Colors.grey[400],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              // Meal timeline
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                  children: [
                    // Day header
                    Row(
                      children: [
                        Text(
                          MealEntry.weekdayFullName(sel),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (sel == DateTime.now().weekday) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.deepOrange,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'TODAY',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Fixed meal slots (Breakfast, Lunch, Snack, Dinner)
                    ...MealTypeExt.fixedTypes.map((type) {
                      final meals = cubit.getMeals(sel, type);
                      return _MealTimelineSection(
                        mealType: type,
                        meals: meals,
                        isLast: false,
                        onAdd: () => _addMeal(context, cubit, sel, type),
                        onEdit: (meal) => _editMeal(context, cubit, meal),
                        onDelete: (meal) =>
                            _deleteMeal(context, cubit, meal, type.label),
                      );
                    }),

                    // Custom entries section
                    _CustomEntriesSection(
                      customEntries: cubit.getCustomEntries(sel),
                      onAdd: () => _addMeal(
                          context, cubit, sel, MealType.custom),
                      onEdit: (meal) => _editMeal(context, cubit, meal),
                      onDelete: (meal) =>
                          _deleteMeal(context, cubit, meal, meal.displayLabel),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Meal Timeline Section ───────────────────────────────────────────────────

class _MealTimelineSection extends StatelessWidget {
  final MealType mealType;
  final List<MealEntry> meals;
  final bool isLast;
  final VoidCallback onAdd;
  final void Function(MealEntry) onEdit;
  final void Function(MealEntry) onDelete;

  const _MealTimelineSection({
    required this.mealType,
    required this.meals,
    required this.isLast,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = mealType.color;
    final hasMeals = meals.isNotEmpty;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline column
          SizedBox(
            width: 48,
            child: Column(
              children: [
                Text(
                  mealType.timeHint.split('–')[0].trim(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: hasMeals ? color : Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: hasMeals ? color : Colors.grey[300],
                    border: hasMeals
                        ? Border.all(
                            color: color.withValues(alpha: 0.3), width: 3)
                        : null,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: Colors.grey[200]),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: hasMeals
                      ? color.withValues(alpha: 0.2)
                      : Colors.grey[200]!,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Text(mealType.emoji, style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                mealType.label,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: hasMeals ? color : Colors.grey[400],
                                ),
                              ),
                              Text(
                                mealType.timeHint,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Add button (always visible)
                        InkWell(
                          onTap: onAdd,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_rounded,
                                    size: 14, color: color),
                                const SizedBox(width: 2),
                                Text(
                                  'Add',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Meal entries
                    if (hasMeals) ...[
                      const SizedBox(height: 10),
                      ...meals.map((meal) => _MealItemRow(
                            meal: meal,
                            color: color,
                            onEdit: () => onEdit(meal),
                            onDelete: () => onDelete(meal),
                          )),
                    ] else ...[
                      const SizedBox(height: 8),
                      Text(
                        'No meal planned yet',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Custom Entries Section ──────────────────────────────────────────────────

class _CustomEntriesSection extends StatelessWidget {
  final List<MealEntry> customEntries;
  final VoidCallback onAdd;
  final void Function(MealEntry) onEdit;
  final void Function(MealEntry) onDelete;

  const _CustomEntriesSection({
    required this.customEntries,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = MealType.custom.color;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline column
          SizedBox(
            width: 48,
            child: Column(
              children: [
                Text(
                  '⏰',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: customEntries.isNotEmpty ? color : Colors.grey[300],
                    border: customEntries.isNotEmpty
                        ? Border.all(
                            color: color.withValues(alpha: 0.3), width: 3)
                        : null,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: customEntries.isNotEmpty
                      ? color.withValues(alpha: 0.2)
                      : Colors.grey[200]!,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        const Text('⏰',
                            style: TextStyle(fontSize: 24)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Custom Items',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: customEntries.isNotEmpty
                                      ? color
                                      : Colors.grey[400],
                                ),
                              ),
                              Text(
                                'Pre-workout, Juice, Supplements...',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: onAdd,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_rounded,
                                    size: 14, color: color),
                                const SizedBox(width: 2),
                                Text(
                                  'Add',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (customEntries.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      ...customEntries.map((entry) => _CustomItemRow(
                            meal: entry,
                            onEdit: () => onEdit(entry),
                            onDelete: () => onDelete(entry),
                          )),
                    ] else ...[
                      const SizedBox(height: 8),
                      Text(
                        'Add items for specific times',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomItemRow extends StatelessWidget {
  final MealEntry meal;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CustomItemRow({
    required this.meal,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = MealType.custom.color;
    final time = meal.formattedTime;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
          child: Row(
            children: [
              // Time badge
              if (time != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    time,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (meal.customLabel != null &&
                        meal.customLabel!.isNotEmpty)
                      Text(
                        meal.customLabel!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    Text(
                      meal.items,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (meal.notes != null && meal.notes!.isNotEmpty)
                      Text(
                        meal.notes!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              InkWell(
                onTap: onDelete,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.all(5),
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

// ─── Single Meal Item Row ────────────────────────────────────────────────────

class _MealItemRow extends StatelessWidget {
  final MealEntry meal;
  final Color color;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MealItemRow({
    required this.meal,
    required this.color,
    required this.onEdit,
    required this.onDelete,
  });

  static const _foodEmojis = {
    'rice': '🍚', 'dal': '🍲', 'roti': '🫓', 'chapati': '🫓',
    'naan': '🫓', 'sabzi': '🥘', 'curry': '🍛', 'biryani': '🍛',
    'dosa': '🥞', 'idli': '🍘', 'samosa': '🥟', 'paratha': '🫓',
    'tea': '🍵', 'coffee': '☕', 'juice': '🧃', 'milk': '🥛',
    'egg': '🥚', 'omelette': '🍳', 'bread': '🍞', 'toast': '🍞',
    'salad': '🥗', 'soup': '🍜', 'sandwich': '🥪', 'burger': '🍔',
    'pizza': '🍕', 'pasta': '🍝', 'noodles': '🍜', 'maggi': '🍜',
    'chicken': '🍗', 'fish': '🐟', 'paneer': '🧀', 'curd': '🥛',
    'fruit': '🍎', 'banana': '🍌', 'apple': '🍎', 'mango': '🥭',
    'cake': '🍰', 'ice cream': '🍦', 'biscuit': '🍪', 'cookie': '🍪',
    'water': '💧', 'lassi': '🥛', 'buttermilk': '🥛', 'smoothie': '🥤',
    'poha': '🍚', 'upma': '🍚', 'puri': '🫓', 'khichdi': '🍚',
    'raita': '🥛', 'pickle': '🫙', 'papad': '🫓', 'chutney': '🫙',
    'sweet': '🍬', 'halwa': '🍮', 'kheer': '🍮', 'gulab jamun': '🍩',
  };

  String _getEmoji(String item) {
    final lower = item.toLowerCase();
    for (final entry in _foodEmojis.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return '🍽️';
  }

  @override
  Widget build(BuildContext context) {
    final items = meal.items
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 6, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Food items as emoji + text rows
                    ...items.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Text(_getEmoji(item),
                                style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    if (meal.notes != null && meal.notes!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Padding(
                        padding: const EdgeInsets.only(left: 2),
                        child: Text(
                          meal.notes!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              InkWell(
                onTap: onDelete,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.all(5),
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

// ─── Add / Edit Meal Page ────────────────────────────────────────────────────

class AddMealPage extends StatefulWidget {
  final MealEntry? entry;
  final int? weekday;
  final MealType? mealType;

  const AddMealPage({Key? key, this.entry, this.weekday, this.mealType})
      : super(key: key);

  @override
  State<AddMealPage> createState() => _AddMealPageState();
}

class _AddMealPageState extends State<AddMealPage> {
  final _formKey = GlobalKey<FormState>();
  final _itemsController = TextEditingController();
  final _notesController = TextEditingController();
  final _labelController = TextEditingController();
  late int _weekday;
  late MealType _mealType;
  int? _timeHour;
  int? _timeMinute;

  bool get _isEditing => widget.entry != null;
  bool get _isCustom => _mealType == MealType.custom;

  @override
  void initState() {
    super.initState();
    if (widget.entry != null) {
      _itemsController.text = widget.entry!.items;
      _notesController.text = widget.entry!.notes ?? '';
      _labelController.text = widget.entry!.customLabel ?? '';
      _weekday = widget.entry!.weekday;
      _mealType = widget.entry!.mealType;
      _timeHour = widget.entry!.timeHour;
      _timeMinute = widget.entry!.timeMinute;
    } else {
      _weekday = widget.weekday ?? DateTime.now().weekday;
      _mealType = widget.mealType ?? MealType.lunch;
    }
  }

  @override
  void dispose() {
    _itemsController.dispose();
    _notesController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final entry = MealEntry(
      id: widget.entry?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      weekday: _weekday,
      mealType: _mealType,
      items: _itemsController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      customLabel: _isCustom && _labelController.text.trim().isNotEmpty
          ? _labelController.text.trim()
          : null,
      timeHour: _isCustom ? _timeHour : null,
      timeMinute: _isCustom ? _timeMinute : null,
    );
    Navigator.pop(context, entry);
  }

  Future<void> _pickTime() async {
    final initial = TimeOfDay(
      hour: _timeHour ?? TimeOfDay.now().hour,
      minute: _timeMinute ?? 0,
    );
    final time = await showTimePicker(context: context, initialTime: initial);
    if (time != null) {
      setState(() {
        _timeHour = time.hour;
        _timeMinute = time.minute;
      });
    }
  }

  String get _timeDisplay {
    if (_timeHour == null) return 'Set time';
    final h = _timeHour! % 12 == 0 ? 12 : _timeHour! % 12;
    final m = (_timeMinute ?? 0).toString().padLeft(2, '0');
    final p = _timeHour! < 12 ? 'AM' : 'PM';
    return '$h:$m $p';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Meal' : 'Add Meal'),
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
                // Preview
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _mealType.color.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _mealType.color.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(_mealType.emoji,
                          style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isCustom
                                  ? (_labelController.text.isNotEmpty
                                      ? '${_labelController.text} · ${MealEntry.weekdayFullName(_weekday)}'
                                      : 'Custom · ${MealEntry.weekdayFullName(_weekday)}')
                                  : '${_mealType.label} · ${MealEntry.weekdayFullName(_weekday)}',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: _mealType.color,
                              ),
                            ),
                            Text(
                              _isCustom
                                  ? (_timeHour != null
                                      ? _timeDisplay
                                      : 'Set a time')
                                  : _mealType.timeHint,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Day + Meal type
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _weekday,
                        decoration: const InputDecoration(
                          labelText: 'Day',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today_rounded),
                        ),
                        items: List.generate(7, (i) {
                          final wd = i + 1;
                          return DropdownMenuItem(
                            value: wd,
                            child: Text(MealEntry.weekdayFullName(wd)),
                          );
                        }),
                        onChanged: (v) {
                          if (v != null) setState(() => _weekday = v);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<MealType>(
                        value: _mealType,
                        decoration: const InputDecoration(
                          labelText: 'Meal Type',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.restaurant_rounded),
                        ),
                        items: MealType.values.map((t) {
                          return DropdownMenuItem(
                            value: t,
                            child: Row(
                              children: [
                                Icon(t.icon, size: 18, color: t.color),
                                const SizedBox(width: 8),
                                Text(t.label),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _mealType = v);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Custom fields
                if (_isCustom) ...[
                  TextFormField(
                    controller: _labelController,
                    decoration: const InputDecoration(
                      labelText: 'Label',
                      hintText: 'e.g. Pre-workout, Evening Juice, Supplement',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.label_outline_rounded),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                      side: BorderSide(color: Colors.grey[400]!),
                    ),
                    leading: Icon(Icons.access_time_rounded,
                        color: _mealType.color),
                    title: const Text('Time'),
                    subtitle: Text(
                      _timeDisplay,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: _timeHour != null
                            ? _mealType.color
                            : Colors.grey[500],
                      ),
                    ),
                    onTap: _pickTime,
                  ),
                  const SizedBox(height: 16),
                ],

                TextFormField(
                  controller: _itemsController,
                  decoration: InputDecoration(
                    labelText: _isCustom ? 'Items *' : 'Food Items *',
                    hintText: _isCustom
                        ? 'e.g. Protein shake, Banana'
                        : 'Rice, Dal, Sabzi, Roti',
                    helperText: 'Separate items with commas',
                    border: const OutlineInputBorder(),
                    prefixIcon:
                        Icon(Icons.fastfood_rounded, color: _mealType.color),
                  ),
                  maxLines: 3,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    hintText: 'e.g. Make it spicy, less oil',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 32),

                ElevatedButton.icon(
                  onPressed: _save,
                  icon: Icon(
                      _isEditing ? Icons.save_rounded : Icons.add_rounded),
                  label: Text(
                    _isEditing ? 'Update' : 'Save',
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _mealType.color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
