import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:my_data_app/src/events/model/event_model.dart';
import 'package:my_data_app/src/events/cubit/event_cubit.dart';
import 'package:my_data_app/src/events/cubit/event_state.dart';
import 'package:my_data_app/src/events/event_analysis_page.dart';

final _fmt = NumberFormat('#,##,###', 'en_IN');

// ─── 1. Finance → Event list ─────────────────────────────────────────────────

class EventFinancePage extends StatelessWidget {
  const EventFinancePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: BlocBuilder<EventCubit, EventState>(
        builder: (context, state) {
          final cubit = context.read<EventCubit>();
          final active = cubit.activeEvents;
          final archived = cubit.archivedEvents;

          return Scaffold(
            appBar: AppBar(
              title: const Text('Finance — Events'),
              centerTitle: true,
              elevation: 0,
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'Active'),
                  Tab(text: 'Archived'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _EventList(
                  events: active,
                  cubit: cubit,
                  emptyTitle: 'No active events yet',
                  emptySub: 'Create a tracker for your next event',
                ),
                _EventList(
                  events: archived,
                  cubit: cubit,
                  emptyTitle: 'Nothing archived',
                  emptySub: 'Completed events live here',
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () async {
                final newEvent = await Navigator.push<EventFund>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: cubit,
                      child: const AddEventPage(),
                    ),
                  ),
                );
                if (newEvent != null) cubit.addEvent(newEvent);
              },
              icon: const Icon(Icons.add),
              label: const Text('New Event'),
            ),
          );
        },
      ),
    );
  }
}

class _EventList extends StatelessWidget {
  final List<EventFund> events;
  final EventCubit cubit;
  final String emptyTitle;
  final String emptySub;

  const _EventList({
    required this.events,
    required this.cubit,
    required this.emptyTitle,
    required this.emptySub,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_note_rounded, size: 48, color: cs.outlineVariant),
            const SizedBox(height: 12),
            Text(emptyTitle,
                style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant)),
            const SizedBox(height: 4),
            Text(emptySub,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
      itemCount: events.length,
      itemBuilder: (ctx, i) {
        final event = events[i];
        final total = cubit.totalSpentFor(event.id);
        final count = cubit.expensesFor(event.id).length;
        return _EventCard(
          event: event,
          total: total,
          count: count,
          cubit: cubit,
        );
      },
    );
  }
}

class _EventCard extends StatelessWidget {
  final EventFund event;
  final double total;
  final int count;
  final EventCubit cubit;

  const _EventCard({
    required this.event,
    required this.total,
    required this.count,
    required this.cubit,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = event.color;
    final budgetProgress = event.budget != null && event.budget! > 0
        ? (total / event.budget!).clamp(0.0, 1.2)
        : null;
    final overBudget = event.budget != null && total > event.budget!;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: cubit,
                child: EventDetailPage(eventId: event.id),
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(event.icon, size: 22, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(event.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text('$count ${count == 1 ? "expense" : "expenses"}',
                                style: TextStyle(
                                    fontSize: 12, color: cs.onSurfaceVariant)),
                            if (event.eventDate != null) ...[
                              Text('  ·  ',
                                  style: TextStyle(
                                      fontSize: 12, color: cs.onSurfaceVariant)),
                              Text(
                                DateFormat('d MMM yyyy').format(event.eventDate!),
                                style: TextStyle(
                                    fontSize: 12, color: cs.onSurfaceVariant),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('₹${_fmt.format(total)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: overBudget ? Colors.red : color,
                          )),
                      if (event.budget != null)
                        Text(
                          'of ₹${_fmt.format(event.budget)}',
                          style: TextStyle(
                              fontSize: 10, color: cs.onSurfaceVariant),
                        ),
                    ],
                  ),
                ],
              ),
              if (budgetProgress != null) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: budgetProgress.clamp(0.0, 1.0),
                    minHeight: 4,
                    backgroundColor: cs.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        overBudget ? Colors.red : color),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── 2. Event Detail (per-event expenses) ────────────────────────────────────

class EventDetailPage extends StatelessWidget {
  final String eventId;
  const EventDetailPage({Key? key, required this.eventId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return BlocBuilder<EventCubit, EventState>(
      builder: (context, state) {
        final cubit = context.read<EventCubit>();
        final event = cubit.getEvent(eventId);
        if (event == null) {
          return const Scaffold(
            body: Center(child: Text('Event not found')),
          );
        }

        final expenses = cubit.expensesFor(eventId);
        final sorted = List<EventExpense>.from(expenses)
          ..sort((a, b) => b.date.compareTo(a.date));
        final total = cubit.totalSpentFor(eventId);
        final categoryMap = cubit.categoryBreakdown(eventId);
        final overBudget = event.budget != null && total > event.budget!;

        return Scaffold(
          appBar: AppBar(
            title: Text(event.name),
            elevation: 0,
            actions: [
              // Toggle between the month calendar and the date-grouped list.
              // Persisted on the event (no updatedAt bump, so it doesn't
              // reorder the event list).
              IconButton(
                icon: Icon(event.showCalendar
                    ? Icons.view_list_rounded
                    : Icons.calendar_month_rounded),
                tooltip: event.showCalendar ? 'List view' : 'Month view',
                onPressed: () => cubit.updateEvent(
                    event.copyWith(showCalendar: !event.showCalendar)),
              ),
              IconButton(
                icon: const Icon(Icons.pie_chart_rounded),
                tooltip: 'Analysis',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: cubit,
                      child: EventAnalysisPage(eventId: event.id),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings_rounded),
                tooltip: 'Settings',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: cubit,
                      child: EventSettingsPage(eventId: event.id),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              // Summary header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: event.color.withValues(alpha: 0.08),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Total Spent',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: cs.onSurface,
                                  )),
                              const SizedBox(height: 2),
                              Text(
                                '₹${_fmt.format(total)}',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: overBudget ? Colors.red : event.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (event.budget != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: overBudget
                                  ? Colors.red[50]
                                  : cs.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: overBudget
                                    ? Colors.red[200]!
                                    : cs.outline,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('Budget',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: cs.onSurfaceVariant,
                                    )),
                                Text('₹${_fmt.format(event.budget)}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: overBudget
                                          ? Colors.red[700]
                                          : cs.onSurface,
                                    )),
                              ],
                            ),
                          ),
                      ],
                    ),
                    if (event.budget != null) ...[
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (total / event.budget!).clamp(0.0, 1.0),
                          minHeight: 6,
                          backgroundColor:
                              cs.surface.withValues(alpha: 0.6),
                          valueColor: AlwaysStoppedAnimation<Color>(
                              overBudget ? Colors.red : event.color),
                        ),
                      ),
                    ],
                    if (categoryMap.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 30,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: categoryMap.entries.map((e) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: cs.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border:
                                      Border.all(color: cs.outline),
                                ),
                                child: Row(
                                  children: [
                                    Text(e.key,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        )),
                                    const SizedBox(width: 6),
                                    Text('₹${_fmt.format(e.value)}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: event.color,
                                        )),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Expenses — month calendar or date-grouped list.
              Expanded(
                child: event.showCalendar
                    ? _EventMonthCalendar(
                        event: event,
                        expenses: sorted,
                        cubit: cubit,
                      )
                    : sorted.isEmpty
                        ? const _EmptyExpenses()
                        : _GroupedExpenseList(
                            event: event,
                            expenses: sorted,
                            cubit: cubit,
                            showDates: event.showDateSeparators,
                          ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              final newExpense = await Navigator.push<EventExpense>(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: cubit,
                    child: AddExpensePage(event: event),
                  ),
                ),
              );
              if (newExpense != null) cubit.addExpense(newExpense);
            },
            backgroundColor: event.color,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Add Expense',
                style: TextStyle(color: Colors.white)),
          ),
        );
      },
    );
  }
}

class _ExpenseRow extends StatelessWidget {
  final EventExpense expense;
  final Color color;
  final EventCubit cubit;
  final EventFund event;

  const _ExpenseRow({
    required this.expense,
    required this.color,
    required this.cubit,
    required this.event,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () async {
          final edited = await Navigator.push<EventExpense>(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: cubit,
                child: AddExpensePage(event: event, existing: expense),
              ),
            ),
          );
          if (edited != null) cubit.updateExpense(edited);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 32,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(expense.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(DateFormat('d MMM yy').format(expense.date),
                            style: TextStyle(
                                fontSize: 11, color: cs.onSurfaceVariant)),
                        if (expense.category != null &&
                            expense.category!.isNotEmpty) ...[
                          Text('  ·  ',
                              style: TextStyle(
                                  fontSize: 11, color: cs.onSurfaceVariant)),
                          Text(expense.category!,
                              style: TextStyle(
                                fontSize: 11,
                                color: color,
                                fontWeight: FontWeight.w600,
                              )),
                        ],
                        if (expense.paidTo != null &&
                            expense.paidTo!.isNotEmpty) ...[
                          Text('  ·  ',
                              style: TextStyle(
                                  fontSize: 11, color: cs.onSurfaceVariant)),
                          Flexible(
                            child: Text(expense.paidTo!,
                                style: TextStyle(
                                    fontSize: 11, color: cs.onSurfaceVariant),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text('₹${_fmt.format(expense.amount)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  )),
              const SizedBox(width: 6),
              InkWell(
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Expense'),
                      content: Text('Delete "${expense.title}"?'),
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
                  if (confirmed == true) {
                    cubit.deleteExpense(event.id, expense.id);
                  }
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.delete_outline_rounded,
                      size: 14, color: Colors.red[300]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── 3. Add/Edit Event ───────────────────────────────────────────────────────

class AddEventPage extends StatefulWidget {
  final EventFund? existing;
  const AddEventPage({Key? key, this.existing}) : super(key: key);

  @override
  State<AddEventPage> createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _budget = TextEditingController();
  int _iconIndex = 0;
  int _colorIndex = 0;
  DateTime? _eventDate;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final e = widget.existing!;
      _name.text = e.name;
      _description.text = e.description ?? '';
      _budget.text = e.budget?.toString() ?? '';
      _iconIndex = e.iconIndex;
      _colorIndex = e.colorIndex;
      _eventDate = e.eventDate;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _budget.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final now = DateTime.now();
    final ev = EventFund(
      id: widget.existing?.id ?? now.millisecondsSinceEpoch.toString(),
      name: _name.text.trim(),
      description:
          _description.text.trim().isEmpty ? null : _description.text.trim(),
      iconIndex: _iconIndex,
      colorIndex: _colorIndex,
      budget: double.tryParse(_budget.text.trim()),
      createdAt: widget.existing?.createdAt ?? now,
      updatedAt: now,
      eventDate: _eventDate,
      isArchived: widget.existing?.isArchived ?? false,
    );
    Navigator.pop(context, ev);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final previewColor = EventFund.availableColors[_colorIndex];
    final previewIcon = EventFund.availableIcons[_iconIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Event' : 'New Event'),
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
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: previewColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(previewIcon, size: 42, color: previewColor),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: 'Event Name *',
                    hintText: 'e.g. Marriage, Goa Trip, Home Renovation',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _description,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _budget,
                  decoration: const InputDecoration(
                    labelText: 'Budget (₹, optional)',
                    hintText: 'Leave blank if no budget limit',
                    border: OutlineInputBorder(),
                    prefixText: '₹ ',
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _eventDate ?? DateTime.now(),
                      firstDate: DateTime(1990),
                      lastDate: DateTime(2100),
                    );
                    if (d != null) setState(() => _eventDate = d);
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Event Date (optional)',
                      border: const OutlineInputBorder(),
                      isDense: true,
                      suffixIcon: _eventDate != null
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () =>
                                  setState(() => _eventDate = null),
                            )
                          : const Icon(Icons.calendar_today_rounded, size: 18),
                    ),
                    child: Text(
                      _eventDate != null
                          ? DateFormat('EEE, MMM d, yyyy').format(_eventDate!)
                          : 'Not set',
                      style: TextStyle(
                        fontSize: 14,
                        color: _eventDate != null
                            ? cs.onSurface
                            : cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Text('Icon',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: List.generate(EventFund.availableIcons.length,
                      (i) {
                    final selected = i == _iconIndex;
                    return InkWell(
                      onTap: () => setState(() => _iconIndex = i),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: selected
                              ? previewColor.withValues(alpha: 0.15)
                              : cs.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(10),
                          border: selected
                              ? Border.all(color: previewColor, width: 2)
                              : null,
                        ),
                        child: Icon(
                          EventFund.availableIcons[i],
                          size: 22,
                          color:
                              selected ? previewColor : cs.onSurfaceVariant,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),

                Text('Color',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(EventFund.availableColors.length,
                      (i) {
                    final c = EventFund.availableColors[i];
                    final selected = i == _colorIndex;
                    return InkWell(
                      onTap: () => setState(() => _colorIndex = i),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: selected
                              ? Border.all(color: Colors.black, width: 3)
                              : Border.all(color: cs.outline),
                        ),
                        child: selected
                            ? const Icon(Icons.check,
                                size: 18, color: Colors.white)
                            : null,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 28),

                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(_isEditing ? 'Update Event' : 'Create Event',
                      style: const TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── 4. Add/Edit Expense ─────────────────────────────────────────────────────

class AddExpensePage extends StatefulWidget {
  final EventFund event;
  final EventExpense? existing;
  const AddExpensePage({Key? key, required this.event, this.existing})
      : super(key: key);

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _amount = TextEditingController();
  final _category = TextEditingController();
  final _paidTo = TextEditingController();
  final _notes = TextEditingController();

  DateTime _date = DateTime.now();
  String? _paymentMode;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final e = widget.existing!;
      _title.text = e.title;
      _amount.text = e.amount.toString();
      _category.text = e.category ?? '';
      _paidTo.text = e.paidTo ?? '';
      _notes.text = e.notes ?? '';
      _date = e.date;
      _paymentMode = e.paymentMode;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _category.dispose();
    _paidTo.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final now = DateTime.now();
    final exp = EventExpense(
      id: widget.existing?.id ?? now.millisecondsSinceEpoch.toString(),
      eventId: widget.event.id,
      title: _title.text.trim(),
      amount: double.parse(_amount.text.trim()),
      date: _date,
      category: _category.text.trim().isEmpty ? null : _category.text.trim(),
      paidTo: _paidTo.text.trim().isEmpty ? null : _paidTo.text.trim(),
      paymentMode: _paymentMode,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
    );
    Navigator.pop(context, exp);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<EventCubit>();
    final suggestions = cubit.categoriesUsed(widget.event.id);
    final color = widget.event.color;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Expense' : 'New Expense'),
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
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(widget.event.icon, size: 18, color: color),
                      const SizedBox(width: 8),
                      Text(widget.event.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: color,
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _title,
                  decoration: const InputDecoration(
                    labelText: 'What did you buy / pay for? *',
                    hintText: 'e.g. Wedding cards printing',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _amount,
                  decoration: const InputDecoration(
                    labelText: 'Amount *',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (double.tryParse(v.trim()) == null) {
                      return 'Enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                InkWell(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(1990),
                      lastDate: DateTime(2100),
                    );
                    if (d != null) setState(() => _date = d);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date *',
                      border: OutlineInputBorder(),
                      isDense: true,
                      suffixIcon: Icon(Icons.calendar_today_rounded, size: 18),
                    ),
                    child: Text(
                      DateFormat('EEE, MMM d, yyyy').format(_date),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _category,
                  decoration: const InputDecoration(
                    labelText: 'Category (optional)',
                    hintText: 'Venue, Food, Decoration, Travel...',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                if (suggestions.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: suggestions.map((s) {
                      return InkWell(
                        onTap: () => setState(() => _category.text = s),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(s,
                              style: TextStyle(
                                fontSize: 11,
                                color: color,
                                fontWeight: FontWeight.w600,
                              )),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 12),

                TextFormField(
                  controller: _paidTo,
                  decoration: const InputDecoration(
                    labelText: 'Paid To (optional)',
                    hintText: 'Vendor / person',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<String?>(
                  initialValue: _paymentMode,
                  decoration: const InputDecoration(
                    labelText: 'Payment Mode (optional)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('—'),
                    ),
                    ...kPaymentModes.map((m) => DropdownMenuItem<String?>(
                          value: m,
                          child: Text(m),
                        )),
                  ],
                  onChanged: (v) => setState(() => _paymentMode = v),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _notes,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(_isEditing ? 'Update Expense' : 'Add Expense',
                      style: const TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── 5. Expenses — empty state / grouped list / month calendar ───────────────

class _EmptyExpenses extends StatelessWidget {
  const _EmptyExpenses();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_rounded, size: 44, color: cs.outlineVariant),
          const SizedBox(height: 10),
          Text('No expenses yet',
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text('Tap + to record your first expense',
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}

/// Date-grouped expense list: a month header (name + total + count) followed
/// by that month's expenses, newest month first. When [showDates] is on, a
/// lighter per-day header is also inserted under each month. Mirrors the
/// home-records list grouping.
class _GroupedExpenseList extends StatelessWidget {
  final EventFund event;
  final List<EventExpense> expenses; // pre-sorted, newest first
  final EventCubit cubit;
  final bool showDates;

  const _GroupedExpenseList({
    required this.event,
    required this.expenses,
    required this.cubit,
    this.showDates = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final grouped = <String, List<EventExpense>>{};
    for (final e in expenses) {
      final key = DateFormat('yyyy-MM').format(e.date);
      grouped.putIfAbsent(key, () => []).add(e);
    }
    final keys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
      itemCount: keys.length,
      itemBuilder: (context, i) {
        final key = keys[i];
        final monthExpenses = grouped[key]!;
        final monthTotal =
            monthExpenses.fold<double>(0, (s, e) => s + e.amount);
        final monthDate = DateTime.parse('$key-01');
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(
                    DateFormat('MMMM yyyy').format(monthDate),
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Text('₹${_fmt.format(monthTotal)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: event.color,
                      )),
                  const SizedBox(width: 6),
                  Text('(${monthExpenses.length})',
                      style: TextStyle(
                          fontSize: 12, color: cs.onSurfaceVariant)),
                ],
              ),
            ),
            if (showDates)
              ..._buildDayGroups(cs, monthExpenses)
            else
              ...monthExpenses.map((e) => _ExpenseRow(
                    expense: e,
                    color: event.color,
                    cubit: cubit,
                    event: event,
                  )),
          ],
        );
      },
    );
  }

  /// Day sub-headers within a month: one lighter header per date (newest
  /// first) followed by that day's expense rows.
  List<Widget> _buildDayGroups(
      ColorScheme cs, List<EventExpense> monthExpenses) {
    final byDay = <String, List<EventExpense>>{};
    for (final e in monthExpenses) {
      final key = DateFormat('yyyy-MM-dd').format(e.date);
      byDay.putIfAbsent(key, () => []).add(e);
    }
    final dayKeys = byDay.keys.toList()..sort((a, b) => b.compareTo(a));

    final widgets = <Widget>[];
    for (final dk in dayKeys) {
      final dayExpenses = byDay[dk]!;
      final dayTotal = dayExpenses.fold<double>(0, (s, e) => s + e.amount);
      final dayDate = DateTime.parse(dk);
      widgets.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 6, 4, 2),
          child: Row(
            children: [
              Icon(Icons.event_rounded,
                  size: 13, color: cs.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                DateFormat('EEE, d MMM').format(dayDate),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Text('₹${_fmt.format(dayTotal)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant,
                  )),
              const SizedBox(width: 6),
              Text('(${dayExpenses.length})',
                  style:
                      TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
            ],
          ),
        ),
      );
      widgets.addAll(dayExpenses.map((e) => _ExpenseRow(
            expense: e,
            color: event.color,
            cubit: cubit,
            event: event,
          )));
    }
    return widgets;
  }
}

/// Month calendar for an event: a 7-column grid (Mon→Sun) with per-day spend
/// totals; tap a day to list its expenses beneath the grid. Navigable by
/// month via the arrows.
class _EventMonthCalendar extends StatefulWidget {
  final EventFund event;
  final List<EventExpense> expenses; // newest first
  final EventCubit cubit;

  const _EventMonthCalendar({
    required this.event,
    required this.expenses,
    required this.cubit,
  });

  @override
  State<_EventMonthCalendar> createState() => _EventMonthCalendarState();
}

class _EventMonthCalendarState extends State<_EventMonthCalendar> {
  late DateTime _month; // first day of the visible month
  late DateTime _selectedDay; // whole-day (midnight)

  @override
  void initState() {
    super.initState();
    // Open on the most recent expense's month (or today if none).
    final base = widget.expenses.isNotEmpty
        ? widget.expenses.first.date
        : DateTime.now();
    _month = DateTime(base.year, base.month);
    _selectedDay = DateTime(base.year, base.month, base.day);
  }

  void _shiftMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
      _selectedDay = DateTime(_month.year, _month.month, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = widget.event.color;

    // Per-day totals for the visible month.
    final dailyTotals = <int, double>{};
    for (final e in widget.expenses) {
      if (e.date.year == _month.year && e.date.month == _month.month) {
        dailyTotals[e.date.day] = (dailyTotals[e.date.day] ?? 0) + e.amount;
      }
    }

    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final leading =
        DateTime(_month.year, _month.month, 1).weekday - 1; // Mon = 0
    final totalCells = ((leading + daysInMonth + 6) ~/ 7) * 7;
    final rows = totalCells ~/ 7;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final dayExpenses = widget.expenses
        .where((e) =>
            e.date.year == _selectedDay.year &&
            e.date.month == _selectedDay.month &&
            e.date.day == _selectedDay.day)
        .toList();
    final dayTotal = dayExpenses.fold<double>(0, (s, e) => s + e.amount);

    const dow = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Column(
      children: [
        // Month navigator
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: () => _shiftMonth(-1),
                visualDensity: VisualDensity.compact,
              ),
              Expanded(
                child: Text(
                  DateFormat('MMMM yyyy').format(_month),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: () => _shiftMonth(1),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
        // Weekday labels
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: dow
                .map((d) => Expanded(
                      child: Center(
                        child: Text(d,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: cs.onSurfaceVariant)),
                      ),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 4),
        // Grid
        LayoutBuilder(builder: (context, constraints) {
          const hPad = 8.0;
          const spacing = 4.0;
          const aspect = 0.95;
          final cellW = (constraints.maxWidth - hPad * 2 - spacing * 6) / 7;
          final cellH = cellW / aspect;
          final gridH = rows * cellH + (rows - 1) * spacing;
          return SizedBox(
            height: gridH + 8,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(hPad, 0, hPad, 8),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: spacing,
                crossAxisSpacing: spacing,
                childAspectRatio: aspect,
              ),
              itemCount: totalCells,
              itemBuilder: (context, i) {
                final dayNum = i - leading + 1;
                if (dayNum < 1 || dayNum > daysInMonth) {
                  return const SizedBox.shrink();
                }
                final date = DateTime(_month.year, _month.month, dayNum);
                final amt = dailyTotals[dayNum] ?? 0;
                return _EventDayCell(
                  day: dayNum,
                  isToday: date == today,
                  isSelected: date == _selectedDay,
                  amountLabel: amt > 0 ? '₹${_fmt.format(amt)}' : '',
                  color: color,
                  onTap: () => setState(() => _selectedDay = date),
                );
              },
            ),
          );
        }),
        const Divider(height: 1),
        // Selected-day header
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
          child: Row(
            children: [
              Icon(Icons.event_rounded, size: 16, color: cs.onSurface),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  DateFormat('EEEE, d MMM yyyy').format(_selectedDay),
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
              if (dayExpenses.isNotEmpty) ...[
                Text('₹${_fmt.format(dayTotal)}',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: color)),
                const SizedBox(width: 6),
                Text('(${dayExpenses.length})',
                    style: TextStyle(
                        fontSize: 12, color: cs.onSurfaceVariant)),
              ],
            ],
          ),
        ),
        // Selected-day expenses
        Expanded(
          child: dayExpenses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.event_busy_rounded,
                          size: 34, color: cs.outlineVariant),
                      const SizedBox(height: 8),
                      Text('No expenses on this day',
                          style: TextStyle(
                              fontSize: 12, color: cs.onSurfaceVariant)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 80),
                  itemCount: dayExpenses.length,
                  itemBuilder: (context, i) => _ExpenseRow(
                    expense: dayExpenses[i],
                    color: color,
                    cubit: widget.cubit,
                    event: widget.event,
                  ),
                ),
        ),
      ],
    );
  }
}

class _EventDayCell extends StatelessWidget {
  final int day;
  final bool isToday;
  final bool isSelected;
  final String amountLabel;
  final Color color;
  final VoidCallback onTap;

  const _EventDayCell({
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.amountLabel,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasExpense = amountLabel.isNotEmpty;

    final Color borderColor;
    final double borderWidth;
    if (isSelected) {
      borderColor = color;
      borderWidth = 2;
    } else if (isToday) {
      borderColor = color.withValues(alpha: 0.6);
      borderWidth = 1.4;
    } else {
      borderColor = cs.outlineVariant;
      borderWidth = 1;
    }

    final Color bg;
    if (isSelected) {
      bg = color.withValues(alpha: 0.18);
    } else if (isToday) {
      bg = color.withValues(alpha: 0.10);
    } else if (hasExpense) {
      bg = color.withValues(alpha: 0.05);
    } else {
      bg = cs.surfaceContainerLow;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: borderWidth),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$day',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: (isToday || isSelected)
                      ? FontWeight.bold
                      : FontWeight.w600,
                  color: cs.onSurface,
                )),
            const Spacer(),
            if (hasExpense)
              Align(
                alignment: Alignment.bottomRight,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.bottomRight,
                  child: Text(amountLabel,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: color,
                      )),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── 6. Event Settings ───────────────────────────────────────────────────────

/// Per-event management, reached from the detail page's settings icon: edit
/// details, archive/unarchive, or delete the event.
class EventSettingsPage extends StatelessWidget {
  final String eventId;
  const EventSettingsPage({Key? key, required this.eventId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EventCubit, EventState>(
      builder: (context, state) {
        final cs = Theme.of(context).colorScheme;
        final cubit = context.read<EventCubit>();
        final event = cubit.getEvent(eventId);
        if (event == null) {
          return const Scaffold(
            body: Center(child: Text('Event not found')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Event Settings'),
            centerTitle: true,
            elevation: 0,
          ),
          body: ListView(
            children: [
              const SizedBox(height: 8),
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: event.color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: event.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(event.icon, color: event.color, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(event.name,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                          if (event.description != null &&
                              event.description!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(event.description!,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: cs.onSurfaceVariant)),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _EventSettingTile(
                icon: Icons.edit_rounded,
                iconColor: Colors.blue[700]!,
                title: 'Edit details',
                subtitle: 'Name, budget, icon, colour, date',
                onTap: () async {
                  final edited = await Navigator.push<EventFund>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                        value: cubit,
                        child: AddEventPage(existing: event),
                      ),
                    ),
                  );
                  if (edited != null) cubit.updateEvent(edited);
                },
              ),
              // List-view display: also break each month into per-day
              // headers. Only affects the date-grouped list view.
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: SwitchListTile(
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.calendar_view_day_rounded,
                        color: Colors.teal[700], size: 22),
                  ),
                  title: const Text('Show date separators',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    'Add a per-day header under each month in list view',
                    style:
                        TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                  value: event.showDateSeparators,
                  onChanged: (v) => cubit.updateEvent(
                      event.copyWith(showDateSeparators: v)),
                ),
              ),
              _EventSettingTile(
                icon: event.isArchived
                    ? Icons.unarchive_rounded
                    : Icons.archive_rounded,
                iconColor: Colors.orange[700]!,
                title: event.isArchived ? 'Unarchive' : 'Archive',
                subtitle: event.isArchived
                    ? 'Move back to active events'
                    : 'Hide from active events',
                onTap: () => cubit.toggleArchive(event.id),
              ),
              _EventSettingTile(
                icon: Icons.delete_outline_rounded,
                iconColor: Colors.red[600]!,
                title: 'Delete event',
                subtitle: 'Remove this event and all its expenses',
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Event'),
                      content: Text(
                          'Delete "${event.name}" and all its expenses?'),
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
                  if (confirmed == true) {
                    final nav = Navigator.of(context);
                    cubit.deleteEvent(event.id);
                    nav.pop(); // close settings
                    nav.pop(); // close detail → back to the event list
                  }
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

class _EventSettingTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _EventSettingTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle,
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        trailing:
            Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
        onTap: onTap,
      ),
    );
  }
}
