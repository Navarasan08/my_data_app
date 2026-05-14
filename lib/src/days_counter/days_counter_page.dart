import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:my_data_app/src/days_counter/cubit/days_counter_cubit.dart';
import 'package:my_data_app/src/days_counter/cubit/days_counter_state.dart';
import 'package:my_data_app/src/days_counter/days_counter_settings_page.dart';
import 'package:my_data_app/src/days_counter/model/days_counter_model.dart';

class DaysCounterPage extends StatelessWidget {
  const DaysCounterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: BlocBuilder<DaysCounterCubit, DaysCounterState>(
        builder: (context, state) {
          final cubit = context.read<DaysCounterCubit>();
          final upcoming = cubit.upcoming;
          final past = cubit.past;

          return Scaffold(
            appBar: AppBar(
              title: const Text('Days Counter'),
              centerTitle: true,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.tune_rounded),
                  tooltip: 'Event types',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                        value: cubit,
                        child: const DaysCounterSettingsPage(),
                      ),
                    ),
                  ),
                ),
              ],
              bottom: TabBar(
                tabs: [
                  Tab(text: 'Upcoming (${upcoming.length})'),
                  Tab(text: 'Past (${past.length})'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _EventList(
                  events: upcoming,
                  mode: _EventListMode.upcoming,
                  cubit: cubit,
                ),
                _EventList(
                  events: past,
                  mode: _EventListMode.past,
                  cubit: cubit,
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              heroTag: 'days_counter_fab',
              onPressed: () async {
                final result = await Navigator.push<DaysCounterEvent>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: cubit,
                      child: const AddEventPage(),
                    ),
                  ),
                );
                if (result != null) cubit.addEvent(result);
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Event'),
            ),
          );
        },
      ),
    );
  }
}

enum _EventListMode { upcoming, past }

class _EventList extends StatelessWidget {
  final List<DaysCounterEvent> events;
  final _EventListMode mode;
  final DaysCounterCubit cubit;

  const _EventList({
    required this.events,
    required this.mode,
    required this.cubit,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              mode == _EventListMode.upcoming
                  ? Icons.event_available_rounded
                  : Icons.history_rounded,
              size: 56,
              color: cs.outline,
            ),
            const SizedBox(height: 12),
            Text(
              mode == _EventListMode.upcoming
                  ? 'No upcoming events'
                  : 'No past events',
              style: TextStyle(fontSize: 15, color: cs.onSurfaceVariant),
            ),
            if (mode == _EventListMode.upcoming) ...[
              const SizedBox(height: 4),
              Text(
                'Tap + to add a birthday, anniversary or one-time event',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
      itemCount: events.length,
      itemBuilder: (_, i) => _EventCard(event: events[i], mode: mode, cubit: cubit),
    );
  }
}

class _EventCard extends StatelessWidget {
  final DaysCounterEvent event;
  final _EventListMode mode;
  final DaysCounterCubit cubit;

  const _EventCard({
    required this.event,
    required this.mode,
    required this.cubit,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = event.eventType.color;
    final isUpcoming = mode == _EventListMode.upcoming;
    final daysCount =
        isUpcoming ? event.daysUntilNext ?? 0 : event.daysSincePast ?? 0;
    final next = event.nextOccurrence;
    final occurDate = isUpcoming ? next ?? event.date : event.date;
    final today = DateTime.now();
    final yearsDelta = event.isYearly
        ? event.yearsFromOriginalOn(occurDate)
        : null;

    // Years subtitle: "Turning 60" / "12 years ago"
    String? yearsLabel;
    if (yearsDelta != null && yearsDelta > 0) {
      yearsLabel = isUpcoming
          ? (event.eventType.id == 'birthday'
              ? 'Turning $yearsDelta'
              : '$yearsDelta${_ordinalSuffix(yearsDelta)} year')
          : '$yearsDelta year${yearsDelta == 1 ? '' : 's'} ago';
    }

    final dayLabel = isUpcoming
        ? (daysCount == 0 ? 'Today' : '$daysCount')
        : '$daysCount';
    final daySub = isUpcoming
        ? (daysCount == 0 ? 'is the day' : daysCount == 1 ? 'day to go' : 'days to go')
        : (daysCount == 1 ? 'day ago' : 'days ago');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          final result = await Navigator.push<DaysCounterEvent>(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: cubit,
                child: AddEventPage(existing: event),
              ),
            ),
          );
          if (result != null) cubit.updateEvent(result);
        },
        onLongPress: () => _confirmDelete(context),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Big day count box
              Container(
                width: 78,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color,
                      Color.lerp(color, Colors.black, 0.25)!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        dayLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      daySub,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(event.eventType.icon, size: 14, color: color),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            event.eventType.displayName,
                            style: TextStyle(
                              fontSize: 12,
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: event.isYearly
                                ? Colors.green.withValues(alpha: 0.12)
                                : Colors.blueGrey.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            event.isYearly ? 'Yearly' : 'One time',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: event.isYearly
                                  ? Colors.green[800]
                                  : Colors.blueGrey,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.event_rounded,
                            size: 13, color: cs.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            DateFormat(
                              event.isYearly
                                  ? 'd MMM'
                                  : 'd MMM yyyy',
                            ).format(occurDate),
                            style: TextStyle(
                                fontSize: 12, color: cs.onSurface),
                          ),
                        ),
                        if (event.isYearly) ...[
                          const SizedBox(width: 6),
                          Text(
                            DateFormat('yyyy').format(occurDate),
                            style: TextStyle(
                                fontSize: 11, color: cs.onSurfaceVariant),
                          ),
                        ],
                        if (yearsLabel != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '· $yearsLabel',
                            style: TextStyle(
                                fontSize: 11,
                                color: color,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ],
                    ),
                    if (event.notes != null && event.notes!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          event.notes!,
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              Today.isToday(occurDate, today)
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'TODAY',
                        style: TextStyle(
                          fontSize: 9,
                          color: color,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    )
                  : Icon(Icons.chevron_right_rounded,
                      size: 20, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete event'),
        content: Text('Remove "${event.title}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) cubit.deleteEvent(event.id);
  }

  static String _ordinalSuffix(int n) {
    if (n % 100 >= 11 && n % 100 <= 13) return 'th';
    switch (n % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }
}

class Today {
  static bool isToday(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ── Add / edit event ─────────────────────────────────────────────────────────

class AddEventPage extends StatefulWidget {
  final DaysCounterEvent? existing;
  const AddEventPage({super.key, this.existing});

  @override
  State<AddEventPage> createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  DaysCounterEventType? _selectedType;
  DateTime _selectedDate = DateTime.now();
  DaysCounterRecurrence _recurrence = DaysCounterRecurrence.yearly;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final e = widget.existing!;
      _titleCtrl.text = e.title;
      _notesCtrl.text = e.notes ?? '';
      _selectedType = e.eventType;
      _selectedDate = e.date;
      _recurrence = e.recurrence;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => _selectedDate = d);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final type = _selectedType;
    if (type == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick an event type.')),
      );
      return;
    }
    final now = DateTime.now();
    final ev = DaysCounterEvent(
      id: widget.existing?.id ?? now.millisecondsSinceEpoch.toString(),
      title: _titleCtrl.text.trim(),
      eventType: type,
      date: _selectedDate,
      recurrence: _recurrence,
      notes:
          _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      createdAt: widget.existing?.createdAt ?? now,
      updatedAt: now,
    );
    Navigator.pop(context, ev);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cubit = context.read<DaysCounterCubit>();
    final types = cubit.state.eventTypes;
    // Make sure the saved type is in the dropdown even if it was deleted
    // from the user's managed list — denormalized snapshot keeps the label.
    final merged = <DaysCounterEventType>[...types];
    final selected = _selectedType;
    if (selected != null && !merged.any((t) => t.id == selected.id)) {
      merged.add(selected);
    }
    _selectedType ??= merged.isNotEmpty ? merged.first : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Event' : 'Add Event'),
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
                  controller: _titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Title *',
                    hintText: "e.g. Mom's birthday, Concert",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title_rounded),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Enter a title' : null,
                ),
                const SizedBox(height: 14),

                DropdownButtonFormField<DaysCounterEventType>(
                  initialValue: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Event type *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category_rounded),
                  ),
                  items: merged
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Row(
                              children: [
                                Icon(t.icon, size: 18, color: t.color),
                                const SizedBox(width: 8),
                                Text(t.displayName),
                              ],
                            ),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedType = v);
                  },
                ),
                const SizedBox(height: 14),

                ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                    side: BorderSide(color: cs.outline),
                  ),
                  leading: const Icon(Icons.event_rounded),
                  title: const Text('Date'),
                  subtitle: Text(
                    DateFormat('EEEE, d MMM yyyy').format(_selectedDate),
                  ),
                  onTap: _pickDate,
                ),
                const SizedBox(height: 14),

                Text(
                  'Recurrence',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface),
                ),
                const SizedBox(height: 6),
                SegmentedButton<DaysCounterRecurrence>(
                  segments: DaysCounterRecurrence.values
                      .map((r) => ButtonSegment(
                            value: r,
                            label: Text(r.label),
                            icon: Icon(r == DaysCounterRecurrence.yearly
                                ? Icons.autorenew_rounded
                                : Icons.calendar_today_rounded),
                          ))
                      .toList(),
                  selected: {_recurrence},
                  onSelectionChanged: (s) =>
                      setState(() => _recurrence = s.first),
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    textStyle: const WidgetStatePropertyAll(
                        TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    _isEditing ? 'Update Event' : 'Save Event',
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
