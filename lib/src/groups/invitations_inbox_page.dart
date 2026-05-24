import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:my_data_app/src/groups/cubit/group_cubit.dart';
import 'package:my_data_app/src/groups/cubit/group_state.dart';
import 'package:my_data_app/src/groups/model/group_model.dart';

/// Lists invitations addressed to the current user. Tapping Accept runs the
/// repo's accept-invitation transaction (which atomically adds the user to
/// the group + writes a membership index doc). Decline just flips the
/// invitation's status.
class InvitationsInboxPage extends StatelessWidget {
  const InvitationsInboxPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Group invitations'),
        elevation: 0,
      ),
      body: BlocBuilder<GroupCubit, GroupState>(
        builder: (context, state) {
          final invites = state.pendingInvitations;
          if (invites.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mark_email_read_rounded,
                      size: 44, color: cs.outlineVariant),
                  const SizedBox(height: 10),
                  Text('No pending invitations',
                      style: TextStyle(
                          fontSize: 13, color: cs.onSurfaceVariant)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: invites.length,
            itemBuilder: (ctx, i) => _InvitationCard(invitation: invites[i]),
          );
        },
      ),
    );
  }
}

class _InvitationCard extends StatefulWidget {
  final GroupInvitation invitation;
  const _InvitationCard({required this.invitation});

  @override
  State<_InvitationCard> createState() => _InvitationCardState();
}

class _InvitationCardState extends State<_InvitationCard> {
  bool _busy = false;

  Future<void> _accept() async {
    setState(() => _busy = true);
    try {
      await context
          .read<GroupCubit>()
          .acceptInvitation(widget.invitation);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Joined "${widget.invitation.groupName}"')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not accept: $e')),
        );
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _decline() async {
    setState(() => _busy = true);
    try {
      await context
          .read<GroupCubit>()
          .declineInvitation(widget.invitation);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not decline: $e')),
        );
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final inv = widget.invitation;
    final color = GroupFund.availableColors[
        inv.groupColorIndex.clamp(0, GroupFund.availableColors.length - 1)];
    final icon = GroupFund.availableIcons[
        inv.groupIconIndex.clamp(0, GroupFund.availableIcons.length - 1)];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
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
                child: Icon(icon, size: 22, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(inv.groupName,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      'Invited by ${inv.invitedByName} · ${DateFormat('d MMM').format(inv.createdAt)}',
                      style: TextStyle(
                          fontSize: 11, color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy ? null : _decline,
                  child: const Text('Decline'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: color),
                  onPressed: _busy ? null : _accept,
                  child: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Accept'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
