import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_data_app/src/groups/cubit/group_settings_cubit.dart';

/// User-level preferences for the Groups feature. These apply to every group
/// the user belongs to (it's a UI preference, not group-scoped) and sync
/// across the user's devices via Firestore.
class GroupSettingsPage extends StatelessWidget {
  const GroupSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Group settings'),
        centerTitle: true,
        elevation: 0,
      ),
      body: BlocBuilder<GroupSettingsCubit, GroupSettingsState>(
        builder: (context, state) {
          final cubit = context.read<GroupSettingsCubit>();
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: ListView(
                children: [
                  SwitchListTile(
                    title: const Text('Month-wise expense list'),
                    subtitle: const Text(
                        'Group expenses by month with subtotals instead of a flat list.'),
                    secondary:
                        const Icon(Icons.calendar_view_month_rounded),
                    value: state.monthwiseListView,
                    onChanged: cubit.setMonthwiseListView,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
