import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:my_data_app/src/pregnancy/cubit/pregnancy_cubit.dart';
import 'package:my_data_app/src/pregnancy/cubit/pregnancy_state.dart';
import 'package:my_data_app/src/pregnancy/model/pregnancy_guide.dart';
import 'package:my_data_app/src/pregnancy/model/pregnancy_model.dart';

final _dateFmt = DateFormat('d MMM yyyy');
final _shortDateFmt = DateFormat('d MMM');

/// Pregnancy Assist: week-by-week progress, the antenatal checklist, a
/// wellbeing journal and plain-language guidance.
class PregnancyPage extends StatelessWidget {
  const PregnancyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PregnancyCubit, PregnancyState>(
      builder: (context, state) {
        final cubit = context.read<PregnancyCubit>();
        if (state.isLoading) {
          return Scaffold(
            appBar: AppBar(title: const Text('Pregnancy Assist')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (!cubit.isTracking) return _SetupView(cubit: cubit);
        return _TrackingView(cubit: cubit, state: state);
      },
    );
  }
}

// ─── Setup ───────────────────────────────────────────────────────────────────

class _SetupView extends StatelessWidget {
  final PregnancyCubit cubit;
  const _SetupView({required this.cubit});

  Future<void> _pickLmp(BuildContext context) async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: now.subtract(const Duration(days: 42)),
      firstDate: now.subtract(const Duration(days: 300)),
      lastDate: now,
      helpText: 'First day of your last period',
    );
    if (d != null) cubit.startPregnancy(lmpDate: d);
  }

  Future<void> _pickDue(BuildContext context) async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 200)),
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 300)),
      helpText: 'Due date given by your doctor',
    );
    if (d != null) cubit.startPregnancy(dueDate: d);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasHistory =
        cubit.state.checks.isNotEmpty || cubit.state.logs.isNotEmpty;
    return Scaffold(
      appBar: AppBar(title: const Text('Pregnancy Assist')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.pink.shade300, Colors.deepPurple.shade300],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: const [
                Icon(
                  Icons.pregnant_woman_rounded,
                  size: 64,
                  color: Colors.white,
                ),
                SizedBox(height: 12),
                Text(
                  'Track every check-up, scan and vaccine, log how you feel, '
                  'and learn what to expect each week.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'To get started, tell us one date:',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          _SetupOption(
            icon: Icons.calendar_today_rounded,
            title: 'First day of my last period',
            subtitle: 'We count 40 weeks from there',
            onTap: () => _pickLmp(context),
          ),
          const SizedBox(height: 10),
          _SetupOption(
            icon: Icons.event_rounded,
            title: 'My due date from the doctor',
            subtitle: 'Usually from a dating scan; the most accurate',
            onTap: () => _pickDue(context),
          ),
          if (hasHistory) ...[
            const SizedBox(height: 24),
            Text(
              'Previous pregnancy data is still saved. Starting again keeps '
              'the checklist and journal; use Reset in the menu to clear them.',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
            TextButton.icon(
              onPressed: () => _confirmReset(context, cubit),
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Reset saved data'),
            ),
          ],
          const SizedBox(height: 24),
          Text(
            pregnancyDisclaimer,
            style: TextStyle(fontSize: 11, color: cs.outline),
          ),
        ],
      ),
    );
  }
}

class _SetupOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _SetupOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(14),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: CircleAvatar(
          backgroundColor: Colors.pink.withValues(alpha: 0.12),
          child: Icon(icon, color: Colors.pink),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

Future<void> _confirmReset(BuildContext context, PregnancyCubit cubit) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (d) => AlertDialog(
      title: const Text('Reset pregnancy data?'),
      content: const Text(
        'The checklist, journal and dates will be deleted. This cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(d, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(d, true),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Reset'),
        ),
      ],
    ),
  );
  if (ok == true) cubit.resetAll();
}

// ─── Tracking ────────────────────────────────────────────────────────────────

class _TrackingView extends StatefulWidget {
  final PregnancyCubit cubit;
  final PregnancyState state;
  const _TrackingView({required this.cubit, required this.state});

  @override
  State<_TrackingView> createState() => _TrackingViewState();
}

class _TrackingViewState extends State<_TrackingView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this)
      ..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _onMenu(String action) async {
    final cubit = widget.cubit;
    switch (action) {
      case 'dates':
        await _editDates(context, cubit);
        break;
      case 'end':
        final ok = await showDialog<bool>(
          context: context,
          builder: (d) => AlertDialog(
            title: const Text('Stop tracking?'),
            content: const Text(
              'Your checklist and journal stay saved; only the active pregnancy is closed.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(d, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(d, true),
                child: const Text('Stop'),
              ),
            ],
          ),
        );
        if (ok == true) cubit.endPregnancy();
        break;
      case 'reset':
        await _confirmReset(context, cubit);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = widget.cubit;
    final showFab = _tabs.index == 1 || _tabs.index == 2;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pregnancy Assist'),
        centerTitle: false,
        actions: [
          PopupMenuButton<String>(
            onSelected: _onMenu,
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'dates', child: Text('Edit dates')),
              PopupMenuItem(value: 'end', child: Text('Stop tracking')),
              PopupMenuItem(value: 'reset', child: Text('Reset all data')),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Checklist'),
            Tab(text: 'Journal'),
            Tab(text: 'Learn'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _OverviewTab(cubit: cubit, onOpenTab: (i) => _tabs.animateTo(i)),
          _ChecklistTab(cubit: cubit),
          _JournalTab(cubit: cubit),
          _LearnTab(cubit: cubit),
        ],
      ),
      floatingActionButton: showFab
          ? FloatingActionButton.extended(
              onPressed: () => _tabs.index == 1
                  ? _openCheckEditor(context, cubit)
                  : _openLogEditor(context, cubit),
              icon: const Icon(Icons.add),
              label: Text(_tabs.index == 1 ? 'Add item' : 'Log today'),
            )
          : null,
    );
  }
}

Future<void> _editDates(BuildContext context, PregnancyCubit cubit) async {
  final profile = cubit.profile;
  final choice = await showModalBottomSheet<String>(
    context: context,
    builder: (_) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.calendar_today_rounded),
            title: const Text('Change last period date'),
            subtitle: Text(
              profile.lmpDate == null
                  ? 'Not set'
                  : _dateFmt.format(profile.lmpDate!),
            ),
            onTap: () => Navigator.pop(context, 'lmp'),
          ),
          ListTile(
            leading: const Icon(Icons.event_rounded),
            title: const Text('Set due date from doctor'),
            subtitle: Text(
              profile.dueDateOverride == null
                  ? 'Not set (calculated from last period)'
                  : _dateFmt.format(profile.dueDateOverride!),
            ),
            onTap: () => Navigator.pop(context, 'due'),
          ),
          if (profile.dueDateOverride != null)
            ListTile(
              leading: const Icon(Icons.undo_rounded),
              title: const Text('Use last period date instead'),
              onTap: () => Navigator.pop(context, 'clearDue'),
            ),
        ],
      ),
    ),
  );
  if (choice == null || !context.mounted) return;
  final now = DateTime.now();
  switch (choice) {
    case 'lmp':
      final d = await showDatePicker(
        context: context,
        initialDate: profile.lmpDate ?? now.subtract(const Duration(days: 42)),
        firstDate: now.subtract(const Duration(days: 320)),
        lastDate: now,
      );
      if (d != null) cubit.updateProfile(profile.copyWith(lmpDate: d));
      break;
    case 'due':
      final d = await showDatePicker(
        context: context,
        initialDate: profile.dueDate ?? now.add(const Duration(days: 200)),
        firstDate: now.subtract(const Duration(days: 30)),
        lastDate: now.add(const Duration(days: 300)),
      );
      if (d != null) cubit.updateProfile(profile.copyWith(dueDateOverride: d));
      break;
    case 'clearDue':
      cubit.updateProfile(profile.copyWith(clearDueDateOverride: true));
      break;
  }
}

// ─── Overview ────────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final PregnancyCubit cubit;
  final void Function(int tab) onOpenTab;
  const _OverviewTab({required this.cubit, required this.onOpenTab});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final week = cubit.currentWeek;
    final guide = PregnancyWeekGuide.forWeek(week);
    final overdue = cubit.overdueChecks;
    final upcoming = cubit.upcomingChecks();
    final due = cubit.dueDate;
    final daysToGo = cubit.daysToGo;
    final total = cubit.state.checks.length;
    final done = cubit.completedCount;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // Hero
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.pink.shade400, Colors.deepPurple.shade400],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Week $week',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'day ${cubit.currentDayOfWeek + 1}',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const Spacer(),
                  _Pill(text: _trimesterLabel(cubit.trimester)),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: cubit.progress,
                  minHeight: 8,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _HeroStat(
                      label: 'Due date',
                      value: due == null ? '—' : _dateFmt.format(due),
                    ),
                  ),
                  Expanded(
                    child: _HeroStat(
                      label: daysToGo >= 0 ? 'Days to go' : 'Days past due',
                      value: '${daysToGo.abs()}',
                    ),
                  ),
                  Expanded(
                    child: _HeroStat(
                      label: 'Checks done',
                      value: '$done / $total',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Baby this week
        _Card(
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.pink.withValues(alpha: 0.12),
                child: const Icon(
                  Icons.child_care_rounded,
                  color: Colors.pink,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About the size of a ${guide.babySize.toLowerCase()}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      guide.baby,
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                    TextButton(
                      onPressed: () => onOpenTab(3),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 32),
                      ),
                      child: const Text('Read this week\'s guide'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        if (overdue.isNotEmpty) ...[
          const SizedBox(height: 12),
          _Card(
            color: Colors.orange.withValues(alpha: 0.10),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${overdue.length} ${overdue.length == 1 ? 'item is' : 'items are'} past '
                    'their recommended week. Tick them off or ask your doctor.',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                TextButton(
                  onPressed: () => onOpenTab(1),
                  child: const Text('View'),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 18),
        _SectionTitle(
          title: 'Coming up',
          action: 'All items',
          onAction: () => onOpenTab(1),
        ),
        if (upcoming.isEmpty)
          _Card(
            child: Text(
              'Nothing pending. Enjoy the calm.',
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          )
        else
          ...upcoming.map(
            (c) => _CheckTile(
              item: c,
              currentWeek: week,
              cubit: cubit,
              compact: true,
            ),
          ),

        const SizedBox(height: 18),
        _SectionTitle(title: 'How are you today?'),
        _Card(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  cubit.latestLog == null
                      ? 'No journal entries yet. A quick note a few times a week helps you and your doctor spot patterns.'
                      : 'Last entry ${_shortDateFmt.format(cubit.latestLog!.date)}'
                            '${cubit.latestLog!.weightKg != null ? ' · ${cubit.latestLog!.weightKg} kg' : ''}'
                            '${cubit.latestLog!.hasBp ? ' · BP ${cubit.latestLog!.bpLabel}' : ''}',
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: () => _openLogEditor(context, cubit),
                child: const Text('Log'),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),
        _Card(
          color: Colors.red.withValues(alpha: 0.06),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.emergency_rounded, color: Colors.red),
            title: const Text(
              'When to call the doctor',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: const Text('Warning signs that need same-day attention'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showWarningSigns(context),
          ),
        ),
      ],
    );
  }
}

String _trimesterLabel(int t) => switch (t) {
  1 => '1st trimester',
  2 => '2nd trimester',
  _ => '3rd trimester',
};

void _showWarningSigns(BuildContext context) {
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (_) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          const Text(
            'Call your doctor or go to the hospital if you notice:',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 10),
          ...pregnancyWarningSigns.map(
            (s) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.circle, size: 8, color: Colors.red),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      s,
                      style: const TextStyle(fontSize: 14, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// ─── Checklist ───────────────────────────────────────────────────────────────

class _ChecklistTab extends StatelessWidget {
  final PregnancyCubit cubit;
  const _ChecklistTab({required this.cubit});

  @override
  Widget build(BuildContext context) {
    final week = cubit.currentWeek;
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        for (final t in [1, 2, 3]) ...[
          Builder(
            builder: (_) {
              final items = cubit.checksForTrimester(t);
              final done = items.where((c) => c.done).length;
              final isCurrent = cubit.trimester == t;
              return Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 6),
                child: Row(
                  children: [
                    Text(
                      _trimesterLabel(t),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: isCurrent ? Colors.pink : cs.onSurface,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isCurrent) const _Pill(text: 'now', dark: true),
                    const Spacer(),
                    Text(
                      '$done / ${items.length}',
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          ...cubit
              .checksForTrimester(t)
              .map((c) => _CheckTile(item: c, currentWeek: week, cubit: cubit)),
        ],
        const SizedBox(height: 16),
        Text(
          pregnancyDisclaimer,
          style: TextStyle(fontSize: 11, color: cs.outline),
        ),
      ],
    );
  }
}

class _CheckTile extends StatelessWidget {
  final PregnancyCheckItem item;
  final int currentWeek;
  final PregnancyCubit cubit;
  final bool compact;
  const _CheckTile({
    required this.item,
    required this.currentWeek,
    required this.cubit,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final overdue = item.isOverdueAt(currentWeek);
    final current = item.isCurrentAt(currentWeek);
    final color = item.category.color;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: item.done
            ? cs.surfaceContainerLow
            : overdue
            ? Colors.orange.withValues(alpha: 0.08)
            : cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: current
              ? Colors.pink.withValues(alpha: 0.5)
              : cs.outlineVariant,
          width: current ? 1.4 : 1,
        ),
      ),
      child: ListTile(
        onTap: () => cubit.toggleCheck(item.id),
        onLongPress: () => _openCheckEditor(context, cubit, existing: item),
        leading: Checkbox(
          value: item.done,
          onChanged: (_) => cubit.toggleCheck(item.id),
          activeColor: Colors.pink,
        ),
        title: Text(
          item.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: item.done ? TextDecoration.lineThrough : null,
            color: item.done ? cs.onSurfaceVariant : cs.onSurface,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _Chip(
                icon: item.category.icon,
                label: item.category.label,
                color: color,
              ),
              _Chip(
                icon: Icons.schedule_rounded,
                label: item.done && item.doneDate != null
                    ? 'Done ${_shortDateFmt.format(item.doneDate!)}'
                    : item.windowLabel,
                color: overdue
                    ? Colors.orange
                    : (current ? Colors.pink : Colors.blueGrey),
              ),
              if (!compact && item.description.isNotEmpty)
                Text(
                  item.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
            ],
          ),
        ),
        trailing: compact
            ? null
            : const Icon(Icons.more_vert_rounded, size: 18),
      ),
    );
  }
}

Future<void> _openCheckEditor(
  BuildContext context,
  PregnancyCubit cubit, {
  PregnancyCheckItem? existing,
}) async {
  final result = await showModalBottomSheet<_CheckEditorResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _CheckEditorSheet(existing: existing),
  );
  if (result == null) return;
  if (result.delete && existing != null) {
    cubit.deleteCheck(existing.id);
  } else if (result.item != null) {
    existing == null
        ? cubit.addCheck(result.item!)
        : cubit.updateCheck(result.item!);
  }
}

class _CheckEditorResult {
  final PregnancyCheckItem? item;
  final bool delete;
  const _CheckEditorResult({this.item, this.delete = false});
}

class _CheckEditorSheet extends StatefulWidget {
  final PregnancyCheckItem? existing;
  const _CheckEditorSheet({this.existing});

  @override
  State<_CheckEditorSheet> createState() => _CheckEditorSheetState();
}

class _CheckEditorSheetState extends State<_CheckEditorSheet> {
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _notes;
  late PregnancyCheckCategory _category;
  late RangeValues _weeks;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?.title ?? '');
    _description = TextEditingController(text: e?.description ?? '');
    _notes = TextEditingController(text: e?.notes ?? '');
    _category = e?.category ?? PregnancyCheckCategory.custom;
    _weeks = RangeValues(
      (e?.fromWeek ?? 20).toDouble(),
      (e?.toWeek ?? 22).toDouble(),
    );
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _save() {
    final title = _title.text.trim();
    if (title.isEmpty) return;
    final base =
        widget.existing ??
        PregnancyCheckItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: title,
          category: _category,
          fromWeek: _weeks.start.round(),
          toWeek: _weeks.end.round(),
          isCustom: true,
          order: 999,
        );
    Navigator.pop(
      context,
      _CheckEditorResult(
        item: base.copyWith(
          title: title,
          description: _description.text.trim(),
          category: _category,
          fromWeek: _weeks.start.round(),
          toWeek: _weeks.end.round(),
          notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              editing ? 'Edit item' : 'New checklist item',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<PregnancyCheckCategory>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: PregnancyCheckCategory.values
                  .map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Row(
                        children: [
                          Icon(c.icon, size: 18, color: c.color),
                          const SizedBox(width: 8),
                          Text(c.label),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (c) => setState(() => _category = c ?? _category),
            ),
            const SizedBox(height: 12),
            Text(
              'Recommended window: weeks ${_weeks.start.round()}–${_weeks.end.round()}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            RangeSlider(
              values: _weeks,
              min: 1,
              max: 42,
              divisions: 41,
              labels: RangeLabels(
                '${_weeks.start.round()}',
                '${_weeks.end.round()}',
              ),
              onChanged: (v) => setState(() => _weeks = v),
            ),
            TextField(
              controller: _description,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notes,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (editing)
                  TextButton.icon(
                    onPressed: () => Navigator.pop(
                      context,
                      const _CheckEditorResult(delete: true),
                    ),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Delete'),
                  ),
                const Spacer(),
                FilledButton(
                  onPressed: _save,
                  child: Text(editing ? 'Save' : 'Add'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Journal ─────────────────────────────────────────────────────────────────

class _JournalTab extends StatelessWidget {
  final PregnancyCubit cubit;
  const _JournalTab({required this.cubit});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final logs = cubit.sortedLogs;
    final latest = cubit.latestLog;
    final change = cubit.weightChange;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        _Card(
          child: Row(
            children: [
              Expanded(
                child: _Stat(
                  label: 'Weight',
                  value: latest?.weightKg == null
                      ? '—'
                      : '${latest!.weightKg} kg',
                  hint: change == null
                      ? null
                      : '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)} kg overall',
                ),
              ),
              Expanded(
                child: _Stat(
                  label: 'Blood pressure',
                  value: latest?.hasBp == true ? latest!.bpLabel : '—',
                ),
              ),
              Expanded(
                child: _Stat(label: 'Entries', value: '${logs.length}'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (logs.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 48),
            child: Column(
              children: [
                Icon(Icons.edit_note_rounded, size: 48, color: cs.outline),
                const SizedBox(height: 8),
                Text(
                  'No entries yet. Tap "Log today" to start.',
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          )
        else
          ...logs.map((l) => _LogCard(log: l, cubit: cubit)),
      ],
    );
  }
}

class _LogCard extends StatelessWidget {
  final PregnancyLog log;
  final PregnancyCubit cubit;
  const _LogCard({required this.log, required this.cubit});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final week = cubit.profile.weekOn(log.date);
    final bits = <String>[
      if (log.weightKg != null) '${log.weightKg} kg',
      if (log.hasBp) 'BP ${log.bpLabel}',
      if (log.kicks != null) '${log.kicks} kicks',
      if (log.mood != null) log.mood!,
    ];
    return _Card(
      onTap: () => _openLogEditor(context, cubit, existing: log),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _dateFmt.format(log.date),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 8),
              _Pill(text: 'wk $week', dark: true),
              const Spacer(),
              Icon(Icons.edit_rounded, size: 16, color: cs.outline),
            ],
          ),
          if (bits.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              bits.join(' · '),
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
            ),
          ],
          if (log.symptoms.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: log.symptoms
                  .map(
                    (s) =>
                        _Chip(icon: Icons.circle, label: s, color: Colors.pink),
                  )
                  .toList(),
            ),
          ],
          if (log.notes != null && log.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(log.notes!, style: const TextStyle(fontSize: 13, height: 1.3)),
          ],
        ],
      ),
    );
  }
}

Future<void> _openLogEditor(
  BuildContext context,
  PregnancyCubit cubit, {
  PregnancyLog? existing,
}) async {
  final result = await showModalBottomSheet<_LogEditorResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _LogEditorSheet(existing: existing),
  );
  if (result == null) return;
  if (result.delete && existing != null) {
    cubit.deleteLog(existing.id);
  } else if (result.log != null) {
    existing == null ? cubit.addLog(result.log!) : cubit.updateLog(result.log!);
  }
}

class _LogEditorResult {
  final PregnancyLog? log;
  final bool delete;
  const _LogEditorResult({this.log, this.delete = false});
}

class _LogEditorSheet extends StatefulWidget {
  final PregnancyLog? existing;
  const _LogEditorSheet({this.existing});

  @override
  State<_LogEditorSheet> createState() => _LogEditorSheetState();
}

class _LogEditorSheetState extends State<_LogEditorSheet> {
  late DateTime _date;
  late final TextEditingController _weight;
  late final TextEditingController _sys;
  late final TextEditingController _dia;
  late final TextEditingController _kicks;
  late final TextEditingController _notes;
  late Set<String> _symptoms;
  String? _mood;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    final now = DateTime.now();
    _date = e?.date ?? DateTime(now.year, now.month, now.day);
    _weight = TextEditingController(text: e?.weightKg?.toString() ?? '');
    _sys = TextEditingController(text: e?.bpSystolic?.toString() ?? '');
    _dia = TextEditingController(text: e?.bpDiastolic?.toString() ?? '');
    _kicks = TextEditingController(text: e?.kicks?.toString() ?? '');
    _notes = TextEditingController(text: e?.notes ?? '');
    _symptoms = {...?e?.symptoms};
    _mood = e?.mood;
  }

  @override
  void dispose() {
    for (final c in [_weight, _sys, _dia, _kicks, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    final id =
        widget.existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    Navigator.pop(
      context,
      _LogEditorResult(
        log: PregnancyLog(
          id: id,
          date: _date,
          weightKg: double.tryParse(_weight.text.trim()),
          bpSystolic: int.tryParse(_sys.text.trim()),
          bpDiastolic: int.tryParse(_dia.text.trim()),
          symptoms: _symptoms.toList(),
          mood: _mood,
          kicks: int.tryParse(_kicks.text.trim()),
          notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  editing ? 'Edit entry' : 'How are you today?',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 320),
                      ),
                      lastDate: DateTime.now(),
                    );
                    if (d != null) setState(() => _date = d);
                  },
                  icon: const Icon(Icons.calendar_today_rounded, size: 16),
                  label: Text(_dateFmt.format(_date)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _weight,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Weight (kg)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _sys,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'BP high',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _dia,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'BP low',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'Symptoms',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: PregnancyLog.symptomOptions
                  .map(
                    (s) => FilterChip(
                      label: Text(s),
                      selected: _symptoms.contains(s),
                      onSelected: (v) => setState(
                        () => v ? _symptoms.add(s) : _symptoms.remove(s),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 14),
            const Text('Mood', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: PregnancyLog.moodOptions
                  .map(
                    (m) => ChoiceChip(
                      label: Text(m),
                      selected: _mood == m,
                      onSelected: (_) =>
                          setState(() => _mood = _mood == m ? null : m),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _kicks,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Kicks counted (optional, from week 28)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notes,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (editing)
                  TextButton.icon(
                    onPressed: () => Navigator.pop(
                      context,
                      const _LogEditorResult(delete: true),
                    ),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Delete'),
                  ),
                const Spacer(),
                FilledButton(onPressed: _save, child: const Text('Save')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Learn ───────────────────────────────────────────────────────────────────

class _LearnTab extends StatefulWidget {
  final PregnancyCubit cubit;
  const _LearnTab({required this.cubit});

  @override
  State<_LearnTab> createState() => _LearnTabState();
}

class _LearnTabState extends State<_LearnTab> {
  late int _week = widget.cubit.currentWeek.clamp(1, 40);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final guide = PregnancyWeekGuide.forWeek(_week);
    final isNow = _week == widget.cubit.currentWeek;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: _week > 1 ? () => setState(() => _week--) : null,
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Week $_week',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          isNow
                              ? 'this week'
                              : _trimesterLabel(
                                  PregnancyProfile.trimesterOf(_week),
                                ),
                          style: TextStyle(
                            fontSize: 12,
                            color: isNow ? Colors.pink : cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _week < 40
                        ? () => setState(() => _week++)
                        : null,
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
              if (!isNow)
                Center(
                  child: TextButton(
                    onPressed: () => setState(
                      () => _week = widget.cubit.currentWeek.clamp(1, 40),
                    ),
                    child: const Text('Back to this week'),
                  ),
                ),
              const Divider(),
              _GuideRow(
                icon: Icons.child_care_rounded,
                title: 'Baby · size of a ${guide.babySize.toLowerCase()}',
                body: guide.baby,
              ),
              _GuideRow(
                icon: Icons.favorite_rounded,
                title: 'You',
                body: guide.mother,
              ),
              _GuideRow(
                icon: Icons.lightbulb_rounded,
                title: 'Tip',
                body: guide.tip,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _SectionTitle(title: 'Trimester guides'),
        ...PregnancyTrimesterGuide.all.map(
          (t) => _Card(
            padding: EdgeInsets.zero,
            child: ExpansionTile(
              initiallyExpanded: t.trimester == widget.cubit.trimester,
              title: Text(
                t.title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(t.weeks),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                Text(t.summary, style: const TextStyle(height: 1.4)),
                const SizedBox(height: 8),
                ...t.focus.map(
                  (f) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: Colors.pink,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            f,
                            style: const TextStyle(fontSize: 13, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        _SectionTitle(title: 'Eating well'),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Reach for',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.green,
                ),
              ),
              ...pregnancyNutritionDo.map(
                (s) => _Bullet(text: s, color: Colors.green),
              ),
              const SizedBox(height: 10),
              const Text(
                'Avoid',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.red,
                ),
              ),
              ...pregnancyNutritionAvoid.map(
                (s) => _Bullet(text: s, color: Colors.red),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _SectionTitle(title: 'When to call the doctor'),
        _Card(
          color: Colors.red.withValues(alpha: 0.06),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: pregnancyWarningSigns
                .map((s) => _Bullet(text: s, color: Colors.red))
                .toList(),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          pregnancyDisclaimer,
          style: TextStyle(fontSize: 11, color: cs.outline),
        ),
      ],
    );
  }
}

class _GuideRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const _GuideRow({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.pink),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Small shared widgets ────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  final Color? color;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  const _Card({
    required this.child,
    this.color,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: color ?? cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const _SectionTitle({required this.title, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const Spacer(),
          if (action != null)
            TextButton(onPressed: onAction, child: Text(action!)),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final bool dark;
  const _Pill({required this.text, this.dark = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: dark ? Colors.pink.withValues(alpha: 0.12) : Colors.white24,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: dark ? Colors.pink : Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Chip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
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
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;
  const _HeroStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final String? hint;
  const _Stat({required this.label, required this.value, this.hint});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        if (hint != null)
          Text(
            hint!,
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
          ),
      ],
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  final Color color;
  const _Bullet({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, size: 7, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
