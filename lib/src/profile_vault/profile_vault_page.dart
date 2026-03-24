import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:my_data_app/src/profile_vault/model/profile_vault_model.dart';
import 'package:my_data_app/src/profile_vault/cubit/profile_vault_cubit.dart';
import 'package:my_data_app/src/profile_vault/cubit/profile_vault_state.dart';

// ─── 1. ProfileVaultHomePage ─────────────────────────────────────────────────

class ProfileVaultHomePage extends StatelessWidget {
  const ProfileVaultHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileVaultCubit, ProfileVaultState>(
      builder: (context, state) {
        final cubit = context.read<ProfileVaultCubit>();
        final favorites = cubit.favorites;
        final counts = cubit.sectionCounts;

        return Scaffold(
          appBar: AppBar(
            title: const Text('My Details'),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.search_rounded),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: cubit,
                      child: const _SearchPage(),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: [
              // Favorites section
              if (favorites.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 6, top: 4),
                  child: Text(
                    'Favorites',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                ...favorites.map((e) => _EntryCard(entry: e)),
                const SizedBox(height: 10),
                Divider(color: Colors.grey.shade200, height: 1),
                const SizedBox(height: 10),
              ],
              // Section tiles
              ...VaultSection.values.map(
                (section) => _SectionTile(
                  section: section,
                  count: counts[section] ?? 0,
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddSectionSheet(context, cubit),
            child: const Icon(Icons.add_rounded),
          ),
        );
      },
    );
  }

  void _showAddSectionSheet(BuildContext context, ProfileVaultCubit cubit) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(14),
              child: Text(
                'Add new entry',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: VaultSection.values.map((section) {
                  return ListTile(
                    dense: true,
                    leading:
                        Icon(section.icon, color: section.color, size: 22),
                    title: Text(section.label,
                        style: const TextStyle(fontSize: 14)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BlocProvider.value(
                            value: cubit,
                            child: AddEntryPage(section: section),
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Section Tile ────────────────────────────────────────────────────────────

class _SectionTile extends StatelessWidget {
  final VaultSection section;
  final int count;

  const _SectionTile({required this.section, required this.count});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ProfileVaultCubit>();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: cubit,
              child: SectionDetailPage(section: section),
            ),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border:
                Border(left: BorderSide(color: section.color, width: 3)),
            color: section.color.withAlpha(10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(section.icon, color: section.color, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  section.label,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
              if (count > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: section.color.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: section.color,
                    ),
                  ),
                ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded,
                  color: Colors.grey.shade400, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── 2. SectionDetailPage ────────────────────────────────────────────────────

class SectionDetailPage extends StatelessWidget {
  final VaultSection section;

  const SectionDetailPage({super.key, required this.section});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ProfileVaultCubit>();

    return BlocBuilder<ProfileVaultCubit, ProfileVaultState>(
      builder: (context, state) {
        final entries = cubit.entriesForSection(section);

        return Scaffold(
          appBar: AppBar(
            title: Text(section.label),
            actions: [
              if (entries.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.share_rounded, size: 20),
                  tooltip: 'Share all',
                  onPressed: () {
                    final text = cubit.shareableTextForSection(section);
                    SharePlus.instance.share(ShareParams(text: text));
                  },
                ),
              IconButton(
                icon: const Icon(Icons.add_rounded),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: cubit,
                      child: AddEntryPage(section: section),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: entries.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(section.icon,
                          size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text(
                        'Add your first ${section.label}',
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 14),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: entries.length,
                  itemBuilder: (_, i) => _EntryCard(entry: entries[i]),
                ),
          floatingActionButton: FloatingActionButton.small(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: cubit,
                  child: AddEntryPage(section: section),
                ),
              ),
            ),
            child: const Icon(Icons.add_rounded),
          ),
        );
      },
    );
  }
}

// ─── 3. _EntryCard ───────────────────────────────────────────────────────────

class _EntryCard extends StatelessWidget {
  final VaultEntry entry;

  const _EntryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ProfileVaultCubit>();
    final section = entry.section;
    final nonEmpty = entry.fields.entries
        .where((e) => e.value.isNotEmpty)
        .take(2)
        .map((e) => '${e.key}: ${e.value}')
        .join('  \u2022  ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: cubit,
              child: EntryDetailPage(entryId: entry.id),
            ),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border:
                Border(left: BorderSide(color: section.color, width: 3)),
            color: section.color.withAlpha(10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(section.icon, color: section.color, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    if (nonEmpty.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          nonEmpty,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => cubit.toggleFavorite(entry.id),
                child: Icon(
                  entry.isFavorite
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  color:
                      entry.isFavorite ? Colors.amber : Colors.grey.shade400,
                  size: 20,
                ),
              ),
              const SizedBox(width: 4),
              _moreMenu(context, cubit),
            ],
          ),
        ),
      ),
    );
  }

  Widget _moreMenu(BuildContext context, ProfileVaultCubit cubit) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert_rounded,
          size: 18, color: Colors.grey.shade500),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'share', child: Text('Share')),
        PopupMenuItem(value: 'edit', child: Text('Edit')),
        PopupMenuItem(value: 'delete', child: Text('Delete')),
      ],
      onSelected: (val) {
        switch (val) {
          case 'share':
            SharePlus.instance.share(ShareParams(text: entry.toShareableText()));
          case 'edit':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: cubit,
                  child: AddEntryPage(
                      section: entry.section, existingEntry: entry),
                ),
              ),
            );
          case 'delete':
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Delete entry?'),
                content: Text('Remove "${entry.title}" permanently?'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel')),
                  TextButton(
                    onPressed: () {
                      cubit.deleteEntry(entry.id);
                      Navigator.pop(ctx);
                    },
                    child: const Text('Delete',
                        style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );
        }
      },
    );
  }
}

// ─── 4. EntryDetailPage ──────────────────────────────────────────────────────

class EntryDetailPage extends StatefulWidget {
  final String entryId;

  const EntryDetailPage({super.key, required this.entryId});

  @override
  State<EntryDetailPage> createState() => _EntryDetailPageState();
}

class _EntryDetailPageState extends State<EntryDetailPage> {
  final Set<String> _revealedKeys = {};

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ProfileVaultCubit>();

    return BlocBuilder<ProfileVaultCubit, ProfileVaultState>(
      builder: (context, state) {
        final entry = cubit.getEntryById(widget.entryId);
        if (entry == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Entry not found')),
          );
        }

        final section = entry.section;
        final filledFields = entry.fields.entries
            .where((e) => e.value.isNotEmpty)
            .toList();

        return Scaffold(
          appBar: AppBar(
            title: Text(entry.title),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_rounded, size: 20),
                tooltip: 'Share',
                onPressed: () {
                  SharePlus.instance.share(ShareParams(text: entry.toShareableText()));
                },
              ),
              IconButton(
                icon: const Icon(Icons.edit_rounded, size: 20),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: cubit,
                      child: AddEntryPage(
                          section: section, existingEntry: entry),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                onPressed: () => _confirmDelete(context, cubit, entry),
              ),
            ],
          ),
          body: ListView(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            children: [
              ...filledFields.map((f) {
                final sensitive = _isSensitive(f.key);
                final revealed = _revealedKeys.contains(f.key);
                return _FieldTile(
                  label: f.key,
                  value: f.value,
                  isSensitive: sensitive,
                  isRevealed: revealed,
                  onToggleReveal: sensitive
                      ? () => setState(() {
                            if (revealed) {
                              _revealedKeys.remove(f.key);
                            } else {
                              _revealedKeys.add(f.key);
                            }
                          })
                      : null,
                );
              }),
              const SizedBox(height: 16),
              // Share selected button
              if (filledFields.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () =>
                      _showSelectiveShareSheet(context, entry),
                  icon: const Icon(Icons.checklist_rounded, size: 18),
                  label: const Text('Share Selected Fields'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              const SizedBox(height: 20),
              // Timestamps
              Text(
                'Created: ${DateFormat('dd MMM yyyy, hh:mm a').format(entry.createdAt)}',
                style:
                    TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 2),
              Text(
                'Updated: ${DateFormat('dd MMM yyyy, hh:mm a').format(entry.updatedAt)}',
                style:
                    TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  bool _isSensitive(String key) {
    final lower = key.toLowerCase();
    return lower.contains('password') || lower.contains('pin');
  }

  void _confirmDelete(
      BuildContext context, ProfileVaultCubit cubit, VaultEntry entry) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete entry?'),
        content: Text('Remove "${entry.title}" permanently?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              cubit.deleteEntry(entry.id);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child:
                const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showSelectiveShareSheet(BuildContext context, VaultEntry entry) {
    final filledKeys = entry.fields.entries
        .where((e) => e.value.isNotEmpty)
        .map((e) => e.key)
        .toList();
    final selected = Set<String>.from(filledKeys);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Select fields to share',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ...filledKeys.map((key) => CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(key,
                          style: const TextStyle(fontSize: 13)),
                      subtitle: Text(
                        entry.fields[key]!,
                        style: const TextStyle(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      value: selected.contains(key),
                      onChanged: (val) {
                        setSheetState(() {
                          if (val == true) {
                            selected.add(key);
                          } else {
                            selected.remove(key);
                          }
                        });
                      },
                    )),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: selected.isEmpty
                      ? null
                      : () {
                          final text = entry.toShareableText(
                            selectedKeys: selected.toList(),
                          );
                          Navigator.pop(ctx);
                          SharePlus.instance.share(ShareParams(text: text));
                        },
                  icon: const Icon(Icons.share_rounded, size: 18),
                  label: const Text('Share Selected'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── 5. _FieldTile ───────────────────────────────────────────────────────────

class _FieldTile extends StatelessWidget {
  final String label;
  final String value;
  final bool isSensitive;
  final bool isRevealed;
  final VoidCallback? onToggleReveal;

  const _FieldTile({
    required this.label,
    required this.value,
    this.isSensitive = false,
    this.isRevealed = false,
    this.onToggleReveal,
  });

  @override
  Widget build(BuildContext context) {
    final displayValue = isSensitive && !isRevealed
        ? '\u2022' * value.length.clamp(4, 12)
        : value;

    return InkWell(
      onTap: () => _copyValue(context),
      onLongPress: () {
        SharePlus.instance.share(ShareParams(text: '$label: $value'));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 1),
                  Text(displayValue,
                      style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
            if (isSensitive)
              GestureDetector(
                onTap: onToggleReveal,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8, top: 6),
                  child: Icon(
                    isRevealed
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    size: 18,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
            GestureDetector(
              onTap: () => _copyValue(context),
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Icon(Icons.copy_rounded,
                    size: 16, color: Colors.grey.shade400),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copyValue(BuildContext context) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied $label'),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}

// ─── 6. AddEntryPage ─────────────────────────────────────────────────────────

class AddEntryPage extends StatefulWidget {
  final VaultSection section;
  final VaultEntry? existingEntry;

  const AddEntryPage(
      {super.key, required this.section, this.existingEntry});

  @override
  State<AddEntryPage> createState() => _AddEntryPageState();
}

class _AddEntryPageState extends State<AddEntryPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final Map<String, TextEditingController> _fieldControllers;
  final Set<String> _obscuredFields = {};
  bool get _isEdit => widget.existingEntry != null;

  @override
  void initState() {
    super.initState();
    final entry = widget.existingEntry;
    _titleController = TextEditingController(text: entry?.title ?? '');

    final fields = VaultTemplate.fieldsFor(widget.section);
    _fieldControllers = {
      for (final f in fields)
        f: TextEditingController(text: entry?.fields[f] ?? ''),
    };

    for (final f in fields) {
      if (_isSensitiveField(f)) _obscuredFields.add(f);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    for (final c in _fieldControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  bool _isSensitiveField(String label) {
    final lower = label.toLowerCase();
    return lower.contains('password') || lower.contains('pin');
  }

  List<String>? _dropdownOptions(String label) {
    if (label == 'ID Type') return VaultTemplate.govtIdTypes;
    if (label == 'Card Type') return VaultTemplate.cardTypes;
    if (label == 'Account Type') return VaultTemplate.accountTypes;
    if (label == 'Policy Type') return VaultTemplate.insuranceTypes;
    if (label == 'Gender') return ['Male', 'Female', 'Other'];
    if (label == 'Blood Group') {
      return ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
    }
    return null;
  }

  bool _isDateField(String label) =>
      label.toLowerCase().contains('date');

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ProfileVaultCubit>();
    final fields = VaultTemplate.fieldsFor(widget.section);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit
            ? 'Edit ${widget.existingEntry!.title}'
            : 'Add ${widget.section.label}'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title *',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            ...fields.map((f) => _buildField(f)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _save(cubit),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(_isEdit ? 'Update' : 'Save'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label) {
    final dropdown = _dropdownOptions(label);
    final isDate = _isDateField(label);
    final isSensitive = _isSensitiveField(label);
    final controller = _fieldControllers[label]!;

    if (dropdown != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: DropdownButtonFormField<String>(
          initialValue: controller.text.isNotEmpty &&
                  dropdown.contains(controller.text)
              ? controller.text
              : null,
          decoration: InputDecoration(
            labelText: label,
            isDense: true,
            border: const OutlineInputBorder(),
          ),
          items: dropdown
              .map((d) => DropdownMenuItem(
                  value: d,
                  child: Text(d, style: const TextStyle(fontSize: 14))))
              .toList(),
          onChanged: (val) => controller.text = val ?? '',
        ),
      );
    }

    if (isDate) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextFormField(
          controller: controller,
          readOnly: true,
          decoration: InputDecoration(
            labelText: label,
            isDense: true,
            border: const OutlineInputBorder(),
            suffixIcon:
                const Icon(Icons.calendar_today_rounded, size: 18),
          ),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime(2100),
            );
            if (picked != null) {
              controller.text =
                  DateFormat('dd/MM/yyyy').format(picked);
            }
          },
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        obscureText: isSensitive && _obscuredFields.contains(label),
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: const OutlineInputBorder(),
          suffixIcon: isSensitive
              ? GestureDetector(
                  onTap: () {
                    setState(() {
                      if (_obscuredFields.contains(label)) {
                        _obscuredFields.remove(label);
                      } else {
                        _obscuredFields.add(label);
                      }
                    });
                  },
                  child: Icon(
                    _obscuredFields.contains(label)
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    size: 18,
                  ),
                )
              : null,
        ),
      ),
    );
  }

  void _save(ProfileVaultCubit cubit) {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final fields = <String, String>{};
    for (final e in _fieldControllers.entries) {
      if (e.value.text.trim().isNotEmpty) {
        fields[e.key] = e.value.text.trim();
      }
    }

    if (_isEdit) {
      cubit.updateEntry(widget.existingEntry!.copyWith(
        title: _titleController.text.trim(),
        fields: fields,
        updatedAt: now,
      ));
    } else {
      cubit.addEntry(VaultEntry(
        id: now.microsecondsSinceEpoch.toString(),
        section: widget.section,
        title: _titleController.text.trim(),
        fields: fields,
        createdAt: now,
        updatedAt: now,
      ));
    }

    Navigator.pop(context);
  }
}

// ─── 7. _SearchPage ──────────────────────────────────────────────────────────

class _SearchPage extends StatefulWidget {
  const _SearchPage();

  @override
  State<_SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<_SearchPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ProfileVaultCubit>();

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search entries...',
            border: InputBorder.none,
          ),
          onChanged: (val) => setState(() => _query = val),
        ),
      ),
      body: _query.trim().isEmpty
          ? Center(
              child: Text(
                'Type to search across all entries',
                style: TextStyle(
                    color: Colors.grey.shade500, fontSize: 14),
              ),
            )
          : _buildResults(cubit),
    );
  }

  Widget _buildResults(ProfileVaultCubit cubit) {
    final results = cubit.search(_query);
    if (results.isEmpty) {
      return Center(
        child: Text(
          'No results found',
          style:
              TextStyle(color: Colors.grey.shade500, fontSize: 14),
        ),
      );
    }

    // Group by section
    final grouped = <VaultSection, List<VaultEntry>>{};
    for (final e in results) {
      grouped.putIfAbsent(e.section, () => []).add(e);
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      children: grouped.entries.expand((group) {
        return [
          Padding(
            padding:
                const EdgeInsets.only(left: 4, top: 8, bottom: 4),
            child: Text(
              group.key.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: group.key.color,
              ),
            ),
          ),
          ...group.value.map((e) => _EntryCard(entry: e)),
        ];
      }).toList(),
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────
