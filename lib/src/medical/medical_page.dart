import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:my_data_app/src/medical/model/medical_model.dart';
import 'package:my_data_app/src/medical/cubit/medical_cubit.dart';
import 'package:my_data_app/src/medical/cubit/medical_state.dart';

final _inr = NumberFormat('#,##,###', 'en_IN');

// ══════════════════════════════════════════════════════════════════════════════
// 1. MedicalHomePage
// ══════════════════════════════════════════════════════════════════════════════

class MedicalHomePage extends StatelessWidget {
  const MedicalHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MedicalCubit, MedicalState>(
      builder: (context, state) {
        final cubit = context.read<MedicalCubit>();
        final members = state.members;
        final records = state.records;
        final activeMeds = cubit.activeMedications;
        final followUps = cubit.upcomingFollowUps;
        final recentRecords = List<MedicalRecord>.from(records)
          ..sort((a, b) => b.date.compareTo(a.date));

        return Scaffold(
          appBar: AppBar(
            title: const Text('Medical Records'),
            centerTitle: true,
            elevation: 0,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Family Members ──────────────────────────────────────────
              const Text(
                'Family Members',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 90,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ...members.map((m) => _MemberChip(
                          member: m,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BlocProvider.value(
                                value: cubit,
                                child: MemberDetailPage(memberId: m.id),
                              ),
                            ),
                          ),
                        )),
                    _AddMemberChip(
                      onTap: () async {
                        final member = await Navigator.push<FamilyMember>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AddMemberPage(),
                          ),
                        );
                        if (member != null) cubit.addMember(member);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Quick Stats ─────────────────────────────────────────────
              if (records.isNotEmpty) ...[
                Row(
                  children: [
                    _QuickStat(
                      label: 'Records',
                      value: records.length.toString(),
                      icon: Icons.folder_rounded,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    _QuickStat(
                      label: 'Active Meds',
                      value: activeMeds.length.toString(),
                      icon: Icons.medication_rounded,
                      color: Colors.teal,
                    ),
                    const SizedBox(width: 8),
                    _QuickStat(
                      label: 'Follow-ups',
                      value: followUps.length.toString(),
                      icon: Icons.event_rounded,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    _QuickStat(
                      label: 'Expenses',
                      value: '\u20B9${_inr.format(cubit.totalExpenses.round())}',
                      icon: Icons.receipt_long_rounded,
                      color: Colors.green,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // ── Upcoming Follow-ups ─────────────────────────────────────
              if (followUps.isNotEmpty) ...[
                const Text(
                  'Upcoming Follow-ups',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ...followUps.take(3).map((f) {
                  final daysLeft = f.record.followUpDate!
                      .difference(DateTime.now())
                      .inDays;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(10),
                      border: Border(
                        left: BorderSide(
                            color: Colors.orange[400]!, width: 3),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          Icon(Icons.event_rounded,
                              size: 18, color: Colors.orange[600]),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  f.record.title,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${f.member.name} \u00B7 ${DateFormat('dd MMM yyyy').format(f.record.followUpDate!)}',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[500]),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: daysLeft <= 3
                                  ? Colors.red[50]
                                  : Colors.orange[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$daysLeft day${daysLeft == 1 ? '' : 's'}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: daysLeft <= 3
                                    ? Colors.red[700]
                                    : Colors.orange[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
              ],

              // ── Active Medications ──────────────────────────────────────
              if (activeMeds.isNotEmpty) ...[
                const Text(
                  'Active Medications',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ...activeMeds.take(5).map((m) => Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: Colors.teal.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(10),
                        border: Border(
                          left: BorderSide(
                              color: Colors.teal[400]!, width: 3),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        child: Row(
                          children: [
                            Icon(Icons.medication_rounded,
                                size: 18, color: Colors.teal[600]),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    m.medication.name,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    [
                                      if (m.medication.dosage != null)
                                        m.medication.dosage!,
                                      m.medication.timingLabel,
                                    ].join(' \u00B7 '),
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[500]),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              m.member.name,
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                    )),
                const SizedBox(height: 16),
              ],

              // ── Recent Records ──────────────────────────────────────────
              if (recentRecords.isNotEmpty) ...[
                const Text(
                  'Recent Records',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ...recentRecords.take(10).map((r) {
                  final member = cubit.getMemberById(r.memberId);
                  return _RecordCard(
                    record: r,
                    member: member,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: cubit,
                          child: RecordDetailPage(recordId: r.id),
                        ),
                      ),
                    ),
                    onDelete: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Record'),
                          content: Text(
                              'Are you sure you want to delete "${r.title}"?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: TextButton.styleFrom(
                                  foregroundColor: Colors.red),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) cubit.deleteRecord(r.id);
                    },
                  );
                }),
              ],

              // ── Empty state ─────────────────────────────────────────────
              if (records.isEmpty && members.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.medical_services_outlined,
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No medical records yet',
                          style: TextStyle(
                              fontSize: 16, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add a family member to get started',
                          style: TextStyle(
                              fontSize: 14, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ── Helper widgets for MedicalHomePage ────────────────────────────────────────

class _MemberChip extends StatelessWidget {
  final FamilyMember member;
  final VoidCallback onTap;

  const _MemberChip({required this.member, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = member.relation == Relation.self
        ? Colors.blue
        : member.gender == Gender.female
            ? Colors.pink
            : Colors.indigo;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70,
        margin: const EdgeInsets.only(right: 10),
        child: Column(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: color.withValues(alpha: 0.15),
              child: Text(
                member.name.isNotEmpty
                    ? member.name[0].toUpperCase()
                    : '?',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: color),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              member.name,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            Text(
              member.relation.label,
              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _AddMemberChip extends StatelessWidget {
  final VoidCallback onTap;

  const _AddMemberChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 70,
        child: Column(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Colors.grey[100],
              child: Icon(Icons.add_rounded, color: Colors.grey[500], size: 22),
            ),
            const SizedBox(height: 4),
            Text(
              'Add',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _QuickStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold, color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.7)),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 2. _RecordCard
// ══════════════════════════════════════════════════════════════════════════════

class _RecordCard extends StatelessWidget {
  final MedicalRecord record;
  final FamilyMember? member;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _RecordCard({
    required this.record,
    required this.member,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = record.type.color;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(color: color, width: 3),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(record.type.icon, size: 20, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.title,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (record.doctorName != null) record.doctorName!,
                        if (record.hospitalName != null) record.hospitalName!,
                        DateFormat('dd MMM yyyy').format(record.date),
                      ].join(' \u00B7 '),
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey[500]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (member != null) ...[
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          member!.name,
                          style: TextStyle(
                              fontSize: 10, color: Colors.grey[600]),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (record.amount != null && record.amount! > 0)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    '\u20B9${_inr.format(record.amount!.round())}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.green[700],
                    ),
                  ),
                ),
              const SizedBox(width: 6),
              InkWell(
                onTap: onDelete,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.delete_outline_rounded,
                      size: 16, color: Colors.red[300]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 3. MemberDetailPage
// ══════════════════════════════════════════════════════════════════════════════

class MemberDetailPage extends StatefulWidget {
  final String memberId;

  const MemberDetailPage({Key? key, required this.memberId}) : super(key: key);

  @override
  State<MemberDetailPage> createState() => _MemberDetailPageState();
}

class _MemberDetailPageState extends State<MemberDetailPage> {
  RecordType? _filterType;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MedicalCubit, MedicalState>(
      builder: (context, state) {
        final cubit = context.read<MedicalCubit>();
        final member = cubit.getMemberById(widget.memberId);
        if (member == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Not Found')),
            body: const Center(child: Text('Member not found')),
          );
        }

        List<MedicalRecord> records = _filterType == null
            ? cubit.recordsForMember(member.id)
            : cubit.recordsForMemberByType(member.id, _filterType!);

        return Scaffold(
          appBar: AppBar(
            title: Text(member.name),
            centerTitle: true,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: () async {
                  final edited = await Navigator.push<FamilyMember>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddMemberPage(member: member),
                    ),
                  );
                  if (edited != null) cubit.updateMember(edited);
                },
              ),
              IconButton(
                icon: Icon(Icons.delete_outline_rounded,
                    size: 20, color: Colors.red[400]),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Member'),
                      content: Text(
                          'Delete "${member.name}" and all their records?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: TextButton.styleFrom(
                              foregroundColor: Colors.red),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true && context.mounted) {
                    cubit.deleteMember(member.id);
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Member Info ─────────────────────────────────────────────
              _MemberInfoSection(member: member),
              const SizedBox(height: 16),

              // ── Record Type Filter ──────────────────────────────────────
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _FilterChip(
                      label: 'All',
                      isSelected: _filterType == null,
                      onTap: () => setState(() => _filterType = null),
                    ),
                    ...RecordType.values.map((type) => _FilterChip(
                          label: type.label,
                          isSelected: _filterType == type,
                          color: type.color,
                          onTap: () => setState(() => _filterType = type),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Records ─────────────────────────────────────────────────
              if (records.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child: Center(
                    child: Text(
                      'No records found',
                      style:
                          TextStyle(fontSize: 14, color: Colors.grey[500]),
                    ),
                  ),
                )
              else
                ...records.map((r) => _RecordCard(
                      record: r,
                      member: member,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BlocProvider.value(
                            value: cubit,
                            child: RecordDetailPage(recordId: r.id),
                          ),
                        ),
                      ),
                      onDelete: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete Record'),
                            content: Text(
                                'Delete "${r.title}"?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: TextButton.styleFrom(
                                    foregroundColor: Colors.red),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) cubit.deleteRecord(r.id);
                      },
                    )),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              final record = await Navigator.push<MedicalRecord>(
                context,
                MaterialPageRoute(
                  builder: (_) => AddRecordPage(memberId: member.id),
                ),
              );
              if (record != null) cubit.addRecord(record);
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Record'),
          ),
        );
      },
    );
  }
}

class _MemberInfoSection extends StatelessWidget {
  final FamilyMember member;

  const _MemberInfoSection({required this.member});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(color: Colors.blue[400]!, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Grid: Gender, Age, Blood Group, Height/Weight
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _InfoTile(
                  label: 'Gender',
                  value: member.gender.label,
                  icon: member.gender.icon),
              if (member.age != null)
                _InfoTile(
                    label: 'Age',
                    value: '${member.age} yrs',
                    icon: Icons.cake_rounded),
              _InfoTile(
                  label: 'Blood',
                  value: member.bloodGroup.label,
                  icon: Icons.bloodtype_rounded),
              if (member.height != null || member.weight != null)
                _InfoTile(
                  label: 'H / W',
                  value:
                      '${member.height?.toStringAsFixed(0) ?? '-'} cm / ${member.weight?.toStringAsFixed(0) ?? '-'} kg',
                  icon: Icons.straighten_rounded,
                ),
            ],
          ),

          // Allergies
          if (member.allergies.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text('Allergies',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: member.allergies
                  .map((a) => _MiniChip(label: a, color: Colors.red))
                  .toList(),
            ),
          ],

          // Chronic Conditions
          if (member.chronicConditions.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text('Chronic Conditions',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: member.chronicConditions
                  .map((c) => _MiniChip(label: c, color: Colors.orange))
                  .toList(),
            ),
          ],

          // Emergency Contact
          if (member.emergencyContact != null &&
              member.emergencyContact!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.phone_rounded, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 6),
                Text(
                  member.emergencyContact!,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],

          // Insurance Info
          if (member.insuranceInfo != null &&
              member.insuranceInfo!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.shield_rounded, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    member.insuranceInfo!,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoTile(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.blue[400]),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(fontSize: 9, color: Colors.grey[500])),
            Text(value,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.blue;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? c.withValues(alpha: 0.15) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? c : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? c : Colors.grey[600],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 4. RecordDetailPage
// ══════════════════════════════════════════════════════════════════════════════

class RecordDetailPage extends StatelessWidget {
  final String recordId;

  const RecordDetailPage({Key? key, required this.recordId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MedicalCubit, MedicalState>(
      builder: (context, state) {
        final cubit = context.read<MedicalCubit>();
        final matches = state.records.where((r) => r.id == recordId);
        if (matches.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Not Found')),
            body: const Center(child: Text('Record not found')),
          );
        }
        final record = matches.first;
        final member = cubit.getMemberById(record.memberId);
        final color = record.type.color;

        return Scaffold(
          appBar: AppBar(
            title: Text(record.title),
            centerTitle: true,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: () async {
                  final edited = await Navigator.push<MedicalRecord>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddRecordPage(
                          memberId: record.memberId, record: record),
                    ),
                  );
                  if (edited != null) cubit.updateRecord(edited);
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Type Badge ──────────────────────────────────────────────
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(record.type.icon, size: 16, color: color),
                    const SizedBox(width: 6),
                    Text(
                      record.type.label,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: color),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Doctor / Hospital / Speciality ──────────────────────────
              if (record.doctorName != null) ...[
                _DetailRow(
                    icon: Icons.person_rounded,
                    label: 'Doctor',
                    value: record.doctorName!),
              ],
              if (record.hospitalName != null) ...[
                _DetailRow(
                    icon: Icons.local_hospital_rounded,
                    label: 'Hospital',
                    value: record.hospitalName!),
              ],
              if (record.speciality != null) ...[
                _DetailRow(
                    icon: Icons.medical_information_rounded,
                    label: 'Speciality',
                    value: record.speciality!),
              ],

              // ── Dates ───────────────────────────────────────────────────
              _DetailRow(
                  icon: Icons.calendar_today_rounded,
                  label: 'Date',
                  value: DateFormat('dd MMM yyyy').format(record.date)),
              if (record.followUpDate != null) ...[
                Builder(builder: (context) {
                  final daysUntil = record.followUpDate!
                      .difference(DateTime.now())
                      .inDays;
                  return _DetailRow(
                    icon: Icons.event_rounded,
                    label: 'Follow-up',
                    value:
                        '${DateFormat('dd MMM yyyy').format(record.followUpDate!)} ($daysUntil day${daysUntil == 1 ? '' : 's'} ${daysUntil >= 0 ? 'left' : 'ago'})',
                  );
                }),
              ],

              // ── Diagnosis ───────────────────────────────────────────────
              if (record.diagnosis != null &&
                  record.diagnosis!.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Diagnosis',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(record.diagnosis!,
                    style: TextStyle(fontSize: 13, color: Colors.grey[700])),
              ],

              // ── Symptoms ────────────────────────────────────────────────
              if (record.symptoms.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Symptoms',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: record.symptoms
                      .map((s) => _MiniChip(label: s, color: Colors.purple))
                      .toList(),
                ),
              ],

              // ── Medications ─────────────────────────────────────────────
              if (record.medications.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Medications',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ...record.medications.map((med) => Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.teal.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(10),
                        border: Border(
                          left: BorderSide(
                              color: Colors.teal[400]!, width: 3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  med.name,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                              if (med.isActive)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green[50],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text('Active',
                                      style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.green[700])),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            [
                              if (med.dosage != null) med.dosage!,
                              med.frequency.label,
                              med.mealTiming.label,
                            ].join(' \u00B7 '),
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[500]),
                          ),
                          if (med.morning ||
                              med.afternoon ||
                              med.evening ||
                              med.night) ...[
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 6,
                              children: [
                                if (med.morning)
                                  _TimingSlot(
                                      label: 'Morning',
                                      icon: Icons.wb_sunny_rounded),
                                if (med.afternoon)
                                  _TimingSlot(
                                      label: 'Afternoon',
                                      icon: Icons.wb_cloudy_rounded),
                                if (med.evening)
                                  _TimingSlot(
                                      label: 'Evening',
                                      icon: Icons.wb_twilight_rounded),
                                if (med.night)
                                  _TimingSlot(
                                      label: 'Night',
                                      icon: Icons.nights_stay_rounded),
                              ],
                            ),
                          ],
                          if (med.durationDays > 0) ...[
                            const SizedBox(height: 4),
                            Text(
                              '${DateFormat('dd MMM').format(med.startDate!)} - ${DateFormat('dd MMM').format(med.endDate!)} (${med.durationDays} days)',
                              style: TextStyle(
                                  fontSize: 10, color: Colors.grey[400]),
                            ),
                          ],
                        ],
                      ),
                    )),
              ],

              // ── Lab Results ─────────────────────────────────────────────
              if (record.labResults.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Lab Results',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(8)),
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                                flex: 3,
                                child: Text('Test',
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600))),
                            const Expanded(
                                flex: 2,
                                child: Text('Value',
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600))),
                            const Expanded(
                                flex: 2,
                                child: Text('Normal',
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600))),
                            SizedBox(
                                width: 50,
                                child: Text('',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[400]))),
                          ],
                        ),
                      ),
                      ...record.labResults.map((lr) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border(
                                  top: BorderSide(color: Colors.grey[100]!)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(lr.testName,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500)),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    '${lr.value ?? '-'}${lr.unit != null ? ' ${lr.unit}' : ''}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: lr.isAbnormal
                                          ? Colors.red[700]
                                          : Colors.grey[700],
                                      fontWeight: lr.isAbnormal
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(lr.normalRange ?? '-',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[400])),
                                ),
                                SizedBox(
                                  width: 50,
                                  child: lr.isAbnormal
                                      ? Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 4, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: Colors.red[50],
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text('Abnormal',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.red[700])),
                                        )
                                      : const SizedBox.shrink(),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
              ],

              // ── Amount / Insurance ──────────────────────────────────────
              if (record.amount != null && record.amount! > 0) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      '\u20B9${_inr.format(record.amount!.round())}',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700]),
                    ),
                    const SizedBox(width: 8),
                    if (record.isCovered)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('Insurance covered',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue[700])),
                      ),
                  ],
                ),
              ],

              // ── Notes ───────────────────────────────────────────────────
              if (record.notes != null && record.notes!.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Notes',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(record.notes!,
                    style: TextStyle(fontSize: 13, color: Colors.grey[700])),
              ],

              // ── Member name ─────────────────────────────────────────────
              if (member != null) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.person_rounded,
                        size: 14, color: Colors.grey[400]),
                    const SizedBox(width: 6),
                    Text(
                      '${member.name} (${member.relation.label})',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[400]),
          const SizedBox(width: 8),
          Text('$label: ',
              style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _TimingSlot extends StatelessWidget {
  final String label;
  final IconData icon;

  const _TimingSlot({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.teal[400]),
        const SizedBox(width: 2),
        Text(label,
            style: TextStyle(fontSize: 10, color: Colors.teal[600])),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 5. AddMemberPage
// ══════════════════════════════════════════════════════════════════════════════

class AddMemberPage extends StatefulWidget {
  final FamilyMember? member;

  const AddMemberPage({Key? key, this.member}) : super(key: key);

  @override
  State<AddMemberPage> createState() => _AddMemberPageState();
}

class _AddMemberPageState extends State<AddMemberPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _emergencyController = TextEditingController();
  final _insuranceController = TextEditingController();
  final _notesController = TextEditingController();
  final _allergyController = TextEditingController();
  final _conditionController = TextEditingController();

  Relation _relation = Relation.self;
  Gender _gender = Gender.other;
  DateTime? _dob;
  BloodGroup _bloodGroup = BloodGroup.unknown;
  List<String> _allergies = [];
  List<String> _conditions = [];

  bool get _isEditing => widget.member != null;

  @override
  void initState() {
    super.initState();
    if (widget.member != null) {
      final m = widget.member!;
      _nameController.text = m.name;
      _relation = m.relation;
      _gender = m.gender;
      _dob = m.dateOfBirth;
      _bloodGroup = m.bloodGroup;
      _heightController.text = m.height?.toString() ?? '';
      _weightController.text = m.weight?.toString() ?? '';
      _allergies = List<String>.from(m.allergies);
      _conditions = List<String>.from(m.chronicConditions);
      _emergencyController.text = m.emergencyContact ?? '';
      _insuranceController.text = m.insuranceInfo ?? '';
      _notesController.text = m.notes ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _emergencyController.dispose();
    _insuranceController.dispose();
    _notesController.dispose();
    _allergyController.dispose();
    _conditionController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final member = FamilyMember(
      id: widget.member?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      relation: _relation,
      gender: _gender,
      dateOfBirth: _dob,
      bloodGroup: _bloodGroup,
      height: double.tryParse(_heightController.text),
      weight: double.tryParse(_weightController.text),
      allergies: _allergies,
      chronicConditions: _conditions,
      emergencyContact: _emergencyController.text.trim().isEmpty
          ? null
          : _emergencyController.text.trim(),
      insuranceInfo: _insuranceController.text.trim().isEmpty
          ? null
          : _insuranceController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );
    Navigator.pop(context, member);
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
            // Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_rounded),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Please enter a name' : null,
            ),
            const SizedBox(height: 16),

            // Relation
            DropdownButtonFormField<Relation>(
              value: _relation,
              decoration: const InputDecoration(
                labelText: 'Relation',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.group_rounded),
              ),
              items: Relation.values
                  .map((r) =>
                      DropdownMenuItem(value: r, child: Text(r.label)))
                  .toList(),
              onChanged: (v) => setState(() => _relation = v!),
            ),
            const SizedBox(height: 16),

            // Gender
            const Text('Gender',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            SegmentedButton<Gender>(
              segments: Gender.values
                  .map((g) => ButtonSegment(
                      value: g, label: Text(g.label), icon: Icon(g.icon)))
                  .toList(),
              selected: {_gender},
              onSelectionChanged: (s) => setState(() => _gender = s.first),
            ),
            const SizedBox(height: 16),

            // Date of Birth
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.cake_rounded),
              title: Text(
                _dob == null
                    ? 'Date of Birth'
                    : DateFormat('dd MMM yyyy').format(_dob!),
              ),
              subtitle:
                  _dob == null ? null : const Text('Tap to change'),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _dob ?? DateTime(2000),
                  firstDate: DateTime(1920),
                  lastDate: DateTime.now(),
                );
                if (date != null) setState(() => _dob = date);
              },
            ),
            const SizedBox(height: 8),

            // Blood Group
            DropdownButtonFormField<BloodGroup>(
              value: _bloodGroup,
              decoration: const InputDecoration(
                labelText: 'Blood Group',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.bloodtype_rounded),
              ),
              items: BloodGroup.values
                  .map((b) =>
                      DropdownMenuItem(value: b, child: Text(b.label)))
                  .toList(),
              onChanged: (v) => setState(() => _bloodGroup = v!),
            ),
            const SizedBox(height: 16),

            // Height / Weight
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _heightController,
                    decoration: const InputDecoration(
                      labelText: 'Height (cm)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _weightController,
                    decoration: const InputDecoration(
                      labelText: 'Weight (kg)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Allergies
            _ChipAddField(
              label: 'Allergies',
              controller: _allergyController,
              items: _allergies,
              chipColor: Colors.red,
              onAdd: (v) => setState(() => _allergies.add(v)),
              onRemove: (v) => setState(() => _allergies.remove(v)),
            ),
            const SizedBox(height: 16),

            // Chronic Conditions
            _ChipAddField(
              label: 'Chronic Conditions',
              controller: _conditionController,
              items: _conditions,
              chipColor: Colors.orange,
              onAdd: (v) => setState(() => _conditions.add(v)),
              onRemove: (v) => setState(() => _conditions.remove(v)),
            ),
            const SizedBox(height: 16),

            // Emergency Contact
            TextFormField(
              controller: _emergencyController,
              decoration: const InputDecoration(
                labelText: 'Emergency Contact',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone_rounded),
              ),
            ),
            const SizedBox(height: 16),

            // Insurance Info
            TextFormField(
              controller: _insuranceController,
              decoration: const InputDecoration(
                labelText: 'Insurance Info',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.shield_rounded),
              ),
            ),
            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notes_rounded),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Save
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(_isEditing ? 'Update Member' : 'Save Member',
                  style: const TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _ChipAddField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final List<String> items;
  final Color chipColor;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;

  const _ChipAddField({
    required this.label,
    required this.controller,
    required this.items,
    required this.chipColor,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: label,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {
                final text = controller.text.trim();
                if (text.isNotEmpty) {
                  onAdd(text);
                  controller.clear();
                }
              },
              icon: Icon(Icons.add_circle_rounded, color: chipColor),
            ),
          ],
        ),
        if (items.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: items
                .map((item) => Chip(
                      label: Text(item,
                          style:
                              TextStyle(fontSize: 12, color: chipColor)),
                      backgroundColor:
                          chipColor.withValues(alpha: 0.08),
                      deleteIcon: Icon(Icons.close, size: 16, color: chipColor),
                      onDeleted: () => onRemove(item),
                      materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 6. AddRecordPage
// ══════════════════════════════════════════════════════════════════════════════

class AddRecordPage extends StatefulWidget {
  final String memberId;
  final MedicalRecord? record;

  const AddRecordPage({Key? key, required this.memberId, this.record})
      : super(key: key);

  @override
  State<AddRecordPage> createState() => _AddRecordPageState();
}

class _AddRecordPageState extends State<AddRecordPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _doctorController = TextEditingController();
  final _hospitalController = TextEditingController();
  final _specialityController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _notesController = TextEditingController();
  final _amountController = TextEditingController();
  final _symptomController = TextEditingController();

  RecordType _recordType = RecordType.consultation;
  DateTime _date = DateTime.now();
  bool _hasFollowUp = false;
  DateTime? _followUpDate;
  List<String> _symptoms = [];
  List<Medication> _medications = [];
  List<LabResult> _labResults = [];
  bool _isCovered = false;

  bool get _isEditing => widget.record != null;

  @override
  void initState() {
    super.initState();
    if (widget.record != null) {
      final r = widget.record!;
      _recordType = r.type;
      _titleController.text = r.title;
      _doctorController.text = r.doctorName ?? '';
      _hospitalController.text = r.hospitalName ?? '';
      _specialityController.text = r.speciality ?? '';
      _date = r.date;
      _hasFollowUp = r.followUpDate != null;
      _followUpDate = r.followUpDate;
      _diagnosisController.text = r.diagnosis ?? '';
      _symptoms = List<String>.from(r.symptoms);
      _medications = List<Medication>.from(r.medications);
      _labResults = List<LabResult>.from(r.labResults);
      _amountController.text =
          r.amount != null ? r.amount!.toStringAsFixed(0) : '';
      _isCovered = r.isCovered;
      _notesController.text = r.notes ?? '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _doctorController.dispose();
    _hospitalController.dispose();
    _specialityController.dispose();
    _diagnosisController.dispose();
    _notesController.dispose();
    _amountController.dispose();
    _symptomController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final record = MedicalRecord(
      id: widget.record?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      memberId: widget.memberId,
      type: _recordType,
      title: _titleController.text.trim(),
      doctorName: _doctorController.text.trim().isEmpty
          ? null
          : _doctorController.text.trim(),
      hospitalName: _hospitalController.text.trim().isEmpty
          ? null
          : _hospitalController.text.trim(),
      speciality: _specialityController.text.trim().isEmpty
          ? null
          : _specialityController.text.trim(),
      date: _date,
      followUpDate: _hasFollowUp ? _followUpDate : null,
      diagnosis: _diagnosisController.text.trim().isEmpty
          ? null
          : _diagnosisController.text.trim(),
      symptoms: _symptoms,
      medications: _medications,
      labResults: _labResults,
      amount: double.tryParse(_amountController.text),
      isCovered: _isCovered,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );
    Navigator.pop(context, record);
  }

  void _addMedication() {
    _showMedicationSheet(null, (med) {
      setState(() => _medications.add(med));
    });
  }

  void _editMedication(int index) {
    _showMedicationSheet(_medications[index], (med) {
      setState(() => _medications[index] = med);
    });
  }

  void _showMedicationSheet(
      Medication? existing, ValueChanged<Medication> onSave) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final dosageCtrl = TextEditingController(text: existing?.dosage ?? '');
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');
    var freq = existing?.frequency ?? MedicationFrequency.onceDaily;
    var meal = existing?.mealTiming ?? MealTiming.afterFood;
    var morning = existing?.morning ?? false;
    var afternoon = existing?.afternoon ?? false;
    var evening = existing?.evening ?? false;
    var night = existing?.night ?? false;
    var startDate = existing?.startDate;
    var endDate = existing?.endDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    existing != null ? 'Edit Medication' : 'Add Medication',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Name *',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: dosageCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Dosage (e.g. 500mg)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<MedicationFrequency>(
                    value: freq,
                    decoration: const InputDecoration(
                      labelText: 'Frequency',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: MedicationFrequency.values
                        .map((f) => DropdownMenuItem(
                            value: f, child: Text(f.label)))
                        .toList(),
                    onChanged: (v) =>
                        setSheetState(() => freq = v!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<MealTiming>(
                    value: meal,
                    decoration: const InputDecoration(
                      labelText: 'Meal Timing',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: MealTiming.values
                        .map((m) => DropdownMenuItem(
                            value: m, child: Text(m.label)))
                        .toList(),
                    onChanged: (v) =>
                        setSheetState(() => meal = v!),
                  ),
                  const SizedBox(height: 12),
                  const Text('Timing',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('Morning'),
                        selected: morning,
                        onSelected: (v) =>
                            setSheetState(() => morning = v),
                      ),
                      FilterChip(
                        label: const Text('Afternoon'),
                        selected: afternoon,
                        onSelected: (v) =>
                            setSheetState(() => afternoon = v),
                      ),
                      FilterChip(
                        label: const Text('Evening'),
                        selected: evening,
                        onSelected: (v) =>
                            setSheetState(() => evening = v),
                      ),
                      FilterChip(
                        label: const Text('Night'),
                        selected: night,
                        onSelected: (v) =>
                            setSheetState(() => night = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: Text(
                            startDate == null
                                ? 'Start Date'
                                : DateFormat('dd MMM').format(startDate!),
                            style: const TextStyle(fontSize: 13),
                          ),
                          leading:
                              const Icon(Icons.calendar_today, size: 18),
                          onTap: () async {
                            final d = await showDatePicker(
                              context: ctx,
                              initialDate: startDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (d != null) {
                              setSheetState(() => startDate = d);
                            }
                          },
                        ),
                      ),
                      Expanded(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: Text(
                            endDate == null
                                ? 'End Date'
                                : DateFormat('dd MMM').format(endDate!),
                            style: const TextStyle(fontSize: 13),
                          ),
                          leading:
                              const Icon(Icons.calendar_today, size: 18),
                          onTap: () async {
                            final d = await showDatePicker(
                              context: ctx,
                              initialDate: endDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (d != null) {
                              setSheetState(() => endDate = d);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (nameCtrl.text.trim().isEmpty) return;
                        onSave(Medication(
                          name: nameCtrl.text.trim(),
                          dosage: dosageCtrl.text.trim().isEmpty
                              ? null
                              : dosageCtrl.text.trim(),
                          frequency: freq,
                          mealTiming: meal,
                          morning: morning,
                          afternoon: afternoon,
                          evening: evening,
                          night: night,
                          startDate: startDate,
                          endDate: endDate,
                          notes: notesCtrl.text.trim().isEmpty
                              ? null
                              : notesCtrl.text.trim(),
                        ));
                        Navigator.pop(ctx);
                      },
                      child: Text(existing != null ? 'Update' : 'Add'),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  void _addLabResult() {
    _showLabResultSheet(null, (lr) {
      setState(() => _labResults.add(lr));
    });
  }

  void _showLabResultSheet(
      LabResult? existing, ValueChanged<LabResult> onSave) {
    final testCtrl =
        TextEditingController(text: existing?.testName ?? '');
    final valueCtrl =
        TextEditingController(text: existing?.value ?? '');
    final unitCtrl =
        TextEditingController(text: existing?.unit ?? '');
    final rangeCtrl =
        TextEditingController(text: existing?.normalRange ?? '');
    var isAbnormal = existing?.isAbnormal ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Add Lab Result',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: testCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Test Name *',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: valueCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Value',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: unitCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Unit',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: rangeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Normal Range',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Abnormal',
                        style: TextStyle(fontSize: 14)),
                    value: isAbnormal,
                    onChanged: (v) =>
                        setSheetState(() => isAbnormal = v),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (testCtrl.text.trim().isEmpty) return;
                        onSave(LabResult(
                          testName: testCtrl.text.trim(),
                          value: valueCtrl.text.trim().isEmpty
                              ? null
                              : valueCtrl.text.trim(),
                          unit: unitCtrl.text.trim().isEmpty
                              ? null
                              : unitCtrl.text.trim(),
                          normalRange: rangeCtrl.text.trim().isEmpty
                              ? null
                              : rangeCtrl.text.trim(),
                          isAbnormal: isAbnormal,
                        ));
                        Navigator.pop(ctx);
                      },
                      child: const Text('Add'),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Record' : 'Add Record'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Record Type
            DropdownButtonFormField<RecordType>(
              value: _recordType,
              decoration: const InputDecoration(
                labelText: 'Record Type',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category_rounded),
              ),
              items: RecordType.values
                  .map((t) => DropdownMenuItem(
                        value: t,
                        child: Row(
                          children: [
                            Icon(t.icon, size: 18, color: t.color),
                            const SizedBox(width: 8),
                            Text(t.label),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _recordType = v!),
            ),
            const SizedBox(height: 16),

            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title_rounded),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Please enter a title' : null,
            ),
            const SizedBox(height: 16),

            // Doctor
            TextFormField(
              controller: _doctorController,
              decoration: const InputDecoration(
                labelText: 'Doctor Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_rounded),
              ),
            ),
            const SizedBox(height: 16),

            // Hospital
            TextFormField(
              controller: _hospitalController,
              decoration: const InputDecoration(
                labelText: 'Hospital Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.local_hospital_rounded),
              ),
            ),
            const SizedBox(height: 16),

            // Speciality
            TextFormField(
              controller: _specialityController,
              decoration: const InputDecoration(
                labelText: 'Speciality',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.medical_information_rounded),
              ),
            ),
            const SizedBox(height: 16),

            // Date
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_rounded),
              title: Text(DateFormat('dd MMM yyyy').format(_date)),
              subtitle: const Text('Date'),
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (d != null) setState(() => _date = d);
              },
            ),

            // Follow-up
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Follow-up Date',
                  style: TextStyle(fontSize: 14)),
              value: _hasFollowUp,
              onChanged: (v) => setState(() {
                _hasFollowUp = v;
                if (v && _followUpDate == null) {
                  _followUpDate =
                      DateTime.now().add(const Duration(days: 14));
                }
              }),
            ),
            if (_hasFollowUp)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_rounded),
                title: Text(
                  _followUpDate == null
                      ? 'Pick date'
                      : DateFormat('dd MMM yyyy').format(_followUpDate!),
                ),
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate:
                        _followUpDate ?? DateTime.now().add(const Duration(days: 14)),
                    firstDate: DateTime.now(),
                    lastDate:
                        DateTime.now().add(const Duration(days: 365)),
                  );
                  if (d != null) setState(() => _followUpDate = d);
                },
              ),
            const SizedBox(height: 8),

            // Diagnosis
            TextFormField(
              controller: _diagnosisController,
              decoration: const InputDecoration(
                labelText: 'Diagnosis',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description_rounded),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Symptoms
            _ChipAddField(
              label: 'Symptoms',
              controller: _symptomController,
              items: _symptoms,
              chipColor: Colors.purple,
              onAdd: (v) => setState(() => _symptoms.add(v)),
              onRemove: (v) => setState(() => _symptoms.remove(v)),
            ),
            const SizedBox(height: 20),

            // ── Medications Section ──────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Medications',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                TextButton.icon(
                  onPressed: _addMedication,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                ),
              ],
            ),
            if (_medications.isNotEmpty)
              ..._medications.asMap().entries.map((entry) {
                final i = entry.key;
                final med = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(10),
                    border: Border(
                      left: BorderSide(
                          color: Colors.teal[400]!, width: 3),
                    ),
                  ),
                  child: ListTile(
                    dense: true,
                    title: Text(med.name,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500)),
                    subtitle: Text(
                      [
                        if (med.dosage != null) med.dosage!,
                        med.frequency.label,
                      ].join(' \u00B7 '),
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey[500]),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () => _editMedication(i),
                          child: Icon(Icons.edit_outlined,
                              size: 18, color: Colors.grey[500]),
                        ),
                        const SizedBox(width: 12),
                        InkWell(
                          onTap: () => setState(
                              () => _medications.removeAt(i)),
                          child: Icon(Icons.delete_outline_rounded,
                              size: 18, color: Colors.red[300]),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            const SizedBox(height: 16),

            // ── Lab Results Section ──────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Lab Results',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                TextButton.icon(
                  onPressed: _addLabResult,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                ),
              ],
            ),
            if (_labResults.isNotEmpty)
              ..._labResults.asMap().entries.map((entry) {
                final i = entry.key;
                final lr = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: lr.isAbnormal
                        ? Colors.red.withValues(alpha: 0.04)
                        : Colors.grey.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(8),
                    border: Border(
                      left: BorderSide(
                        color: lr.isAbnormal
                            ? Colors.red[400]!
                            : Colors.grey[400]!,
                        width: 3,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(lr.testName,
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500)),
                            Text(
                              '${lr.value ?? '-'} ${lr.unit ?? ''} (${lr.normalRange ?? '-'})',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                      if (lr.isAbnormal)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('Abnormal',
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red[700])),
                        ),
                      InkWell(
                        onTap: () =>
                            setState(() => _labResults.removeAt(i)),
                        child: Icon(Icons.delete_outline_rounded,
                            size: 18, color: Colors.red[300]),
                      ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 16),

            // Amount
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(),
                prefixText: '\u20B9 ',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),

            // Insurance
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Covered by insurance',
                  style: TextStyle(fontSize: 14)),
              value: _isCovered,
              onChanged: (v) => setState(() => _isCovered = v),
            ),
            const SizedBox(height: 8),

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notes_rounded),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Save
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(_isEditing ? 'Update Record' : 'Save Record',
                  style: const TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
