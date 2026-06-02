import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_data_app/src/home/cubit/home_record_cubit.dart';
import 'package:my_data_app/src/home/cubit/home_record_state.dart';
import 'package:my_data_app/src/home/home_categories_page.dart';
import 'package:my_data_app/src/home/home_payment_types_page.dart';
import 'package:my_data_app/src/home/widgets/expense_io_sheet.dart';

class HomeRecordSettingsPage extends StatelessWidget {
  const HomeRecordSettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeRecordCubit, HomeRecordState>(
      builder: (context, state) {
        final cs = Theme.of(context).colorScheme;
        final cubit = context.read<HomeRecordCubit>();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Settings'),
            centerTitle: true,
            elevation: 0,
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: ListView(
                children: [
                  const SizedBox(height: 8),

                  // Currency
                  _SettingsTile(
                    icon: Icons.attach_money_rounded,
                    iconColor: Colors.green[700]!,
                    title: 'Currency',
                    subtitle:
                        '${state.currency.symbol}  ${state.currency.name} (${state.currency.code})',
                    onTap: () => _showCurrencyDialog(context, cubit, state),
                  ),

                  // Categories
                  _SettingsTile(
                    icon: Icons.category_rounded,
                    iconColor: Colors.orange[700]!,
                    title: 'Categories',
                    subtitle: 'Default and custom expense categories',
                    onTap: () => _push(
                      context,
                      cubit,
                      const HomeCategoriesPage(),
                    ),
                  ),

                  // Payment Types
                  _SettingsTile(
                    icon: Icons.account_balance_wallet_rounded,
                    iconColor: Colors.purple[700]!,
                    title: 'Payment Types',
                    subtitle: 'Cash / UPI / card and more',
                    onTap: () => _push(
                      context,
                      cubit,
                      const HomePaymentTypesPage(),
                    ),
                  ),

                  // Export & Import
                  _SettingsTile(
                    icon: Icons.ios_share_rounded,
                    iconColor: Colors.blue[700]!,
                    title: 'Export & Import',
                    subtitle: 'CSV, Excel, email — or import from a file',
                    onTap: () => ExpenseIoSheet.show(context, cubit),
                  ),

                  const Divider(height: 24),

                  // Display preferences
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Text(
                      'Display',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                  SwitchListTile(
                    title: const Text('Month-wise calendar'),
                    subtitle: Text(
                      state.showMonthlyCalendar
                          ? 'Showing records by month with navigation'
                          : 'Showing all records in a single scrollable list',
                      style:
                          TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                    value: state.showMonthlyCalendar,
                    onChanged: (val) => cubit.setShowMonthlyCalendar(val),
                  ),

                  // Monthly start date + weekend handling
                  ListTile(
                    leading: const Icon(Icons.event_repeat_rounded),
                    title: const Text('Monthly start date'),
                    subtitle: Text(
                      'Day ${state.monthlyStartDay} · '
                      '${_weekendLabel(state.weekendAdjustment)}',
                      style:
                          TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                    trailing: Icon(Icons.chevron_right_rounded,
                        color: cs.onSurfaceVariant),
                    onTap: () => _showMonthlyCycleDialog(context, cubit, state),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _push(BuildContext context, HomeRecordCubit cubit, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(value: cubit, child: page),
      ),
    );
  }

  void _showMonthlyCycleDialog(
      BuildContext context, HomeRecordCubit cubit, HomeRecordState state) {
    showDialog(
      context: context,
      builder: (ctx) => _MonthlyCycleDialog(
        initialDay: state.monthlyStartDay,
        initialAdjustment: state.weekendAdjustment,
        onSave: (day, adjustment) {
          cubit.setMonthlyStartDay(day);
          cubit.setWeekendAdjustment(adjustment);
        },
      ),
    );
  }

  void _showCurrencyDialog(
      BuildContext context, HomeRecordCubit cubit, HomeRecordState state) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Currency'),
        content: SizedBox(
          width: 350,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: HomeCurrency.all.map((c) {
                final selected = c.code == state.currency.code;
                return ListTile(
                  leading: Text(
                    c.symbol,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                  title: Text('${c.name} (${c.code})',
                      style: const TextStyle(fontSize: 14)),
                  trailing: selected
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () {
                    cubit.setCurrency(c);
                    Navigator.pop(ctx);
                  },
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    Key? key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
        ),
        trailing: Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
        onTap: onTap,
      ),
    );
  }
}

String _weekendLabel(WeekendAdjustment adjustment) {
  switch (adjustment) {
    case WeekendAdjustment.exact:
      return 'Keep exact date';
    case WeekendAdjustment.previousFriday:
      return 'Previous Friday';
    case WeekendAdjustment.followingMonday:
      return 'Following Monday';
  }
}

class _MonthlyCycleDialog extends StatefulWidget {
  final int initialDay;
  final WeekendAdjustment initialAdjustment;
  final void Function(int day, WeekendAdjustment adjustment) onSave;

  const _MonthlyCycleDialog({
    required this.initialDay,
    required this.initialAdjustment,
    required this.onSave,
  });

  @override
  State<_MonthlyCycleDialog> createState() => _MonthlyCycleDialogState();
}

class _MonthlyCycleDialogState extends State<_MonthlyCycleDialog> {
  late int _day = widget.initialDay.clamp(1, 31);
  late WeekendAdjustment _adjustment = widget.initialAdjustment;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('Monthly start date'),
      content: SizedBox(
        width: 350,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'The day each monthly cycle begins. Days beyond a short month '
                '(e.g. 31 in February) fall back to that month\'s last day.',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Start day',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  DropdownButton<int>(
                    value: _day,
                    items: List.generate(31, (i) => i + 1)
                        .map((d) => DropdownMenuItem<int>(
                              value: d,
                              child: Text('$d'),
                            ))
                        .toList(),
                    onChanged: (d) {
                      if (d != null) setState(() => _day = d);
                    },
                  ),
                ],
              ),
              const Divider(height: 24),
              Text(
                'If it falls on a weekend',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              RadioGroup<WeekendAdjustment>(
                groupValue: _adjustment,
                onChanged: (val) {
                  if (val != null) setState(() => _adjustment = val);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: WeekendAdjustment.values.map((w) {
                    return RadioListTile<WeekendAdjustment>(
                      value: w,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(_weekendLabel(w)),
                      subtitle: w == WeekendAdjustment.exact
                          ? null
                          : Text(
                              w == WeekendAdjustment.previousFriday
                                  ? 'Move the start back to the previous Friday'
                                  : 'Move the start forward to the next Monday',
                              style: TextStyle(
                                  fontSize: 11, color: cs.onSurfaceVariant),
                            ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSave(_day, _adjustment);
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
