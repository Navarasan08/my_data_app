import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_data_app/src/dashboard/dashboard_settings_cubit.dart';

class DashboardSettingsPage extends StatelessWidget {
  const DashboardSettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardSettingsCubit, DashboardSettingsState>(
      builder: (context, state) {
        final cubit = context.read<DashboardSettingsCubit>();
        final features = state.features;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Dashboard Settings'),
            centerTitle: true,
            elevation: 0,
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Text(
                      'Drag to reorder, toggle to show/hide',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[500],
                      ),
                    ),
                  ),
                  Expanded(
                    child: ReorderableListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      itemCount: features.length,
                      onReorder: cubit.reorder,
                      proxyDecorator: (child, index, animation) {
                        return Material(
                          elevation: 4,
                          borderRadius: BorderRadius.circular(12),
                          child: child,
                        );
                      },
                      itemBuilder: (context, index) {
                        final feature = features[index];
                        return _FeatureSettingTile(
                          key: ValueKey(feature.id),
                          feature: feature,
                          onToggle: () =>
                              cubit.toggleVisibility(feature.id),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FeatureSettingTile extends StatelessWidget {
  final FeatureItem feature;
  final VoidCallback onToggle;

  const _FeatureSettingTile({
    Key? key,
    required this.feature,
    required this.onToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: feature.visible ? Colors.white : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: feature.visible ? Colors.grey[200]! : Colors.grey[300]!,
        ),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: feature.visible
                ? LinearGradient(colors: feature.gradient)
                : null,
            color: feature.visible ? null : Colors.grey[300],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(feature.icon, size: 20, color: Colors.white),
        ),
        title: Text(
          feature.title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: feature.visible ? Colors.black87 : Colors.grey[500],
          ),
        ),
        subtitle: Text(
          feature.visible ? 'Visible' : 'Hidden',
          style: TextStyle(
            fontSize: 12,
            color: feature.visible ? Colors.green[600] : Colors.grey[400],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: feature.visible,
              onChanged: (_) => onToggle(),
              activeColor: Colors.green,
            ),
            Icon(Icons.drag_handle_rounded,
                color: Colors.grey[400], size: 22),
          ],
        ),
      ),
    );
  }
}
