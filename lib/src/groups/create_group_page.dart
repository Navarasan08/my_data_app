import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_data_app/src/groups/cubit/group_cubit.dart';
import 'package:my_data_app/src/groups/model/group_model.dart';

/// Two-step group creation:
///  1. name + icon + color
///  2. (optional) seed invitations by email
///
/// We create the group first (so the user can come back later to invite),
/// then send invitations in parallel. Each invite that succeeds shows a tick;
/// failures surface inline so the user can edit and retry.
class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _emailInput = TextEditingController();
  int _iconIndex = 18;
  int _colorIndex = 0;
  final List<String> _pendingEmails = [];
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _emailInput.dispose();
    super.dispose();
  }

  static final _emailRegex =
      RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

  void _addEmail() {
    final raw = _emailInput.text.trim().toLowerCase();
    if (raw.isEmpty) return;
    if (!_emailRegex.hasMatch(raw)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid email')),
      );
      return;
    }
    if (_pendingEmails.contains(raw)) {
      _emailInput.clear();
      return;
    }
    setState(() {
      _pendingEmails.add(raw);
      _emailInput.clear();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final cubit = context.read<GroupCubit>();
    try {
      final group = await cubit.createGroup(
        name: _name.text.trim(),
        description: _description.text.trim().isEmpty
            ? null
            : _description.text.trim(),
        iconIndex: _iconIndex,
        colorIndex: _colorIndex,
      );

      // Best-effort invites — ignore individual failures so the group still
      // gets created even if one address is bogus.
      final failures = <String>[];
      for (final email in _pendingEmails) {
        try {
          await cubit.invite(groupId: group.id, email: email);
        } catch (e) {
          failures.add(email);
        }
      }
      if (mounted) {
        if (failures.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Created. Could not invite: ${failures.join(", ")}')),
          );
        }
        Navigator.pop(context, group);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create group: $e')),
        );
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = GroupFund.availableColors[_colorIndex];
    final icon = GroupFund.availableIcons[_iconIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Group'),
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
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, size: 42, color: color),
                  ),
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: 'Group Name *',
                    hintText: 'e.g. Goa Trip, Roommates, Office Lunch',
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
                  children:
                      List.generate(GroupFund.availableIcons.length, (i) {
                    final selected = i == _iconIndex;
                    return InkWell(
                      onTap: () => setState(() => _iconIndex = i),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: selected
                              ? color.withValues(alpha: 0.15)
                              : cs.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(10),
                          border: selected
                              ? Border.all(color: color, width: 2)
                              : null,
                        ),
                        child: Icon(
                          GroupFund.availableIcons[i],
                          size: 22,
                          color:
                              selected ? color : cs.onSurfaceVariant,
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
                  children: List.generate(GroupFund.availableColors.length,
                      (i) {
                    final c = GroupFund.availableColors[i];
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
                const SizedBox(height: 24),

                Text('Invite People (optional)',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _emailInput,
                        decoration: const InputDecoration(
                          hintText: 'friend@example.com',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        keyboardType: TextInputType.emailAddress,
                        onFieldSubmitted: (_) => _addEmail(),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton.filled(
                      onPressed: _addEmail,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                if (_pendingEmails.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _pendingEmails
                        .map((e) => Chip(
                              label: Text(e,
                                  style: const TextStyle(fontSize: 12)),
                              onDeleted: () => setState(
                                  () => _pendingEmails.remove(e)),
                            ))
                        .toList(),
                  ),
                ],
                const SizedBox(height: 28),

                ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Create Group',
                          style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
