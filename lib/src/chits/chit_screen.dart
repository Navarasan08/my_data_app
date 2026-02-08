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
    return BlocBuilder<ChitCubit, ChitState>(
      builder: (context, state) {
        final cubit = context.read<ChitCubit>();
        final chitFunds = state.chitFunds;
        final activeChits = cubit.getByStatus(ChitStatus.active);
        final completedChits = cubit.getByStatus(ChitStatus.completed);
        final upcomingChits = cubit.getByStatus(ChitStatus.upcoming);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Chit Fund Manager'),
            centerTitle: true,
            elevation: 0,
          ),
          body: Column(
            children: [
              // Summary Cards
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        title: 'Active',
                        count: activeChits.length,
                        color: Colors.green,
                        icon: Icons.play_circle_outline,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        title: 'Upcoming',
                        count: upcomingChits.length,
                        color: Colors.orange,
                        icon: Icons.schedule,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        title: 'Completed',
                        count: completedChits.length,
                        color: Colors.blue,
                        icon: Icons.check_circle_outline,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Chit Funds List
              Expanded(
                child: chitFunds.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.group_work_outlined,
                                size: 80, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No chit funds yet',
                              style: TextStyle(
                                  fontSize: 16, color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap the + button to create your first chit group',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: chitFunds.length,
                        itemBuilder: (context, index) {
                          final chitFund = chitFunds[index];
                          return ChitFundCard(
                            chitFund: chitFund,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BlocProvider.value(
                                    value: cubit,
                                    child: ChitFundDetailsPage(
                                        chitFundId: chitFund.id),
                                  ),
                                ),
                              );
                            },
                            onEdit: () async {
                              final editedChitFund =
                                  await Navigator.push<ChitFund>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddChitFundPage(
                                      chitFund: chitFund),
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
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      style: TextButton.styleFrom(
                                          foregroundColor: Colors.red),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true) {
                                cubit.deleteChitFund(chitFund.id);
                              }
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              final newChitFund = await Navigator.push<ChitFund>(
                context,
                MaterialPageRoute(
                    builder: (context) => const AddChitFundPage()),
              );
              if (newChitFund != null) {
                cubit.addChitFund(newChitFund);
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Create Chit Group'),
          ),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
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

  Color _getStatusColor() {
    switch (chitFund.status) {
      case ChitStatus.active:
        return Colors.green;
      case ChitStatus.completed:
        return Colors.blue;
      case ChitStatus.upcoming:
        return Colors.orange;
    }
  }

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
    final completedMonths = chitFund.auctions.length;
    final progress = completedMonths / chitFund.durationMonths;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.group_work,
                        color: Colors.deepPurple[700], size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          chitFund.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor().withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: _getStatusColor().withOpacity(0.3)),
                          ),
                          child: Text(
                            _getStatusText(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    color: Colors.blue[400],
                    onPressed: onEdit,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.red[400],
                    onPressed: onDelete,
                  ),
                ],
              ),
              if (chitFund.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  chitFund.description!,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Divider(color: Colors.grey[300]),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _InfoItem(
                      icon: Icons.currency_rupee,
                      label: 'Total',
                      value: '₹${_formatAmount(chitFund.totalAmount)}',
                    ),
                  ),
                  Expanded(
                    child: _InfoItem(
                      icon: Icons.people,
                      label: 'Members',
                      value:
                          '${chitFund.members.length}/${chitFund.totalMembers}',
                    ),
                  ),
                  Expanded(
                    child: _InfoItem(
                      icon: Icons.calendar_month,
                      label: 'Duration',
                      value: '${chitFund.durationMonths}M',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Progress',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '$completedMonths/${chitFund.durationMonths}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                                _getStatusColor()),
                          ),
                        ),
                      ],
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

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

// Add Chit Fund Page
class AddChitFundPage extends StatefulWidget {
  final ChitFund? chitFund;

  const AddChitFundPage({Key? key, this.chitFund}) : super(key: key);

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

  DateTime _startDate = DateTime.now();
  ChitStatus _selectedStatus = ChitStatus.upcoming;

  bool get _isEditing => widget.chitFund != null;

  @override
  void initState() {
    super.initState();
    if (widget.chitFund != null) {
      _nameController.text = widget.chitFund!.name;
      _totalAmountController.text = widget.chitFund!.totalAmount.toString();
      _membersController.text = widget.chitFund!.totalMembers.toString();
      _durationController.text = widget.chitFund!.durationMonths.toString();
      _descriptionController.text = widget.chitFund!.description ?? '';
      _startDate = widget.chitFund!.startDate;
      _selectedStatus = widget.chitFund!.status;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _totalAmountController.dispose();
    _membersController.dispose();
    _durationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  double _calculateMonthlyContribution() {
    final totalAmount =
        double.tryParse(_totalAmountController.text) ?? 0;
    final members = int.tryParse(_membersController.text) ?? 1;
    return members > 0 ? totalAmount / members : 0;
  }

  void _saveChitFund() {
    if (_formKey.currentState!.validate()) {
      final totalAmount = double.parse(_totalAmountController.text);
      final totalMembers = int.parse(_membersController.text);
      final durationMonths = int.parse(_durationController.text);

      final chitFund = ChitFund(
        id: widget.chitFund?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        totalAmount: totalAmount,
        totalMembers: totalMembers,
        durationMonths: durationMonths,
        monthlyContribution: totalAmount / totalMembers,
        startDate: _startDate,
        status: _selectedStatus,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        members: widget.chitFund?.members ?? [],
        auctions: widget.chitFund?.auctions ?? [],
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
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Chit Group Name *',
                hintText: 'e.g., Family Chit Group',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.group_work),
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Required' : null,
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
                const SizedBox(width: 12),
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
              subtitle:
                  Text(DateFormat('MMM dd, yyyy').format(_startDate)),
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

  const ChitFundDetailsPage({Key? key, required this.chitFundId})
      : super(key: key);

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
                Tab(
                    text: 'Overview',
                    icon: Icon(Icons.dashboard, size: 20)),
                Tab(
                    text: 'Members',
                    icon: Icon(Icons.people, size: 20)),
                Tab(
                    text: 'Auctions',
                    icon: Icon(Icons.gavel, size: 20)),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _OverviewTab(chitFund: chitFund),
              _MembersTab(
                chitFund: chitFund,
                onAddMember: (member) =>
                    cubit.addMember(widget.chitFundId, member),
                onUpdateMember: (member) =>
                    cubit.updateMember(widget.chitFundId, member),
              ),
              _AuctionsTab(
                chitFund: chitFund,
                onAddAuction: (auction) =>
                    cubit.addAuction(widget.chitFundId, auction),
                onUpdateAuction: (auction) =>
                    cubit.updateAuction(widget.chitFundId, auction),
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
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _DetailRow(
                  label: 'Total Amount',
                  value: '₹${chitFund.totalAmount.toStringAsFixed(0)}',
                  icon: Icons.currency_rupee,
                ),
                _DetailRow(
                  label: 'Monthly Contribution',
                  value:
                      '₹${chitFund.monthlyContribution.toStringAsFixed(0)}',
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
                  value: DateFormat('MMM dd, yyyy')
                      .format(chitFund.startDate),
                  icon: Icons.date_range,
                ),
                if (chitFund.description != null) ...[
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    chitFund.description!,
                    style:
                        TextStyle(fontSize: 14, color: Colors.grey[700]),
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
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.green),
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
            style:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
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
                      Icon(Icons.people_outline,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No members added yet',
                        style: TextStyle(
                            fontSize: 16, color: Colors.grey[600]),
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
                        final editedMember =
                            await Navigator.push<Member>(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AddMemberPage(member: member),
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

  const MemberCard({Key? key, required this.member, this.onEdit})
      : super(key: key);

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
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
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
              Text('📱 ${member.phone}',
                  style: const TextStyle(fontSize: 12)),
            if (member.email != null)
              Text('✉️ ${member.email}',
                  style: const TextStyle(fontSize: 12)),
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
        id: widget.member?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        phone: _phoneController.text.isEmpty
            ? null
            : _phoneController.text,
        email: _emailController.text.isEmpty
            ? null
            : _emailController.text,
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
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Required' : null,
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
              onChanged: (value) =>
                  setState(() => _isOrganizer = value),
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
                      builder: (context) =>
                          AddAuctionPage(chitFund: chitFund),
                    ),
                  );
                  if (auction != null) {
                    onAddAuction(auction);
                  }
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Auction'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
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
                      Icon(Icons.gavel,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No auctions recorded yet',
                        style: TextStyle(
                            fontSize: 16, color: Colors.grey[600]),
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
                        final editedAuction =
                            await Navigator.push<Auction>(
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

  const AuctionCard({Key? key, required this.auction, this.onEdit})
      : super(key: key);

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
                  child: Icon(Icons.gavel,
                      color: Colors.deepPurple[700], size: 24),
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
                        DateFormat('MMM dd, yyyy')
                            .format(auction.auctionDate),
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey[600]),
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
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey[700])),
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
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey[700])),
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

  const AddAuctionPage(
      {Key? key, required this.chitFund, this.auction})
      : super(key: key);

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
          ? widget.chitFund.members
              .firstWhere((m) => m.id == widget.auction!.winnerId)
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
    final bidAmount =
        double.tryParse(_bidAmountController.text) ?? 0;
    return bidAmount;
  }

  double _calculateDiscount() {
    final bidAmount =
        double.tryParse(_bidAmountController.text) ?? 0;
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
        id: widget.auction?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        monthNumber: _monthNumber,
        auctionDate: _auctionDate,
        winnerId: _selectedWinner!.id,
        winnerName: _selectedWinner!.name,
        bidAmount: bidAmount,
        discountAmount: discount,
        amountReceived: bidAmount,
        notes: _notesController.text.isEmpty
            ? null
            : _notesController.text,
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
                      style: TextStyle(
                          fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Auction Date'),
              subtitle: Text(
                  DateFormat('MMM dd, yyyy').format(_auctionDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _auctionDate,
                  firstDate: widget.chitFund.startDate,
                  lastDate:
                      DateTime.now().add(const Duration(days: 365)),
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
              onChanged: (value) =>
                  setState(() => _selectedWinner = value),
              validator: (value) =>
                  value == null ? 'Required' : null,
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
                            style:
                                TextStyle(fontWeight: FontWeight.w500)),
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
                            style: TextStyle(
                                fontWeight: FontWeight.bold)),
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
