import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:my_data_app/src/chits/cubit/chit_cubit.dart';
import 'package:my_data_app/src/dashboard/dashboard_settings_cubit.dart';
import 'package:my_data_app/src/home/cubit/home_record_cubit.dart';
import 'package:my_data_app/src/interest/cubit/interest_cubit.dart';
import 'package:my_data_app/src/loans/cubit/loan_cubit.dart';
import 'package:my_data_app/src/money_owe/cubit/money_owe_cubit.dart';
import 'package:my_data_app/src/monthly_stats/monthly_summary.dart';
import 'package:my_data_app/src/reminder/cubit/bill_cubit.dart';
import 'package:my_data_app/src/shell/feature_pages.dart';
import 'package:my_data_app/src/vehicle/cubit/vehicle_cubit.dart';

// Chalkboard palette. The page keeps its blackboard look in both themes.
const _board = Color(0xFF1E2224);
const _chalk = Color(0xFFF2F0E4);
const _chalkDim = Color(0x99F2F0E4);
const _chalkGreen = Color(0xFF7BD88F);
const _chalkRed = Color(0xFFFF7A70);
const _chalkBlue = Color(0xFF7EC8F2);

/// The month's money on one blackboard: income at the top, every commitment
/// (bills, EMIs, chits, interest, debts, household and vehicle spend)
/// itemised beneath, tallied to a single balance. Reads every finance cubit
/// live; it owns no data of its own.
class MonthlyStatsPage extends StatefulWidget {
  const MonthlyStatsPage({super.key});

  @override
  State<MonthlyStatsPage> createState() => _MonthlyStatsPageState();
}

class _MonthlyStatsPageState extends State<MonthlyStatsPage> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  void _changeMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  void _openFeature(BuildContext context, String featureId) {
    final page = buildFeaturePage(context, featureId);
    if (page == null) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  /// Bottom sheet with a switch per ledger line. Toggles persist through
  /// [DashboardSettingsCubit] and sync across devices.
  void _showItemSettings(BuildContext context, MonthlySummary summary) {
    final settingsCubit = context.read<DashboardSettingsCubit>();
    showModalBottomSheet(
      context: context,
      backgroundColor: _board,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => BlocProvider.value(
        value: settingsCubit,
        child: BlocBuilder<DashboardSettingsCubit, DashboardSettingsState>(
          builder: (context, settings) {
            final hidden = settings.hiddenMonthlyStatItems;
            return SafeArea(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text(
                      'Items on the board',
                      style: _chalkStyle(19, bold: true),
                    ),
                  ),
                  SwitchListTile(
                    value: settings.showZeroMonthlyStatItems,
                    onChanged: settingsCubit.setShowZeroMonthlyStatItems,
                    title: Text('Show items at 0', style: _chalkStyle(16)),
                    subtitle: Text(
                      'Keep lines with nothing this month on the board',
                      style: _chalkStyle(12, color: _chalkDim),
                    ),
                    activeTrackColor: _chalkGreen,
                    inactiveTrackColor: Colors.white12,
                    dense: true,
                  ),
                  const Divider(color: Colors.white12, height: 16),
                  for (final item in summary.items)
                    SwitchListTile(
                      value: !hidden.contains(item.id),
                      onChanged: (_) =>
                          settingsCubit.toggleMonthlyStatItem(item.id),
                      title: Text(
                        item.label,
                        style: _chalkStyle(16),
                      ),
                      subtitle: Text(
                        item.isIncome ? 'Income' : 'Outgoing',
                        style: _chalkStyle(12, color: _chalkDim),
                      ),
                      activeTrackColor: _chalkGreen,
                      inactiveTrackColor: Colors.white12,
                      dense: true,
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final homeCubit = context.watch<HomeRecordCubit>();
    final homeState = homeCubit.state;
    final billState = context.watch<BillCubit>().state;
    final loanState = context.watch<LoanCubit>().state;
    final moneyOweState = context.watch<MoneyOweCubit>().state;
    final vehicleState = context.watch<VehicleCubit>().state;
    final chitState = context.watch<ChitCubit>().state;
    final interestState = context.watch<InterestCubit>().state;

    final summary = MonthlySummary.compute(
      month: _month,
      homeWindow: homeCubit.cycleWindowForMonth(_month.year, _month.month),
      records: homeState.records,
      bills: billState.bills,
      loans: loanState.loans,
      debts: moneyOweState.entries,
      vehicles: vehicleState.vehicles,
      chitFunds: chitState.chitFunds,
      interestRecords: interestState.records,
    );

    String money(double v) =>
        homeState.currency.format(v, decimals: v % 1 == 0 ? 0 : 2);

    // Enabled items show biggest first. Lines switched off in settings are
    // left out of the tally too; zero-amount lines can optionally be hidden
    // (they never affect the tally either way).
    final boardSettings = context.watch<DashboardSettingsCubit>().state;
    final hidden = boardSettings.hiddenMonthlyStatItems;
    final showZero = boardSettings.showZeroMonthlyStatItems;
    bool visible(MonthlyStatItem i) =>
        !hidden.contains(i.id) && (showZero || i.amount != 0);
    final incomeRows = summary.incomeItems.where(visible).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    final outgoingRows = summary.outgoingItems.where(visible).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    final totalIncome = incomeRows.fold(0.0, (s, i) => s + i.amount);
    final totalOutgoing = outgoingRows.fold(0.0, (s, i) => s + i.amount);
    final balance = totalIncome - totalOutgoing;
    final positive = balance >= 0;

    return Scaffold(
      backgroundColor: _board,
      appBar: AppBar(
        backgroundColor: _board,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 48,
        iconTheme: const IconThemeData(color: _chalk),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.chevron_left_rounded, color: _chalk),
              onPressed: () => _changeMonth(-1),
            ),
            Text(
              DateFormat('MMMM yyyy').format(_month),
              style: _chalkStyle(20, bold: true),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.chevron_right_rounded, color: _chalk),
              onPressed: () => _changeMonth(1),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: _chalk),
            tooltip: 'Choose items',
            onPressed: () => _showItemSettings(context, summary),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          _RatioBar(income: totalIncome, expense: totalOutgoing),
          const SizedBox(height: 18),
          _LedgerLine(
            label: 'Income',
            amount: money(totalIncome),
            amountColor: _chalkGreen,
            heading: true,
            onTap: () => _openFeature(context, 'home'),
          ),
          for (final i in incomeRows)
            _LedgerLine(
              label: i.label,
              detail: i.detail,
              amount: money(i.amount),
              indent: true,
              onTap: () => _openFeature(context, i.featureId),
            ),
          const SizedBox(height: 14),
          _LedgerLine(
            label: 'Expense',
            amount: money(totalOutgoing),
            amountColor: _chalkRed,
            heading: true,
            onTap: () => _openFeature(context, 'home'),
          ),
          for (final i in outgoingRows)
            _LedgerLine(
              label: i.label,
              detail: i.detail,
              amount: money(i.amount),
              indent: true,
              onTap: () => _openFeature(context, i.featureId),
            ),
          const SizedBox(height: 18),
          const _DashedRule(),
          const SizedBox(height: 14),
          _LedgerLine(
            label: 'Balance',
            amount: '${positive ? '+' : '−'}${money(balance.abs())}',
            amountColor: positive ? _chalkBlue : _chalkRed,
            heading: true,
          ),
        ],
      ),
    );
  }
}

TextStyle _chalkStyle(
  double size, {
  Color color = _chalk,
  bool bold = false,
}) {
  return GoogleFonts.patrickHand(
    fontSize: size,
    color: color,
    fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
    letterSpacing: 0.5,
  );
}

/// The green/red income-vs-expense proportion bar at the top of the board.
class _RatioBar extends StatelessWidget {
  final double income;
  final double expense;

  const _RatioBar({required this.income, required this.expense});

  @override
  Widget build(BuildContext context) {
    final total = income + expense;
    final greenShare = total == 0 ? 0.5 : income / total;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          height: 12,
          child: Row(
            children: [
              Expanded(
                flex: (greenShare * 1000).round().clamp(1, 999),
                child: const ColoredBox(color: _chalkGreen),
              ),
              Expanded(
                flex: ((1 - greenShare) * 1000).round().clamp(1, 999),
                child: const ColoredBox(color: _chalkRed),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One handwritten ledger row: label left, amount right. Headings are large
/// and colored; item rows sit indented in plain chalk.
class _LedgerLine extends StatelessWidget {
  final String label;
  final String? detail;
  final String amount;
  final Color amountColor;
  final bool heading;
  final bool indent;
  final VoidCallback? onTap;

  const _LedgerLine({
    required this.label,
    this.detail,
    required this.amount,
    this.amountColor = _chalk,
    this.heading = false,
    this.indent = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = heading ? 24.0 : 19.0;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.fromLTRB(indent ? 28 : 8, 7, 8, 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(
                  text: label,
                  style: _chalkStyle(size, bold: heading),
                  children: [
                    if (detail != null)
                      TextSpan(
                        text: '   $detail',
                        style: _chalkStyle(13, color: _chalkDim),
                      ),
                  ],
                ),
              ),
            ),
            Text(
              amount,
              style: _chalkStyle(size, color: amountColor, bold: heading),
            ),
          ],
        ),
      ),
    );
  }
}

/// The hand-drawn dashed rule above the balance line.
class _DashedRule extends StatelessWidget {
  const _DashedRule();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 2,
      child: CustomPaint(
        painter: _DashPainter(),
        size: Size(double.infinity, 2),
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  const _DashPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _chalkDim
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    const dash = 8.0;
    const gap = 6.0;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 1), Offset(x + dash, 1), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
