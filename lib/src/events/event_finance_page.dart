import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:my_data_app/src/events/model/event_model.dart';
import 'package:my_data_app/src/events/cubit/event_cubit.dart';
import 'package:my_data_app/src/events/cubit/event_state.dart';

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
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_note_rounded, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(emptyTitle,
                style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            const SizedBox(height: 4),
            Text(emptySub,
                style: TextStyle(fontSize: 12, color: Colors.grey[400])),
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
                                    fontSize: 12, color: Colors.grey[600])),
                            if (event.eventDate != null) ...[
                              Text('  ·  ',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey[400])),
                              Text(
                                DateFormat('d MMM yyyy').format(event.eventDate!),
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[600]),
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
                              fontSize: 10, color: Colors.grey[500]),
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
                    backgroundColor: Colors.grey[200],
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
              IconButton(
                icon: Icon(
                  event.isArchived
                      ? Icons.unarchive_rounded
                      : Icons.archive_rounded,
                ),
                tooltip: event.isArchived ? 'Unarchive' : 'Archive',
                onPressed: () => cubit.toggleArchive(event.id),
              ),
              IconButton(
                icon: const Icon(Icons.edit_rounded),
                tooltip: 'Edit',
                onPressed: () async {
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
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                tooltip: 'Delete',
                onPressed: () async {
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
                    cubit.deleteEvent(event.id);
                    if (context.mounted) Navigator.pop(context);
                  }
                },
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
                                    color: Colors.grey[700],
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
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: overBudget
                                    ? Colors.red[200]!
                                    : Colors.grey[300]!,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('Budget',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[600],
                                    )),
                                Text('₹${_fmt.format(event.budget)}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: overBudget
                                          ? Colors.red[700]
                                          : Colors.black87,
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
                              Colors.white.withValues(alpha: 0.6),
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
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border:
                                      Border.all(color: Colors.grey[300]!),
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

              // Expense list
              Expanded(
                child: sorted.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long_rounded,
                                size: 44, color: Colors.grey[300]),
                            const SizedBox(height: 10),
                            Text('No expenses yet',
                                style: TextStyle(
                                    fontSize: 13, color: Colors.grey[500])),
                            const SizedBox(height: 4),
                            Text('Tap + to record your first expense',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey[400])),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
                        itemCount: sorted.length,
                        itemBuilder: (ctx, i) => _ExpenseRow(
                          expense: sorted[i],
                          color: event.color,
                          cubit: cubit,
                          event: event,
                        ),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
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
                                fontSize: 11, color: Colors.grey[500])),
                        if (expense.category != null &&
                            expense.category!.isNotEmpty) ...[
                          Text('  ·  ',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey[400])),
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
                                  fontSize: 11, color: Colors.grey[400])),
                          Flexible(
                            child: Text(expense.paidTo!,
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey[500]),
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
                            ? Colors.black87
                            : Colors.grey[500],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Text('Icon',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700])),
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
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                          border: selected
                              ? Border.all(color: previewColor, width: 2)
                              : null,
                        ),
                        child: Icon(
                          EventFund.availableIcons[i],
                          size: 22,
                          color:
                              selected ? previewColor : Colors.grey[600],
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
                        color: Colors.grey[700])),
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
                              : Border.all(color: Colors.grey[300]!),
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
