import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:my_data_app/src/chits/model/chit_model.dart';
import 'package:my_data_app/src/chits/cubit/chit_cubit.dart';
import 'package:my_data_app/src/chits/cubit/chit_state.dart';

export 'package:my_data_app/src/chits/model/chit_model.dart';

// Chit Fund List Page
class ChitFundListPage extends StatelessWidget {
  const ChitFundListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: BlocBuilder<ChitCubit, ChitState>(
        builder: (context, state) {
          final cubit = context.read<ChitCubit>();
          final ownerChits = cubit.getByRole(ChitRole.owner);
          final participantChits = cubit.getByRole(ChitRole.participant);

          return Scaffold(
            appBar: AppBar(
              title: const Text('Chit Fund Manager'),
              centerTitle: true,
              elevation: 0,
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'My Chits', icon: Icon(Icons.star_rounded, size: 20)),
                  Tab(text: 'Participating', icon: Icon(Icons.group_work_rounded, size: 20)),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                // Owner tab
                _ChitListView(
                  chitFunds: ownerChits,
                  emptyMessage: 'No chit groups created yet',
                  emptySubMessage: 'Tap the + button to create your first chit group',
                  itemBuilder: (chitFund) => ChitFundCard(
                    chitFund: chitFund,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BlocProvider.value(
                            value: cubit,
                            child: ChitFundDetailsPage(chitFundId: chitFund.id),
                          ),
                        ),
                      );
                    },
                    onEdit: () async {
                      final editedChitFund = await Navigator.push<ChitFund>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddChitFundPage(chitFund: chitFund),
                        ),
                      );
                      if (editedChitFund != null) {
                        cubit.updateChitFund(editedChitFund);
                      }
                    },
                    onDelete: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Chit Group'),
                          content: Text(
                              'Are you sure you want to delete "${chitFund.name}"? All members and auction records will also be deleted.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        cubit.deleteChitFund(chitFund.id);
                      }
                    },
                  ),
                ),
                // Participant tab
                _ChitListView(
                  chitFunds: participantChits,
                  emptyMessage: 'Not participating in any chit funds',
                  emptySubMessage: 'Tap the + button to join a chit fund',
                  itemBuilder: (chitFund) => _ParticipantChitCard(
                    chitFund: chitFund,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BlocProvider.value(
                            value: cubit,
                            child: ParticipantChitDetailPage(chitFundId: chitFund.id),
                          ),
                        ),
                      );
                    },
                    onDelete: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Remove Chit Fund'),
                          content: Text(
                              'Are you sure you want to remove "${chitFund.name}" from your list?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                              child: const Text('Remove'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        cubit.deleteChitFund(chitFund.id);
                      }
                    },
                  ),
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () => _showAddOptions(context, cubit),
              child: const Icon(Icons.add),
            ),
          );
        },
      ),
    );
  }

  void _showAddOptions(BuildContext context, ChitCubit cubit) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Add Chit Fund',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.star_rounded, color: Colors.deepPurple),
                  ),
                  title: const Text('Create Chit Group (as Owner)'),
                  subtitle: const Text('Start and manage your own chit fund'),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    final newChitFund = await Navigator.push<ChitFund>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddChitFundPage(initialRole: ChitRole.owner),
                      ),
                    );
                    if (newChitFund != null) {
                      cubit.addChitFund(newChitFund);
                    }
                  },
                ),
                const Divider(indent: 16, endIndent: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.group_work_rounded, color: Colors.teal),
                  ),
                  title: const Text('Join Chit Fund (as Participant)'),
                  subtitle: const Text('Track a chit fund you are participating in'),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    final newChitFund = await Navigator.push<ChitFund>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddChitFundPage(initialRole: ChitRole.participant),
                      ),
                    );
                    if (newChitFund != null) {
                      cubit.addChitFund(newChitFund);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ChitListView extends StatelessWidget {
  final List<ChitFund> chitFunds;
  final String emptyMessage;
  final String emptySubMessage;
  final Widget Function(ChitFund) itemBuilder;

  const _ChitListView({
    required this.chitFunds,
    required this.emptyMessage,
    required this.emptySubMessage,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (chitFunds.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_work_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              emptySubMessage,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: chitFunds.length,
      itemBuilder: (context, index) => itemBuilder(chitFunds[index]),
    );
  }
}

class _ParticipantChitCard extends StatelessWidget {
  final ChitFund chitFund;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ParticipantChitCard({
    required this.chitFund,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    switch (chitFund.status) {
      case ChitStatus.active:
        statusColor = Colors.green;
        break;
      case ChitStatus.completed:
        statusColor = Colors.blue;
        break;
      case ChitStatus.upcoming:
        statusColor = Colors.orange;
        break;
    }

    final nextPayment = chitFund.myNextPayment;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.group_work_rounded, size: 22, color: Colors.deepPurple),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chitFund.name,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (chitFund.organizerName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'By ${chitFund.organizerName}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _getStatusText(chitFund.status),
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${chitFund.myPaidCount}/${chitFund.durationMonths} paid',
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Monthly: ₹${chitFund.monthlyContribution.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  InkWell(
                    onTap: onDelete,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red[300]),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (nextPayment != null) ...[
                    Text(
                      'Due ${DateFormat('MMM dd').format(nextPayment.dueDate)}',
                      style: TextStyle(fontSize: 11, color: Colors.orange[700], fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '₹${nextPayment.amount.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.orange[800]),
                    ),
                  ] else
                    Text(
                      'All paid',
                      style: TextStyle(fontSize: 12, color: Colors.green[700], fontWeight: FontWeight.w600),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusText(ChitStatus status) {
    switch (status) {
      case ChitStatus.active:
        return 'Active';
      case ChitStatus.completed:
        return 'Completed';
      case ChitStatus.upcoming:
        return 'Upcoming';
    }
  }
}

class ChitFundCard extends StatelessWidget {
  final ChitFund chitFund;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ChitFundCard({
    Key? key,
    required this.chitFund,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  String _getStatusText() {
    switch (chitFund.status) {
      case ChitStatus.active:
        return 'Active';
      case ChitStatus.completed:
        return 'Completed';
      case ChitStatus.upcoming:
        return 'Upcoming';
    }
  }

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    switch (chitFund.status) {
      case ChitStatus.active:
        statusColor = Colors.green;
        break;
      case ChitStatus.completed:
        statusColor = Colors.blue;
        break;
      case ChitStatus.upcoming:
        statusColor = Colors.orange;
        break;
    }

    final memberProgress = chitFund.members.length / chitFund.totalMembers;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.group_work_rounded, size: 22, color: statusColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          chitFund.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _getStatusText(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: statusColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '₹${_formatAmount(chitFund.totalAmount)}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: onDelete,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red[300]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Members progress
              Row(
                children: [
                  Icon(Icons.people_outline_rounded, size: 14, color: Colors.grey[400]),
                  const SizedBox(width: 6),
                  Text(
                    '${chitFund.members.length}/${chitFund.totalMembers} members',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: memberProgress.clamp(0.0, 1.0),
                        minHeight: 4,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }
}

// Participant Chit Detail Page
class ParticipantChitDetailPage extends StatelessWidget {
  final String chitFundId;

  const ParticipantChitDetailPage({Key? key, required this.chitFundId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChitCubit, ChitState>(
      builder: (context, state) {
        final cubit = context.read<ChitCubit>();
        final chitFund = cubit.getChitFundById(chitFundId);

        if (chitFund == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Chit Fund')),
            body: const Center(child: Text('Chit fund not found')),
          );
        }

        final payments = chitFund.members.isNotEmpty ? chitFund.members.first.payments : <Payment>[];
        final paidCount = payments.where((p) => p.isPaid).length;
        final pendingCount = payments.where((p) => !p.isPaid).length;

        return Scaffold(
          appBar: AppBar(
            title: Text(chitFund.name),
            elevation: 0,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Summary card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Chit Details',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      _DetailRow(
                        label: 'Total Amount',
                        value: '₹${chitFund.totalAmount.toStringAsFixed(0)}',
                        icon: Icons.currency_rupee,
                      ),
                      _DetailRow(
                        label: 'Monthly Contribution',
                        value: '₹${chitFund.monthlyContribution.toStringAsFixed(0)}',
                        icon: Icons.payment,
                      ),
                      _DetailRow(
                        label: 'Duration',
                        value: '${chitFund.durationMonths} Months',
                        icon: Icons.calendar_month,
                      ),
                      _DetailRow(
                        label: 'Status',
                        value: _getStatusText(chitFund.status),
                        icon: Icons.info_outline,
                      ),
                      if (chitFund.organizerName != null)
                        _DetailRow(
                          label: 'Organizer',
                          value: chitFund.organizerName!,
                          icon: Icons.person,
                        ),
                      if (chitFund.organizerPhone != null)
                        _DetailRow(
                          label: 'Organizer Phone',
                          value: chitFund.organizerPhone!,
                          icon: Icons.phone,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Stats row
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Paid',
                      value: paidCount.toString(),
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatCard(
                      title: 'Pending',
                      value: pendingCount.toString(),
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatCard(
                      title: 'Paid ₹',
                      value: _formatCompact(chitFund.myTotalPaid),
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatCard(
                      title: 'Pending ₹',
                      value: _formatCompact(chitFund.myTotalPending),
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Auction win info
              if (chitFund.myMonthNumber != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.emoji_events_rounded, color: Colors.amber[800], size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Won auction in month ${chitFund.myMonthNumber} — received ₹${chitFund.myAuctionAmount?.toStringAsFixed(0) ?? '0'}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.amber[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Payment timeline
              const Text(
                'Payment Timeline',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (payments.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No payments recorded',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    ),
                  ),
                )
              else
                ...payments.map((payment) {
                  return _PaymentTimelineItem(
                    payment: payment,
                    onToggle: () => cubit.togglePayment(chitFundId, payment.id),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  String _getStatusText(ChitStatus status) {
    switch (status) {
      case ChitStatus.active:
        return 'Active';
      case ChitStatus.completed:
        return 'Completed';
      case ChitStatus.upcoming:
        return 'Upcoming';
    }
  }

  String _formatCompact(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(fontSize: 10, color: Colors.grey[700]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _PaymentTimelineItem extends StatelessWidget {
  final Payment payment;
  final VoidCallback onToggle;

  const _PaymentTimelineItem({
    required this.payment,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isPaid = payment.isPaid;
    final color = isPaid ? Colors.green : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${payment.monthNumber}',
                style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Month ${payment.monthNumber}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  '₹${payment.amount.toStringAsFixed(0)} - Due ${DateFormat('MMM dd, yyyy').format(payment.dueDate)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isPaid ? Colors.green[50] : Colors.orange[50],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isPaid ? 'Paid' : 'Pending',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isPaid ? Colors.green[700] : Colors.orange[700],
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isPaid ? Colors.green.withValues(alpha: 0.1) : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isPaid ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                size: 22,
                color: isPaid ? Colors.green : Colors.grey[400],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Add Chit Fund Page
class AddChitFundPage extends StatefulWidget {
  final ChitFund? chitFund;
  final ChitRole initialRole;

  const AddChitFundPage({Key? key, this.chitFund, this.initialRole = ChitRole.owner}) : super(key: key);

  @override
  State<AddChitFundPage> createState() => _AddChitFundPageState();
}

class _AddChitFundPageState extends State<AddChitFundPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _totalAmountController = TextEditingController();
  final _membersController = TextEditingController();
  final _durationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _organizerNameController = TextEditingController();
  final _organizerPhoneController = TextEditingController();
  final _auctionMonthController = TextEditingController();
  final _amountReceivedController = TextEditingController();

  DateTime _startDate = DateTime.now();
  ChitStatus _selectedStatus = ChitStatus.upcoming;
  late ChitRole _role;

  bool get _isEditing => widget.chitFund != null;

  @override
  void initState() {
    super.initState();
    _role = widget.chitFund?.role ?? widget.initialRole;
    if (widget.chitFund != null) {
      _nameController.text = widget.chitFund!.name;
      _totalAmountController.text = widget.chitFund!.totalAmount.toString();
      _membersController.text = widget.chitFund!.totalMembers.toString();
      _durationController.text = widget.chitFund!.durationMonths.toString();
      _descriptionController.text = widget.chitFund!.description ?? '';
      _startDate = widget.chitFund!.startDate;
      _selectedStatus = widget.chitFund!.status;
      _organizerNameController.text = widget.chitFund!.organizerName ?? '';
      _organizerPhoneController.text = widget.chitFund!.organizerPhone ?? '';
      if (widget.chitFund!.myMonthNumber != null) {
        _auctionMonthController.text = widget.chitFund!.myMonthNumber.toString();
      }
      if (widget.chitFund!.myAuctionAmount != null) {
        _amountReceivedController.text = widget.chitFund!.myAuctionAmount.toString();
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _totalAmountController.dispose();
    _membersController.dispose();
    _durationController.dispose();
    _descriptionController.dispose();
    _organizerNameController.dispose();
    _organizerPhoneController.dispose();
    _auctionMonthController.dispose();
    _amountReceivedController.dispose();
    super.dispose();
  }

  double _calculateMonthlyContribution() {
    final totalAmount = double.tryParse(_totalAmountController.text) ?? 0;
    final members = _role == ChitRole.participant
        ? 1
        : (int.tryParse(_membersController.text) ?? 1);
    return members > 0 ? totalAmount / members : 0;
  }

  List<Payment> _generatePayments(int durationMonths, double monthlyAmount, DateTime startDate) {
    final payments = <Payment>[];
    for (int i = 1; i <= durationMonths; i++) {
      final dueDate = DateTime(startDate.year, startDate.month + i, startDate.day);
      payments.add(Payment(
        id: '${DateTime.now().millisecondsSinceEpoch}_$i',
        memberId: 'self',
        monthNumber: i,
        amount: monthlyAmount,
        dueDate: dueDate,
      ));
    }
    return payments;
  }

  void _saveChitFund() {
    if (_formKey.currentState!.validate()) {
      final totalAmount = double.parse(_totalAmountController.text);
      final totalMembers = _role == ChitRole.participant
          ? 1
          : int.parse(_membersController.text);
      final durationMonths = int.parse(_durationController.text);
      final monthlyContribution = totalAmount / (totalMembers > 0 ? totalMembers : 1);

      List<Member> members = widget.chitFund?.members ?? [];
      if (_role == ChitRole.participant && members.isEmpty) {
        final payments = _generatePayments(durationMonths, monthlyContribution, _startDate);
        members = [
          Member(
            id: 'self',
            name: 'Me',
            joinedDate: DateTime.now(),
            payments: payments,
          ),
        ];
      }

      final chitFund = ChitFund(
        id: widget.chitFund?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        role: _role,
        totalAmount: totalAmount,
        totalMembers: totalMembers,
        durationMonths: durationMonths,
        monthlyContribution: monthlyContribution,
        startDate: _startDate,
        status: _selectedStatus,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        members: members,
        auctions: widget.chitFund?.auctions ?? [],
        organizerName: _role == ChitRole.participant && _organizerNameController.text.isNotEmpty
            ? _organizerNameController.text
            : widget.chitFund?.organizerName,
        organizerPhone: _role == ChitRole.participant && _organizerPhoneController.text.isNotEmpty
            ? _organizerPhoneController.text
            : widget.chitFund?.organizerPhone,
        myMonthNumber: _role == ChitRole.participant && _auctionMonthController.text.isNotEmpty
            ? int.tryParse(_auctionMonthController.text)
            : widget.chitFund?.myMonthNumber,
        myAuctionAmount: _role == ChitRole.participant && _amountReceivedController.text.isNotEmpty
            ? double.tryParse(_amountReceivedController.text)
            : widget.chitFund?.myAuctionAmount,
      );

      Navigator.pop(context, chitFund);
    }
  }

  @override
  Widget build(BuildContext context) {
    final monthlyContribution = _calculateMonthlyContribution();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Chit Group' : 'Create Chit Group'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Role selector
            SegmentedButton<ChitRole>(
              segments: const [
                ButtonSegment(
                  value: ChitRole.owner,
                  label: Text('Owner'),
                  icon: Icon(Icons.star_rounded),
                ),
                ButtonSegment(
                  value: ChitRole.participant,
                  label: Text('Participant'),
                  icon: Icon(Icons.group_work_rounded),
                ),
              ],
              selected: {_role},
              onSelectionChanged: (selected) {
                setState(() => _role = selected.first);
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Chit Group Name *',
                hintText: 'e.g., Family Chit Group',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.group_work),
              ),
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _totalAmountController,
              decoration: const InputDecoration(
                labelText: 'Total Chit Amount *',
                hintText: '100000',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.currency_rupee),
              ),
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Required';
                if (double.tryParse(value!) == null) return 'Invalid amount';
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (_role == ChitRole.owner)
                  Expanded(
                    child: TextFormField(
                      controller: _membersController,
                      decoration: const InputDecoration(
                        labelText: 'Total Members *',
                        hintText: '20',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.people),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'Required';
                        if (int.tryParse(value!) == null) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                if (_role == ChitRole.owner) const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _durationController,
                    decoration: const InputDecoration(
                      labelText: 'Duration (Months) *',
                      hintText: '20',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_month),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Required';
                      if (int.tryParse(value!) == null) return 'Invalid';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (monthlyContribution > 0)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.green[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Monthly Contribution: ₹${monthlyContribution.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // Participant-specific fields
            if (_role == ChitRole.participant) ...[
              TextFormField(
                controller: _organizerNameController,
                decoration: const InputDecoration(
                  labelText: 'Organizer Name',
                  hintText: 'e.g., Ramesh Kumar',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _organizerPhoneController,
                decoration: const InputDecoration(
                  labelText: 'Organizer Phone',
                  hintText: 'e.g., 9876543210',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _auctionMonthController,
                      decoration: const InputDecoration(
                        labelText: 'My Auction Month',
                        hintText: 'e.g., 5',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.emoji_events),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _amountReceivedController,
                      decoration: const InputDecoration(
                        labelText: 'Amount Received',
                        hintText: 'e.g., 90000',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.currency_rupee),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Additional details about the chit group',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Start Date'),
              subtitle: Text(DateFormat('MMM dd, yyyy').format(_startDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (date != null) {
                  setState(() => _startDate = date);
                }
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Status',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...ChitStatus.values.map((status) {
              return RadioListTile<ChitStatus>(
                title: Text(_getStatusLabel(status)),
                value: status,
                groupValue: _selectedStatus,
                onChanged: (value) {
                  setState(() => _selectedStatus = value!);
                },
              );
            }),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveChitFund,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                  _isEditing ? 'Update Chit Group' : 'Create Chit Group',
                  style: const TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusLabel(ChitStatus status) {
    switch (status) {
      case ChitStatus.active:
        return 'Active';
      case ChitStatus.completed:
        return 'Completed';
      case ChitStatus.upcoming:
        return 'Upcoming';
    }
  }
}

// Chit Fund Details Page
class ChitFundDetailsPage extends StatefulWidget {
  final String chitFundId;

  const ChitFundDetailsPage({Key? key, required this.chitFundId}) : super(key: key);

  @override
  State<ChitFundDetailsPage> createState() => _ChitFundDetailsPageState();
}

class _ChitFundDetailsPageState extends State<ChitFundDetailsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChitCubit, ChitState>(
      builder: (context, state) {
        final cubit = context.read<ChitCubit>();
        final chitFund = cubit.getChitFundById(widget.chitFundId);

        if (chitFund == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Chit Fund')),
            body: const Center(child: Text('Chit fund not found')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(chitFund.name),
            elevation: 0,
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Overview', icon: Icon(Icons.dashboard, size: 20)),
                Tab(text: 'Members', icon: Icon(Icons.people, size: 20)),
                Tab(text: 'Auctions', icon: Icon(Icons.gavel, size: 20)),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _OverviewTab(chitFund: chitFund),
              _MembersTab(
                chitFund: chitFund,
                onAddMember: (member) => cubit.addMember(widget.chitFundId, member),
                onUpdateMember: (member) => cubit.updateMember(widget.chitFundId, member),
              ),
              _AuctionsTab(
                chitFund: chitFund,
                onAddAuction: (auction) => cubit.addAuction(widget.chitFundId, auction),
                onUpdateAuction: (auction) => cubit.updateAuction(widget.chitFundId, auction),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Overview Tab
class _OverviewTab extends StatelessWidget {
  final ChitFund chitFund;

  const _OverviewTab({required this.chitFund});

  @override
  Widget build(BuildContext context) {
    final completedMonths = chitFund.auctions.length;
    final remainingMonths = chitFund.durationMonths - completedMonths;
    final progress = completedMonths / chitFund.durationMonths;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chit Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _DetailRow(
                  label: 'Total Amount',
                  value: '₹${chitFund.totalAmount.toStringAsFixed(0)}',
                  icon: Icons.currency_rupee,
                ),
                _DetailRow(
                  label: 'Monthly Contribution',
                  value: '₹${chitFund.monthlyContribution.toStringAsFixed(0)}',
                  icon: Icons.payment,
                ),
                _DetailRow(
                  label: 'Total Members',
                  value: '${chitFund.totalMembers}',
                  icon: Icons.people,
                ),
                _DetailRow(
                  label: 'Duration',
                  value: '${chitFund.durationMonths} Months',
                  icon: Icons.calendar_month,
                ),
                _DetailRow(
                  label: 'Start Date',
                  value: DateFormat('MMM dd, yyyy').format(chitFund.startDate),
                  icon: Icons.date_range,
                ),
                if (chitFund.description != null) ...[
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    chitFund.description!,
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Progress',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _ProgressCard(
                        title: 'Completed',
                        value: completedMonths.toString(),
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ProgressCard(
                        title: 'Remaining',
                        value: remainingMonths.toString(),
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 20,
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    '${(progress * 100).toStringAsFixed(1)}% Complete',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _ProgressCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// Members Tab
class _MembersTab extends StatelessWidget {
  final ChitFund chitFund;
  final Function(Member) onAddMember;
  final Function(Member) onUpdateMember;

  const _MembersTab(
      {required this.chitFund,
      required this.onAddMember,
      required this.onUpdateMember});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${chitFund.members.length} / ${chitFund.totalMembers} Members',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  final member = await Navigator.push<Member>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddMemberPage(),
                    ),
                  );
                  if (member != null) {
                    onAddMember(member);
                  }
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Member'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: chitFund.members.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No members added yet',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: chitFund.members.length,
                  itemBuilder: (context, index) {
                    final member = chitFund.members[index];
                    return MemberCard(
                      member: member,
                      onEdit: () async {
                        final editedMember = await Navigator.push<Member>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddMemberPage(member: member),
                          ),
                        );
                        if (editedMember != null) {
                          onUpdateMember(editedMember);
                        }
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class MemberCard extends StatelessWidget {
  final Member member;
  final VoidCallback? onEdit;

  const MemberCard({Key? key, required this.member, this.onEdit}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.deepPurple[100],
          child: Text(
            member.name[0].toUpperCase(),
            style: TextStyle(
              color: Colors.deepPurple[700],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Text(
              member.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (member.isOrganizer) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'ORGANIZER',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber[900],
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (member.phone != null)
              Text('Phone: ${member.phone}', style: const TextStyle(fontSize: 12)),
            if (member.email != null)
              Text('Email: ${member.email}', style: const TextStyle(fontSize: 12)),
          ],
        ),
        trailing: onEdit != null
            ? IconButton(
                icon: const Icon(Icons.edit_outlined),
                color: Colors.blue[400],
                onPressed: onEdit,
              )
            : const Icon(Icons.chevron_right),
      ),
    );
  }
}

// Add Member Page
class AddMemberPage extends StatefulWidget {
  final Member? member;

  const AddMemberPage({Key? key, this.member}) : super(key: key);

  @override
  State<AddMemberPage> createState() => _AddMemberPageState();
}

class _AddMemberPageState extends State<AddMemberPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isOrganizer = false;

  bool get _isEditing => widget.member != null;

  @override
  void initState() {
    super.initState();
    if (widget.member != null) {
      _nameController.text = widget.member!.name;
      _phoneController.text = widget.member!.phone ?? '';
      _emailController.text = widget.member!.email ?? '';
      _isOrganizer = widget.member!.isOrganizer;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _saveMember() {
    if (_formKey.currentState!.validate()) {
      final member = Member(
        id: widget.member?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        phone: _phoneController.text.isEmpty ? null : _phoneController.text,
        email: _emailController.text.isEmpty ? null : _emailController.text,
        isOrganizer: _isOrganizer,
        joinedDate: widget.member?.joinedDate ?? DateTime.now(),
        payments: widget.member?.payments ?? [],
      );
      Navigator.pop(context, member);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Member' : 'Add Member'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Member Name *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Organizer'),
              subtitle: const Text('Mark as group organizer'),
              value: _isOrganizer,
              onChanged: (value) => setState(() => _isOrganizer = value),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveMember,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                  _isEditing ? 'Update Member' : 'Add Member',
                  style: const TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

// Auctions Tab
class _AuctionsTab extends StatelessWidget {
  final ChitFund chitFund;
  final Function(Auction) onAddAuction;
  final Function(Auction) onUpdateAuction;

  const _AuctionsTab(
      {required this.chitFund,
      required this.onAddAuction,
      required this.onUpdateAuction});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${chitFund.auctions.length} Auctions',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  final auction = await Navigator.push<Auction>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddAuctionPage(chitFund: chitFund),
                    ),
                  );
                  if (auction != null) {
                    onAddAuction(auction);
                  }
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Auction'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: chitFund.auctions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.gavel, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No auctions recorded yet',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: chitFund.auctions.length,
                  itemBuilder: (context, index) {
                    final auction = chitFund.auctions[index];
                    return AuctionCard(
                      auction: auction,
                      onEdit: () async {
                        final editedAuction = await Navigator.push<Auction>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddAuctionPage(
                              chitFund: chitFund,
                              auction: auction,
                            ),
                          ),
                        );
                        if (editedAuction != null) {
                          onUpdateAuction(editedAuction);
                        }
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class AuctionCard extends StatelessWidget {
  final Auction auction;
  final VoidCallback? onEdit;

  const AuctionCard({Key? key, required this.auction, this.onEdit}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.gavel, color: Colors.deepPurple[700], size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Month ${auction.monthNumber}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        DateFormat('MMM dd, yyyy').format(auction.auctionDate),
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                if (onEdit != null)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    color: Colors.blue[400],
                    onPressed: onEdit,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Winner: ${auction.winnerName}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Bid Amount:',
                          style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                      Text(
                        '₹${auction.bidAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Discount:',
                          style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                      Text(
                        '₹${auction.discountAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Amount Received:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '₹${auction.amountReceived.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (auction.notes != null) ...[
              const SizedBox(height: 8),
              Text(
                auction.notes!,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Add Auction Page
class AddAuctionPage extends StatefulWidget {
  final ChitFund chitFund;
  final Auction? auction;

  const AddAuctionPage({Key? key, required this.chitFund, this.auction}) : super(key: key);

  @override
  State<AddAuctionPage> createState() => _AddAuctionPageState();
}

class _AddAuctionPageState extends State<AddAuctionPage> {
  final _formKey = GlobalKey<FormState>();
  final _bidAmountController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _auctionDate = DateTime.now();
  Member? _selectedWinner;
  int _monthNumber = 1;

  bool get _isEditing => widget.auction != null;

  @override
  void initState() {
    super.initState();
    if (widget.auction != null) {
      _bidAmountController.text = widget.auction!.bidAmount.toString();
      _notesController.text = widget.auction!.notes ?? '';
      _auctionDate = widget.auction!.auctionDate;
      _monthNumber = widget.auction!.monthNumber;
      _selectedWinner = widget.chitFund.members
              .where((m) => m.id == widget.auction!.winnerId)
              .isNotEmpty
          ? widget.chitFund.members.firstWhere((m) => m.id == widget.auction!.winnerId)
          : null;
    } else {
      _monthNumber = widget.chitFund.auctions.length + 1;
    }
  }

  @override
  void dispose() {
    _bidAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double _calculateAmountReceived() {
    final bidAmount = double.tryParse(_bidAmountController.text) ?? 0;
    return bidAmount;
  }

  double _calculateDiscount() {
    final bidAmount = double.tryParse(_bidAmountController.text) ?? 0;
    return widget.chitFund.totalAmount - bidAmount;
  }

  void _saveAuction() {
    if (_formKey.currentState!.validate()) {
      if (_selectedWinner == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a winner')),
        );
        return;
      }

      final bidAmount = double.parse(_bidAmountController.text);
      final discount = widget.chitFund.totalAmount - bidAmount;

      final auction = Auction(
        id: widget.auction?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        monthNumber: _monthNumber,
        auctionDate: _auctionDate,
        winnerId: _selectedWinner!.id,
        winnerName: _selectedWinner!.name,
        bidAmount: bidAmount,
        discountAmount: discount,
        amountReceived: bidAmount,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      Navigator.pop(context, auction);
    }
  }

  @override
  Widget build(BuildContext context) {
    final amountReceived = _calculateAmountReceived();
    final discount = _calculateDiscount();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Auction' : 'Record Auction'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Month $_monthNumber Auction',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Total Chit Amount: ₹${widget.chitFund.totalAmount.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Auction Date'),
              subtitle: Text(DateFormat('MMM dd, yyyy').format(_auctionDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _auctionDate,
                  firstDate: widget.chitFund.startDate,
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() => _auctionDate = date);
                }
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Member>(
              decoration: const InputDecoration(
                labelText: 'Winner *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              value: _selectedWinner,
              items: widget.chitFund.members.map((member) {
                return DropdownMenuItem(
                  value: member,
                  child: Text(member.name),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedWinner = value),
              validator: (value) => value == null ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bidAmountController,
              decoration: InputDecoration(
                labelText: 'Bid Amount *',
                hintText: widget.chitFund.totalAmount.toStringAsFixed(0),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.currency_rupee),
              ),
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Required';
                final amount = double.tryParse(value!);
                if (amount == null) return 'Invalid amount';
                if (amount > widget.chitFund.totalAmount) {
                  return 'Cannot exceed total amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            if (discount >= 0)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Discount:',
                            style: TextStyle(fontWeight: FontWeight.w500)),
                        Text(
                          '₹${discount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Amount Received:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          '₹${amountReceived.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Additional details...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveAuction,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                  _isEditing ? 'Update Auction' : 'Save Auction',
                  style: const TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
