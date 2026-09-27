import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:my_data_app/src/quick_notes/cubit/quick_note_cubit.dart';
import 'package:my_data_app/src/quick_notes/cubit/quick_note_state.dart';
import 'package:my_data_app/src/quick_notes/model/quick_note.dart';
import 'package:my_data_app/src/shell/app_drawer.dart';

/// Quick Notes tab: notes and checklists, pinned ones first, with search,
/// swipe-to-pin / swipe-to-delete, and a distraction-free editor.
class QuickNotesPage extends StatelessWidget {
  const QuickNotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QuickNoteCubit, QuickNoteState>(
      builder: (context, state) {
        final cubit = context.read<QuickNoteCubit>();
        final notes = cubit.filtered;
        final pinned = notes.where((n) => n.pinned).toList();
        final others = notes.where((n) => !n.pinned).toList();
        final cs = Theme.of(context).colorScheme;
        final searching = state.search.trim().isNotEmpty;

        return Scaffold(
          appBar: AppBar(
            leading: const ShellMenuButton(),
            title: const Text('Quick Notes'),
            centerTitle: false,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(58),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: _SearchField(onChanged: cubit.setSearch),
                  ),
                  if (!state.isLive)
                    const LinearProgressIndicator(minHeight: 2),
                ],
              ),
            ),
          ),
          body: notes.isEmpty
              ? _Empty(searching: searching, loading: state.isLoading)
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  children: [
                    if (pinned.isNotEmpty) ...[
                      _SectionHeader(
                        icon: Icons.push_pin_rounded,
                        title: 'Pinned',
                        count: pinned.length,
                      ),
                      ...pinned.map((n) => _NoteCard(note: n, cubit: cubit)),
                      const SizedBox(height: 8),
                    ],
                    if (others.isNotEmpty) ...[
                      if (pinned.isNotEmpty || searching)
                        _SectionHeader(
                          icon: Icons.notes_rounded,
                          title: searching ? 'Results' : 'Notes',
                          count: others.length,
                        ),
                      ...others.map((n) => _NoteCard(note: n, cubit: cubit)),
                    ],
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '${notes.length} ${notes.length == 1 ? 'note' : 'notes'}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'quick_notes_fab',
            onPressed: () => _newNote(context, cubit),
            icon: const Icon(Icons.edit_rounded),
            label: const Text('New'),
          ),
        );
      },
    );
  }

  Future<void> _newNote(BuildContext context, QuickNoteCubit cubit) async {
    final cs = Theme.of(context).colorScheme;
    final checklist = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: _NewChoice(
                  icon: Icons.notes_rounded,
                  color: cs.primary,
                  title: 'Note',
                  subtitle: 'Free text',
                  onTap: () => Navigator.pop(context, false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _NewChoice(
                  icon: Icons.checklist_rounded,
                  color: Colors.teal,
                  title: 'Checklist',
                  subtitle: 'Tick things off',
                  onTap: () => Navigator.pop(context, true),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (checklist == null || !context.mounted) return;
    _openEditor(context, cubit, cubit.newNote(checklist: checklist));
  }
}

class _NewChoice extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _NewChoice({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Column(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final ValueChanged<String> onChanged;
  const _SearchField({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 40,
      child: TextField(
        onChanged: onChanged,
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          hintText: 'Search',
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 20,
            color: cs.onSurfaceVariant,
          ),
          isDense: true,
          contentPadding: EdgeInsets.zero,
          filled: true,
          fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.6),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final int count;
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Row(
        children: [
          Icon(icon, size: 14, color: cs.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 6),
          Text('$count', style: TextStyle(fontSize: 11, color: cs.outline)),
        ],
      ),
    );
  }
}

void _openEditor(BuildContext context, QuickNoteCubit cubit, QuickNote note) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: QuickNoteEditorPage(note: note),
      ),
    ),
  );
}

class _Empty extends StatelessWidget {
  final bool searching;
  final bool loading;
  const _Empty({required this.searching, required this.loading});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (loading) return const Center(child: CircularProgressIndicator());
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                searching
                    ? Icons.search_off_rounded
                    : Icons.sticky_note_2_outlined,
                size: 40,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              searching ? 'Nothing matches' : 'Your notes live here',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              searching
                  ? 'Try a different word.'
                  : 'Jot a thought or start a checklist.\nPinned notes stay at the top.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Relative time for the card footer: "Just now", "12 min", "3h", "Yesterday",
/// then a short date.
String _relativeTime(DateTime t) {
  final now = DateTime.now();
  final d = now.difference(t);
  if (d.inMinutes < 1) return 'Just now';
  if (d.inMinutes < 60) return '${d.inMinutes} min ago';
  if (d.inHours < 24 && now.day == t.day) return '${d.inHours}h ago';
  final yesterday = DateTime(now.year, now.month, now.day - 1);
  if (t.year == yesterday.year &&
      t.month == yesterday.month &&
      t.day == yesterday.day) {
    return 'Yesterday';
  }
  if (d.inDays < 7) return DateFormat('EEEE').format(t);
  return DateFormat(t.year == now.year ? 'd MMM' : 'd MMM yyyy').format(t);
}

class _NoteCard extends StatelessWidget {
  final QuickNote note;
  final QuickNoteCubit cubit;
  const _NoteCard({required this.note, required this.cubit});

  Future<bool> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Delete note?'),
        content: Text('"${note.displayTitle}" will be removed.'),
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
    return ok == true;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = note.hasChecklist ? Colors.teal : cs.primary;
    final preview = note.preview;
    final visibleItems = note.items.take(4).toList();
    final progress = note.items.isEmpty
        ? 0.0
        : note.doneCount / note.items.length;

    return Dismissible(
      key: ValueKey('note_${note.id}'),
      // Swipe right → pin/unpin (no confirmation), swipe left → delete.
      background: _SwipeBackground(
        alignment: Alignment.centerLeft,
        color: cs.primary,
        icon: note.pinned ? Icons.push_pin_outlined : Icons.push_pin_rounded,
        label: note.pinned ? 'Unpin' : 'Pin',
      ),
      secondaryBackground: const _SwipeBackground(
        alignment: Alignment.centerRight,
        color: Colors.red,
        icon: Icons.delete_outline_rounded,
        label: 'Delete',
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          cubit.togglePin(note.id);
          return false; // keep the card; it just moves section
        }
        final ok = await _confirmDelete(context);
        if (ok) cubit.delete(note.id);
        return ok;
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: note.pinned
                ? cs.primary.withValues(alpha: 0.4)
                : cs.outlineVariant,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _openEditor(context, cubit, note),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Accent stripe: blue for notes, teal for checklists.
                Container(width: 4, color: accent.withValues(alpha: 0.9)),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              note.hasChecklist
                                  ? Icons.checklist_rounded
                                  : Icons.notes_rounded,
                              size: 16,
                              color: accent,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                note.displayTitle,
                                style: const TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (note.pinned)
                              Icon(
                                Icons.push_pin_rounded,
                                size: 15,
                                color: cs.primary,
                              ),
                          ],
                        ),
                        if (preview.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            preview,
                            style: TextStyle(
                              fontSize: 13,
                              color: cs.onSurfaceVariant,
                              height: 1.35,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (note.hasChecklist) ...[
                          const SizedBox(height: 8),
                          ...visibleItems.map(
                            (i) => _ItemLine(
                              item: i,
                              accent: accent,
                              onTap: () => cubit.toggleItem(note.id, i.id),
                            ),
                          ),
                          if (note.items.length > visibleItems.length)
                            Padding(
                              padding: const EdgeInsets.only(left: 30, top: 2),
                              child: Text(
                                '+${note.items.length - visibleItems.length} more',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 4,
                              backgroundColor: accent.withValues(alpha: 0.12),
                              valueColor: AlwaysStoppedAnimation(accent),
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 12,
                              color: cs.outline,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _relativeTime(note.updatedAt),
                              style: TextStyle(
                                fontSize: 11,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                            if (note.hasChecklist) ...[
                              const Spacer(),
                              Text(
                                '${note.doneCount} of ${note.items.length} done',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: progress == 1
                                      ? accent
                                      : cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
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

class _ItemLine extends StatelessWidget {
  final NoteItem item;
  final Color accent;
  final VoidCallback onTap;
  const _ItemLine({
    required this.item,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            _CheckCircle(done: item.done, accent: accent, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.text,
                style: TextStyle(
                  fontSize: 13.5,
                  color: item.done ? cs.outline : cs.onSurface,
                  decoration: item.done ? TextDecoration.lineThrough : null,
                  decorationColor: cs.outline,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Animated round checkbox shared by the list and the editor.
class _CheckCircle extends StatelessWidget {
  final bool done;
  final Color accent;
  final double size;
  const _CheckCircle({
    required this.done,
    required this.accent,
    this.size = 22,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? accent : Colors.transparent,
        border: Border.all(color: done ? accent : cs.outline, width: 1.6),
      ),
      child: done
          ? Icon(Icons.check_rounded, size: size * 0.7, color: Colors.white)
          : null,
    );
  }
}

class _SwipeBackground extends StatelessWidget {
  final Alignment alignment;
  final Color color;
  final IconData icon;
  final String label;
  const _SwipeBackground({
    required this.alignment,
    required this.color,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: alignment,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Editor ──────────────────────────────────────────────────────────────────

/// Full-screen editor. Saves automatically when the user leaves, and
/// discards a note that is still empty, like a notes app should.
class QuickNoteEditorPage extends StatefulWidget {
  final QuickNote note;
  const QuickNoteEditorPage({super.key, required this.note});

  @override
  State<QuickNoteEditorPage> createState() => _QuickNoteEditorPageState();
}

class _QuickNoteEditorPageState extends State<QuickNoteEditorPage> {
  late final TextEditingController _title;
  late final TextEditingController _body;
  late List<_ItemRow> _items;
  late bool _pinned;
  bool _deleted = false;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.note.title);
    _body = TextEditingController(text: widget.note.body);
    _items = widget.note.items.map(_ItemRow.fromItem).toList();
    _pinned = widget.note.pinned;
    // A brand-new checklist opens with the cursor in its first line.
    if (widget.note.items.length == 1 && widget.note.items.first.text.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _items.isNotEmpty) _items.first.focus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    for (final r in _items) {
      r.dispose();
    }
    super.dispose();
  }

  QuickNote _current() => widget.note.copyWith(
    title: _title.text,
    body: _body.text,
    items: _items.map((r) => r.toItem()).toList(),
    pinned: _pinned,
  );

  void _save() {
    if (_deleted) return;
    context.read<QuickNoteCubit>().save(_current());
  }

  void _addItem({int? after}) {
    final row = _ItemRow.empty();
    setState(() {
      if (after == null) {
        _items.add(row);
      } else {
        _items.insert(after + 1, row);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => row.focus.requestFocus(),
    );
  }

  void _removeItem(int index) {
    final row = _items[index];
    setState(() => _items.removeAt(index));
    row.dispose();
  }

  void _clearDone() {
    final doomed = _items.where((r) => r.done).toList();
    setState(() => _items.removeWhere((r) => r.done));
    for (final r in doomed) {
      r.dispose();
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Delete note?'),
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
    if (ok != true || !mounted) return;
    _deleted = true;
    context.read<QuickNoteCubit>().delete(widget.note.id);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isChecklist = _items.isNotEmpty;
    final accent = isChecklist ? Colors.teal : cs.primary;
    final done = _items.where((r) => r.done).length;

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _save();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isChecklist ? 'Checklist' : 'Note',
                style: const TextStyle(fontSize: 17),
              ),
              Text(
                'Edited ${_relativeTime(widget.note.updatedAt).toLowerCase()}',
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: _pinned ? 'Unpin' : 'Pin',
              icon: Icon(
                _pinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                color: _pinned ? cs.primary : null,
              ),
              onPressed: () => setState(() => _pinned = !_pinned),
            ),
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'clear_done') _clearDone();
                if (v == 'delete') _delete();
              },
              itemBuilder: (_) => [
                if (isChecklist && done > 0)
                  const PopupMenuItem(
                    value: 'clear_done',
                    child: Text('Remove ticked items'),
                  ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete note'),
                ),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            if (isChecklist)
              LinearProgressIndicator(
                value: _items.isEmpty ? 0 : done / _items.length,
                minHeight: 3,
                backgroundColor: accent.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation(accent),
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                children: [
                  TextField(
                    controller: _title,
                    textCapitalization: TextCapitalization.sentences,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Title',
                      hintStyle: TextStyle(color: cs.outline),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (var i = 0; i < _items.length; i++)
                    _ChecklistRow(
                      row: _items[i],
                      accent: accent,
                      onToggle: () =>
                          setState(() => _items[i].done = !_items[i].done),
                      onSubmitted: () => _addItem(after: i),
                      onRemove: () => _removeItem(i),
                      onEmptyBackspace: () {
                        if (_items.length > 1) _removeItem(i);
                      },
                    ),
                  if (isChecklist)
                    InkWell(
                      onTap: () => _addItem(),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.add_circle_outline_rounded,
                              size: 22,
                              color: accent,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Add item',
                              style: TextStyle(
                                color: accent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (isChecklist) const SizedBox(height: 12),
                  TextField(
                    controller: _body,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: null,
                    minLines: isChecklist ? 2 : 14,
                    keyboardType: TextInputType.multiline,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                    decoration: InputDecoration(
                      hintText: isChecklist ? 'Add a note…' : 'Start writing…',
                      hintStyle: TextStyle(color: cs.outline),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
            // Bottom toolbar: sits above the keyboard.
            _EditorToolbar(
              isChecklist: isChecklist,
              accent: accent,
              onAddItem: () => _addItem(),
              onDelete: _delete,
              summary: isChecklist ? '$done of ${_items.length} done' : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _EditorToolbar extends StatelessWidget {
  final bool isChecklist;
  final Color accent;
  final VoidCallback onAddItem;
  final VoidCallback onDelete;
  final String? summary;
  const _EditorToolbar({
    required this.isChecklist,
    required this.accent,
    required this.onAddItem,
    required this.onDelete,
    this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.fromLTRB(
        8,
        4,
        8,
        4 + MediaQuery.of(context).viewPadding.bottom,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: onAddItem,
            icon: Icon(Icons.add_task_rounded, color: accent),
            label: Text(
              isChecklist ? 'Add item' : 'Add checklist',
              style: TextStyle(color: accent, fontWeight: FontWeight.w600),
            ),
          ),
          const Spacer(),
          if (summary != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                summary!,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
            ),
          IconButton(
            tooltip: 'Delete',
            onPressed: onDelete,
            icon: Icon(
              Icons.delete_outline_rounded,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemRow {
  final String id;
  final TextEditingController controller;
  final FocusNode focus;
  bool done;

  _ItemRow({required this.id, required String text, required this.done})
    : controller = TextEditingController(text: text),
      focus = FocusNode();

  factory _ItemRow.fromItem(NoteItem i) =>
      _ItemRow(id: i.id, text: i.text, done: i.done);

  factory _ItemRow.empty() => _ItemRow(
    id: '${DateTime.now().microsecondsSinceEpoch}',
    text: '',
    done: false,
  );

  NoteItem toItem() =>
      NoteItem(id: id, text: controller.text.trim(), done: done);

  void dispose() {
    controller.dispose();
    focus.dispose();
  }
}

class _ChecklistRow extends StatelessWidget {
  final _ItemRow row;
  final Color accent;
  final VoidCallback onToggle;
  final VoidCallback onSubmitted;
  final VoidCallback onRemove;
  final VoidCallback onEmptyBackspace;
  const _ChecklistRow({
    required this.row,
    required this.accent,
    required this.onToggle,
    required this.onSubmitted,
    required this.onRemove,
    required this.onEmptyBackspace,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          InkWell(
            onTap: onToggle,
            customBorder: const CircleBorder(),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: _CheckCircle(done: row.done, accent: accent),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: TextField(
              controller: row.controller,
              focusNode: row.focus,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => onSubmitted(),
              onChanged: (v) {
                // Backspace on an empty line removes it, like Notes does.
                if (v.isEmpty && row.controller.text.isEmpty) return;
              },
              style: TextStyle(
                fontSize: 16,
                height: 1.4,
                color: row.done ? cs.outline : cs.onSurface,
                decoration: row.done ? TextDecoration.lineThrough : null,
                decorationColor: cs.outline,
              ),
              decoration: InputDecoration(
                hintText: 'List item',
                hintStyle: TextStyle(color: cs.outline),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Remove',
            onPressed: onRemove,
            icon: Icon(Icons.close_rounded, size: 18, color: cs.outline),
          ),
        ],
      ),
    );
  }
}
