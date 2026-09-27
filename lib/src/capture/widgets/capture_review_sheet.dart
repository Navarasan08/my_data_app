import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:my_data_app/src/capture/cubit/capture_cubit.dart';
import 'package:my_data_app/src/capture/cubit/capture_state.dart';
import 'package:my_data_app/src/capture/pending_capture.dart';
import 'package:my_data_app/src/home/cubit/home_record_cubit.dart';
import 'package:my_data_app/src/home/home_record_model.dart';
import 'package:my_data_app/src/home/home_record_page.dart';

/// Bottom sheet listing auto-captured payments. Each entry can be turned
/// into a record (opens [AddHomeRecordPage] prefilled) or dismissed.
class CaptureReviewSheet extends StatelessWidget {
  const CaptureReviewSheet({Key? key}) : super(key: key);

  /// Present the sheet, re-providing the two cubits since a modal sheet
  /// lives above the shell's provider scope.
  static Future<void> show(
    BuildContext context,
    HomeRecordCubit homeCubit,
    CaptureCubit captureCubit,
  ) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: homeCubit),
          BlocProvider.value(value: captureCubit),
        ],
        child: const CaptureReviewSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return BlocBuilder<CaptureCubit, CaptureState>(
      builder: (context, state) {
        final captureCubit = context.read<CaptureCubit>();
        final homeCubit = context.read<HomeRecordCubit>();
        final pending = state.pending.reversed.toList(); // newest first

        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.35,
          maxChildSize: 0.92,
          expand: false,
          builder: (_, scrollController) => Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
                child: Row(
                  children: [
                    Icon(Icons.notifications_active_rounded,
                        size: 18, color: Colors.amber[800]),
                    const SizedBox(width: 8),
                    const Text(
                      'Detected payments',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: pending.isEmpty
                          ? null
                          : () => captureCubit.removeAll(),
                      child: const Text('Clear all'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: pending.isEmpty
                    ? Center(
                        child: Text(
                          'Nothing to review',
                          style: TextStyle(
                            fontSize: 13,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: pending.length,
                        itemBuilder: (_, i) => _CaptureTile(
                          capture: pending[i],
                          homeCubit: homeCubit,
                          captureCubit: captureCubit,
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

class _CaptureTile extends StatelessWidget {
  final PendingCapture capture;
  final HomeRecordCubit homeCubit;
  final CaptureCubit captureCubit;

  const _CaptureTile({
    required this.capture,
    required this.homeCubit,
    required this.captureCubit,
  });

  Future<void> _addAsRecord(BuildContext context) async {
    final record = await Navigator.push<HomeRecord>(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: homeCubit,
          child: AddHomeRecordPage(
            categories: homeCubit.allCategories,
            paymentTypes: homeCubit.paymentTypes,
            initialDate: capture.capturedAt,
            prefillTitle: capture.counterparty.isEmpty
                ? '${capture.sourceApp} payment'
                : capture.counterparty,
            prefillAmount: capture.amount,
            prefillIsIncome: capture.isIncome,
          ),
        ),
      ),
    );
    if (record != null) {
      homeCubit.addRecord(record);
      captureCubit.remove(capture.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = capture.isIncome ? Colors.green[700]! : Colors.red[700]!;

    return ListTile(
      dense: true,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          capture.isIncome
              ? Icons.arrow_downward_rounded
              : Icons.arrow_upward_rounded,
          size: 18,
          color: color,
        ),
      ),
      title: Text(
        [
          homeCubit.formatAmount(capture.amount, decimals: 2),
          if (capture.counterparty.isNotEmpty) capture.counterparty,
        ].join('  ·  '),
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${capture.sourceApp}  ·  '
        '${DateFormat('d MMM, h:mm a').format(capture.capturedAt)}'
        '${capture.isIncome ? '  ·  Income' : ''}',
        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            onPressed: () => _addAsRecord(context),
            child: const Text('Add', style: TextStyle(fontSize: 12)),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded,
                size: 18, color: cs.onSurfaceVariant),
            tooltip: 'Dismiss',
            visualDensity: VisualDensity.compact,
            onPressed: () => captureCubit.remove(capture.id),
          ),
        ],
      ),
    );
  }
}
