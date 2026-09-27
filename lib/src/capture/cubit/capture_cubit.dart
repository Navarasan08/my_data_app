import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notification_listener_service/notification_event.dart';
import 'package:notification_listener_service/notification_listener_service.dart';

import 'package:my_data_app/src/capture/capture_config.dart';
import 'package:my_data_app/src/capture/payment_notification_parser.dart';
import 'package:my_data_app/src/capture/pending_capture.dart';
import 'package:my_data_app/src/capture/cubit/capture_state.dart';

/// Listens (Android-only, behind [autoCaptureSupported]) to payment-app
/// notifications, parses them into [PendingCapture]s and keeps a reviewable
/// queue. Every plugin call is guarded so this cubit is inert on web/iOS
/// and on AUTO_CAPTURE=false store builds.
class CaptureCubit extends Cubit<CaptureState> {
  final PendingCaptureStore _store;
  StreamSubscription<ServiceNotificationEvent>? _sub;

  CaptureCubit({PendingCaptureStore? store})
      : _store = store ?? PendingCaptureStore(),
        super(const CaptureState());

  Future<void> init() async {
    if (!autoCaptureSupported) return;
    final enabled = await _store.getEnabled();
    final pending = await _store.load();
    bool granted = false;
    try {
      granted = await NotificationListenerService.isPermissionGranted();
    } catch (_) {
      // Plugin unavailable (e.g. hot-restart edge) — treat as not granted.
    }
    emit(CaptureState(
      enabled: enabled,
      permissionGranted: granted,
      pending: pending,
    ));
    if (enabled && granted) _listen();
  }

  /// Turn the feature on/off from settings. Turning it on requests the
  /// system notification-access permission when missing (this opens the
  /// system settings screen; call [refreshPermission] when the user comes
  /// back). Returns true when capture is actually running afterwards.
  Future<bool> setEnabled(bool value) async {
    if (!autoCaptureSupported) return false;
    if (!value) {
      await _store.setEnabled(false);
      await _sub?.cancel();
      _sub = null;
      emit(state.copyWith(enabled: false));
      return false;
    }

    bool granted = false;
    try {
      granted = await NotificationListenerService.isPermissionGranted();
      if (!granted) {
        // Opens the system "Notification access" settings screen.
        granted = await NotificationListenerService.requestPermission();
      }
    } catch (_) {
      granted = false;
    }
    await _store.setEnabled(true);
    emit(state.copyWith(enabled: true, permissionGranted: granted));
    if (granted) _listen();
    return granted;
  }

  /// Re-checks the permission (e.g. after returning from system settings)
  /// and starts listening if everything is now in place.
  Future<void> refreshPermission() async {
    if (!autoCaptureSupported) return;
    bool granted = false;
    try {
      granted = await NotificationListenerService.isPermissionGranted();
    } catch (_) {}
    emit(state.copyWith(permissionGranted: granted));
    if (state.enabled && granted) _listen();
  }

  void _listen() {
    if (_sub != null) return;
    _sub = NotificationListenerService.notificationsStream.listen(_onEvent);
  }

  void _onEvent(ServiceNotificationEvent event) {
    if (event.hasRemoved == true) return;
    final parsed = PaymentNotificationParser.parse(
      packageName: event.packageName ?? '',
      title: event.title,
      text: event.content,
    );
    if (parsed == null) return;

    final now = DateTime.now();
    // Dedupe: payment apps often re-post the same notification (summary +
    // detail). Same amount/counterparty/app within 3 minutes = duplicate.
    final duplicate = state.pending.any((p) =>
        p.amount == parsed.amount &&
        p.counterparty == parsed.counterparty &&
        p.sourceApp == parsed.sourceApp &&
        now.difference(p.capturedAt).inMinutes < 3);
    if (duplicate) return;

    final capture = PendingCapture(
      id: '${now.millisecondsSinceEpoch}_${state.pending.length}',
      amount: parsed.amount,
      counterparty: parsed.counterparty,
      isIncome: parsed.isIncome,
      sourceApp: parsed.sourceApp,
      capturedAt: now,
    );
    final next = [...state.pending, capture];
    emit(state.copyWith(pending: next));
    _store.save(next);
  }

  /// Remove a suggestion — used both for "dismiss" and after the user saved
  /// it as a record.
  Future<void> remove(String id) async {
    final next = state.pending.where((p) => p.id != id).toList();
    emit(state.copyWith(pending: next));
    await _store.save(next);
  }

  Future<void> removeAll() async {
    emit(state.copyWith(pending: const []));
    await _store.save(const []);
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
