import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:my_data_app/src/core/sync/sync_snapshot.dart';

/// A hairline activity bar that runs while any module is still loading from
/// cache or waiting for the server, and sits invisible (but keeps its
/// height, so nothing shifts) once everything is live.
class SyncIndicator extends StatelessWidget {
  final ValueListenable<SyncStatus> status;
  final double height;

  const SyncIndicator({super.key, required this.status, this.height = 2});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SyncStatus>(
      valueListenable: status,
      builder: (context, s, _) => SizedBox(
        height: height,
        child: s.isLive
            ? null
            : LinearProgressIndicator(
                minHeight: height,
                backgroundColor: Colors.transparent,
              ),
      ),
    );
  }
}
