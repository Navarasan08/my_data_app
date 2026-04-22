import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:my_data_app/src/notifications/model/app_notification.dart';
import 'package:my_data_app/src/notifications/cubit/notification_cubit.dart';
import 'package:my_data_app/src/notifications/cubit/notification_state.dart';

class NotificationsPage extends StatelessWidget {
  /// Called when the user taps a notification — receives the notification so
  /// the host (MainShell) can route to the right module.
  final void Function(AppNotification n)? onOpen;

  const NotificationsPage({super.key, this.onOpen});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationCubit, NotificationState>(
      builder: (context, state) {
        final cubit = context.read<NotificationCubit>();
        final items = cubit.sorted;
        final unread = cubit.unreadCount;

        return Scaffold(
          backgroundColor: const Color(0xFFF0F4F8),
          appBar: AppBar(
            title: const Text('Notifications'),
            centerTitle: true,
            elevation: 0,
            actions: [
              if (unread > 0)
                IconButton(
                  icon: const Icon(Icons.mark_email_read_rounded),
                  tooltip: 'Mark all read',
                  onPressed: cubit.markAllRead,
                ),
              if (items.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_sweep_rounded),
                  tooltip: 'Clear all',
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Clear all notifications'),
                        content: const Text(
                            'Remove every notification from this list?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: TextButton.styleFrom(
                                foregroundColor: Colors.red),
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) cubit.clearAll();
                  },
                ),
            ],
          ),
          body: items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off_rounded,
                          size: 56, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text(
                        'You\'re all caught up',
                        style: TextStyle(
                            fontSize: 14, color: Colors.grey[500]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'New reminders will appear here',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
                  itemCount: items.length,
                  itemBuilder: (ctx, i) => _NotificationTile(
                    notification: items[i],
                    onTap: () {
                      cubit.markRead(items[i].id);
                      onOpen?.call(items[i]);
                    },
                    onDismiss: () => cubit.dismiss(items[i].id),
                  ),
                ),
        );
      },
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  String _ago(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('d MMM').format(t);
  }

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final color = n.severity.color;

    return Dismissible(
      key: ValueKey(n.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: Colors.red[100],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.delete_rounded, color: Colors.red[700]),
      ),
      onDismissed: (_) => onDismiss(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: n.isRead ? Colors.grey[50] : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: n.isRead ? Colors.grey[200]! : color.withValues(alpha: 0.4),
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(n.severity.icon, size: 16, color: color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              n.title,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: n.isRead
                                    ? FontWeight.w500
                                    : FontWeight.w700,
                                color: n.isRead
                                    ? Colors.grey[700]
                                    : Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!n.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(left: 6, top: 4),
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      if (n.body.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          n.body,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            height: 1.3,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              n.sourceModule.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: color,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _ago(n.createdAt),
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ],
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
