import 'package:my_data_app/src/capture/pending_capture.dart';

class CaptureState {
  /// The user's settings toggle (persisted). Capture only actually runs when
  /// this is on AND [permissionGranted].
  final bool enabled;

  /// Whether the system "Notification access" permission is granted.
  final bool permissionGranted;

  /// Detected payments awaiting review, oldest first.
  final List<PendingCapture> pending;

  const CaptureState({
    this.enabled = false,
    this.permissionGranted = false,
    this.pending = const [],
  });

  CaptureState copyWith({
    bool? enabled,
    bool? permissionGranted,
    List<PendingCapture>? pending,
  }) {
    return CaptureState(
      enabled: enabled ?? this.enabled,
      permissionGranted: permissionGranted ?? this.permissionGranted,
      pending: pending ?? this.pending,
    );
  }
}
