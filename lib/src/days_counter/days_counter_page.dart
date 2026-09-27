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
                  tooltip: 'Filters',
                  onPressed: () => _openFilterSheet(context, cubit),
                  icon: Badge(
                    isLabelVisible: state.activeFilterCount > 0,
                    label: Text('${state.activeFilterCount}'),
                    child: const Icon(Icons.filter_list_rounded),
                  ),
                ),
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
            body: Column(
              children: [
                _FilterStrip(cubit: cubit, state: state),
                Expanded(
                  child: TabBarView(
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

/// One scrolling row of chips: the day window first, then one chip per
/// event type. Everything else lives in the filter sheet.
class _FilterStrip extends StatelessWidget {
  final DaysCounterCubit cubit;
  final DaysCounterState state;
  const _FilterStrip({required this.cubit, required this.state});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hidden = cubit.hiddenByFilters;
    final hiddenLabel = hidden == 0
        ? 'Filters on'
        : '$hidden ${hidden == 1 ? 'event' : 'events'} hidden';
    return Container(
      color: cs.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children: [
                for (final w in DaysCounterWindow.values) ...[
                  ChoiceChip(
                    label: Text(w.label),
                    selected: state.window == w,
                    onSelected: (_) => cubit.setWindow(w),
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 6),
                ],
                Container(
                  width: 1,
                  height: 22,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  color: cs.outlineVariant,
                ),
                for (final t in state.eventTypes) ...[
                  const SizedBox(width: 6),
                  FilterChip(
                    avatar: Icon(t.icon, size: 16, color: t.color),
                    label: Text(t.displayName),
                    selected: state.typeFilter.contains(t.id),
                    onSelected: (_) => cubit.toggleTypeFilter(t.id),
                    selectedColor: t.color.withValues(alpha: 0.18),
                    checkmarkColor: t.color,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ],
            ),
          ),
          if (state.hasActiveFilters)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 8, 4),
              child: Row(
                children: [
                  Text(
                    hiddenLabel,
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: cubit.clearFilters,
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Clear'),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ],
              ),
            ),
          Divider(height: 1, color: cs.outlineVariant),
        ],
      ),
    );
  }
}

/// Recurrence, search and a clear-all, for the filters that do not fit in
/// the strip.
Future<void> _openFilterSheet(BuildContext context, DaysCounterCubit cubit) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: BlocBuilder<DaysCounterCubit, DaysCounterState>(
        builder: (context, state) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              0,
              20,
              MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filters',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: state.search,
                    onChanged: cubit.setSearch,
                    decoration: const InputDecoration(
                      labelText: 'Search title or notes',
                      prefixIcon: Icon(Icons.search_rounded),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Recurrence',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  SegmentedButton<DaysCounterRecurrence?>(
                    segments: const [
                      ButtonSegment(value: null, label: Text('Both')),
                      ButtonSegment(
                        value: DaysCounterRecurrence.yearly,
                        label: Text('Yearly'),
                      ),
                      ButtonSegment(
                        value: DaysCounterRecurrence.oneTime,
                        label: Text('One time'),
                      ),
                    ],
                    selected: {state.recurrenceFilter},
                    onSelectionChanged: (s) =>
                        cubit.setRecurrenceFilter(s.first),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Show within',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: DaysCounterWindow.values
                        .map(
                          (w) => ChoiceChip(
                            label: Text(w.label),
                            selected: state.window == w,
                            onSelected: (_) => cubit.setWindow(w),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Event types',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: state.eventTypes
                        .map(
                          (t) => FilterChip(
                            avatar: Icon(t.icon, size: 16, color: t.color),
                            label: Text(t.displayName),
                            selected: state.typeFilter.contains(t.id),
                            onSelected: (_) => cubit.toggleTypeFilter(t.id),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      TextButton(
                        onPressed: state.hasActiveFilters
                            ? cubit.clearFilters
                            : null,
                        child: const Text('Clear all'),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Done'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ),
  );
}

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
      itemBuilder: (_, i) =>
          _EventCard(event: events[i], mode: mode, cubit: cubit),
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
    final theme = _KindTheme.of(event);
    final color = theme.primary;
    final isUpcoming = mode == _EventListMode.upcoming;
    final daysCount = isUpcoming
        ? event.daysUntilNext ?? 0
        : event.daysSincePast ?? 0;
    final next = event.nextOccurrence;
    final occurDate = isUpcoming ? next ?? event.date : event.date;
    final today = DateTime.now();
    // Type-aware wording: "Turning 33" + "Born 12 Mar 1994 · 32 years old"
    // for a birthday, "12th death anniversary" for a memorial, and so on.
    final desc = event.describe(upcoming: isUpcoming, today: today);
    final yearsLabel = desc.headline;

    final dayLabel = isUpcoming
        ? (daysCount == 0 ? 'Today' : '$daysCount')
        : '$daysCount';
    final daySub = isUpcoming
        ? (daysCount == 0
              ? 'is the day'
              : daysCount == 1
              ? 'day to go'
              : 'days to go')
        : (daysCount == 1 ? 'day ago' : 'days ago');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        // A soft wash of the kind's colour over the surface, so a wedding
        // card reads rose, a memorial card slate, a birthday card warm.
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color.alphaBlend(theme.primary.withValues(alpha: 0.10), cs.surface),
            Color.alphaBlend(
              theme.secondary.withValues(alpha: 0.04),
              cs.surface,
            ),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.30)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Watermark motif in the corner: rings, cake, candle, lantern…
          Positioned(
            right: -14,
            bottom: -18,
            child: Icon(
              theme.watermark,
              size: 96,
              color: theme.primary.withValues(alpha: 0.08),
            ),
          ),
          if (theme.ribbon != null)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 3, 12, 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.primary, theme.secondary],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                  ),
                ),
                child: Text(
                  theme.ribbon!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          InkWell(
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
              // Extra headroom when a ribbon sits in the corner.
              padding: EdgeInsets.fromLTRB(
                14,
                theme.ribbon != null ? 20 : 14,
                14,
                14,
              ),
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
                        colors: [theme.primary, theme.secondary],
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
                                horizontal: 6,
                                vertical: 1,
                              ),
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
                            Icon(
                              Icons.event_rounded,
                              size: 13,
                              color: cs.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                DateFormat(
                                  event.isYearly ? 'd MMM' : 'd MMM yyyy',
                                ).format(occurDate),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: cs.onSurface,
                                ),
                              ),
                            ),
                            if (event.isYearly) ...[
                              const SizedBox(width: 6),
                              Text(
                                DateFormat('yyyy').format(occurDate),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                            if (yearsLabel != null) ...[
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  '· $yearsLabel',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: color,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (desc.detail != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Row(
                              children: [
                                Icon(
                                  _kindIcon(event.kind),
                                  size: 12,
                                  color: cs.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    desc.detail!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: cs.onSurfaceVariant,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
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
                            horizontal: 6,
                            vertical: 2,
                          ),
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
                      : Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: cs.onSurfaceVariant,
                        ),
                ],
              ),
            ),
          ),
        ],
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
            child: const Text('Cancel'),
          ),
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
}

/// Visual identity of a card, chosen by what the event *is*: a wedding
/// card is rose and gold with rings, a birthday card warm with a cake, a
/// memorial card calm slate with a candle, a festival card bright with a
/// lantern. Custom types fall back to the colour the user picked for them.
class _KindTheme {
  final Color primary;
  final Color secondary;
  final IconData watermark;

  /// Small ribbon in the top-right corner; null for plain cards.
  final String? ribbon;

  const _KindTheme({
    required this.primary,
    required this.secondary,
    required this.watermark,
    this.ribbon,
  });

  static _KindTheme of(DaysCounterEvent event) {
    switch (event.kind) {
      case DaysCounterEventKind.birthday:
        return const _KindTheme(
          primary: Color(0xFFF06292), // pink
          secondary: Color(0xFFFFB74D), // amber
          watermark: Icons.cake_rounded,
          ribbon: 'BIRTHDAY',
        );
      case DaysCounterEventKind.wedding:
        return const _KindTheme(
          primary: Color(0xFFC2185B), // deep rose
          secondary: Color(0xFFD4AF37), // gold
          watermark: Icons.favorite_rounded,
          ribbon: 'ANNIVERSARY',
        );
      case DaysCounterEventKind.memorial:
        return const _KindTheme(
          primary: Color(0xFF546E7A), // slate
          secondary: Color(0xFF90A4AE),
          watermark: Icons.local_florist_rounded,
          ribbon: 'IN MEMORY',
        );
      case DaysCounterEventKind.festival:
        return const _KindTheme(
          primary: Color(0xFFFF7043), // orange
          secondary: Color(0xFF7E57C2), // violet
          watermark: Icons.celebration_rounded,
          ribbon: 'FESTIVAL',
        );
      case DaysCounterEventKind.other:
        final c = event.eventType.color;
        return _KindTheme(
          primary: c,
          secondary: Color.lerp(c, Colors.black, 0.25)!,
          watermark: event.eventType.icon,
        );
    }
  }
}

IconData _kindIcon(DaysCounterEventKind kind) => switch (kind) {
  DaysCounterEventKind.birthday => Icons.cake_rounded,
  DaysCounterEventKind.memorial => Icons.local_florist_rounded,
  DaysCounterEventKind.wedding => Icons.favorite_rounded,
  DaysCounterEventKind.festival => Icons.celebration_rounded,
  DaysCounterEventKind.other => Icons.history_rounded,
};

/// What the date field means for this kind of event.
String _dateLabelFor(DaysCounterEventKind kind, DaysCounterRecurrence r) {
  if (r == DaysCounterRecurrence.oneTime) return 'Date';
  return switch (kind) {
    DaysCounterEventKind.birthday => 'Date of birth',
    DaysCounterEventKind.memorial => 'Date of passing',
    DaysCounterEventKind.wedding => 'Wedding date',
    DaysCounterEventKind.festival => 'Date',
    DaysCounterEventKind.other => 'Original date',
  };
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
  bool _yearKnown = true;

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
      _yearKnown = e.yearKnown;
    }
  }

  DaysCounterEventKind get _kind => _selectedType == null
      ? DaysCounterEventKind.other
      : daysCounterKindOf(_selectedType!);

  /// Live preview of what the card will say for the current form values.
  String? _preview() {
    final type = _selectedType;
    if (type == null || _recurrence != DaysCounterRecurrence.yearly) {
      return null;
    }
    final now = DateTime.now();
    final draft = DaysCounterEvent(
      id: '_',
      title: '',
      eventType: type,
      date: _selectedDate,
      recurrence: _recurrence,
      yearKnown: _yearKnown,
      createdAt: now,
      updatedAt: now,
    );
    final d = draft.describe(upcoming: true, today: now);
    final parts = [
      if (d.headline != null) d.headline!,
      if (d.detail != null) d.detail!,
    ];
    return parts.isEmpty ? null : parts.join(' · ');
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pick an event type.')));
      return;
    }
    final now = DateTime.now();
    final ev = DaysCounterEvent(
      id: widget.existing?.id ?? now.millisecondsSinceEpoch.toString(),
      title: _titleCtrl.text.trim(),
      eventType: type,
      date: _selectedDate,
      recurrence: _recurrence,
      yearKnown: _recurrence == DaysCounterRecurrence.yearly
          ? _yearKnown
          : true,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
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
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Row(
                            children: [
                              Icon(t.icon, size: 18, color: t.color),
                              const SizedBox(width: 8),
                              Text(t.displayName),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedType = v);
                  },
                ),
                const SizedBox(height: 14),

                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                    side: BorderSide(color: cs.outline),
                  ),
                  leading: Icon(_kindIcon(_kind)),
                  title: Text(_dateLabelFor(_kind, _recurrence)),
                  subtitle: Text(
                    DateFormat(
                      _yearKnown || _recurrence != DaysCounterRecurrence.yearly
                          ? 'EEEE, d MMM yyyy'
                          : 'd MMMM',
                    ).format(_selectedDate),
                  ),
                  onTap: _pickDate,
                ),
                if (_recurrence == DaysCounterRecurrence.yearly) ...[
                  CheckboxListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                    value: !_yearKnown,
                    onChanged: (v) =>
                        setState(() => _yearKnown = !(v ?? false)),
                    title: const Text('I don\'t know the year'),
                    subtitle: const Text(
                      'Only the day and month will be used; no age shown.',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                  if (_preview() != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 2, 12, 0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            size: 14,
                            color: cs.primary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _preview()!,
                              style: TextStyle(
                                fontSize: 12,
                                color: cs.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
                const SizedBox(height: 14),

                Text(
                  'Recurrence',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                SegmentedButton<DaysCounterRecurrence>(
                  segments: DaysCounterRecurrence.values
                      .map(
                        (r) => ButtonSegment(
                          value: r,
                          label: Text(r.label),
                          icon: Icon(
                            r == DaysCounterRecurrence.yearly
                                ? Icons.autorenew_rounded
                                : Icons.calendar_today_rounded,
                          ),
                        ),
                      )
                      .toList(),
                  selected: {_recurrence},
                  onSelectionChanged: (s) =>
                      setState(() => _recurrence = s.first),
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    textStyle: const WidgetStatePropertyAll(
                      TextStyle(fontSize: 12),
                    ),
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
