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

    final isToday = isUpcoming && daysCount == 0;
    final dateText = DateFormat(
      isUpcoming ? 'EEE, d MMM yyyy' : 'd MMM yyyy',
    ).format(occurDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withValues(alpha: isToday ? 0.75 : 0.30),
          width: isToday ? 1.6 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isToday ? 0.18 : 0.08),
            blurRadius: isToday ? 16 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Watermark motif in the corner: rings, cake, candle, lantern…
          Positioned(
            right: -18,
            bottom: -22,
            child: Icon(
              theme.watermark,
              size: 110,
              color: theme.primary.withValues(alpha: 0.07),
            ),
          ),
          // The milestone is the point of the card ("Turning 24", "4th
          // wedding anniversary"), so it takes the top-right corner tag.
          if (yearsLabel != null)
            Positioned(
              top: 0,
              right: 0,
              child: _MilestoneBadge(
                text: yearsLabel,
                icon: _kindIcon(event.kind),
                theme: theme,
                emphasized: isToday,
                corner: true,
              ),
            ),
          InkWell(
            borderRadius: BorderRadius.circular(18),
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
              // Extra headroom when the milestone tag sits in the corner.
              padding: EdgeInsets.fromLTRB(
                14,
                yearsLabel != null ? 30 : 14,
                14,
                14,
              ),
              child: Row(
                children: [
                  _DayBox(
                    label: dayLabel,
                    sub: daySub,
                    theme: theme,
                    isToday: isToday,
                    todayIcon: _kindIcon(event.kind),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 7),
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
                                dateText,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (desc.detail != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              desc.detail!,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: cs.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _MiniChip(
                              icon: event.eventType.icon,
                              label: event.eventType.displayName,
                              color: event.eventType.color,
                            ),
                            const SizedBox(width: 6),
                            _MiniChip(
                              icon: event.isYearly
                                  ? Icons.autorenew_rounded
                                  : Icons.calendar_today_rounded,
                              label: event.isYearly ? 'Yearly' : 'One time',
                              color: event.isYearly
                                  ? Colors.green
                                  : Colors.blueGrey,
                            ),
                          ],
                        ),
                        if (event.notes != null && event.notes!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              event.notes!,
                              style: TextStyle(
                                fontSize: 11.5,
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
                  const SizedBox(width: 4),
                  Icon(
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

  const _KindTheme({
    required this.primary,
    required this.secondary,
    required this.watermark,
  });

  static _KindTheme of(DaysCounterEvent event) {
    switch (event.kind) {
      case DaysCounterEventKind.birthday:
        return const _KindTheme(
          primary: Color(0xFFF06292), // pink
          secondary: Color(0xFFFFB74D), // amber
          watermark: Icons.cake_rounded,
        );
      case DaysCounterEventKind.wedding:
        return const _KindTheme(
          primary: Color(0xFFC2185B), // deep rose
          secondary: Color(0xFFD4AF37), // gold
          watermark: Icons.favorite_rounded,
        );
      case DaysCounterEventKind.memorial:
        return const _KindTheme(
          primary: Color(0xFF546E7A), // slate
          secondary: Color(0xFF90A4AE),
          watermark: Icons.local_florist_rounded,
        );
      case DaysCounterEventKind.festival:
        return const _KindTheme(
          primary: Color(0xFFFF7043), // orange
          secondary: Color(0xFF7E57C2), // violet
          watermark: Icons.celebration_rounded,
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

/// The big count on the left: "12 / days to go". On the day itself it
/// swaps to the kind's icon with TODAY underneath.
class _DayBox extends StatelessWidget {
  final String label;
  final String sub;
  final _KindTheme theme;
  final bool isToday;
  final IconData todayIcon;

  const _DayBox({
    required this.label,
    required this.sub,
    required this.theme,
    required this.isToday,
    required this.todayIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 82,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [theme.primary, theme.secondary],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: theme.primary.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          if (isToday)
            Icon(todayIcon, size: 30, color: Colors.white)
          else
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                  height: 1.05,
                ),
              ),
            ),
          const SizedBox(height: 3),
          Text(
            isToday ? 'TODAY' : sub,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: isToday ? 10 : 10,
              fontWeight: FontWeight.w700,
              letterSpacing: isToday ? 1.0 : 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// The milestone pill: "Turning 24", "4th wedding anniversary".
class _MilestoneBadge extends StatelessWidget {
  final String text;
  final IconData icon;
  final _KindTheme theme;
  final bool emphasized;

  /// True when the badge is the card's top-right corner tag: only the
  /// bottom-left corner is rounded so it hugs the card edge.
  final bool corner;

  const _MilestoneBadge({
    required this.text,
    required this.icon,
    required this.theme,
    this.emphasized = false,
    this.corner = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: corner
          ? EdgeInsets.fromLTRB(12, emphasized ? 6 : 5, 14, emphasized ? 7 : 6)
          : EdgeInsets.symmetric(
              horizontal: emphasized ? 12 : 10,
              vertical: emphasized ? 6 : 5,
            ),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [theme.primary, theme.secondary]),
        borderRadius: corner
            ? const BorderRadius.only(bottomLeft: Radius.circular(14))
            : BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.primary.withValues(alpha: 0.30),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: emphasized ? 16 : 14, color: Colors.white),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white,
                fontSize: emphasized ? 14 : 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Small tinted chip for the type and recurrence.
class _MiniChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MiniChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
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

  /// Confirms, deletes through the cubit and returns to the list. The list
  /// receives no result, so it does not try to update the removed event.
  Future<void> _delete(BuildContext context, DaysCounterCubit cubit) async {
    final event = widget.existing;
    if (event == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Delete event'),
        content: Text('Remove "${event.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(d, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    cubit.deleteEvent(event.id);
    Navigator.pop(context);
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
        actions: [
          if (_isEditing)
            IconButton(
              tooltip: 'Delete event',
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () => _delete(context, cubit),
            ),
        ],
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
                if (_isEditing) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => _delete(context, cubit),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(
                        color: Colors.red.withValues(alpha: 0.5),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Delete Event'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
