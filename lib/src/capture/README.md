# Payment auto-capture (Android, sideload builds only)

Reads payment notifications (GPay, PhonePe, Paytm, BHIM, Amazon Pay,
WhatsApp Pay) via Android's `NotificationListenerService`, parses out
amount / payee / direction, and queues them as **pending captures**. The
Expense Tracker shows a "payments detected" banner; reviewing opens the
add-record form prefilled — the user picks a category and saves.

## Pieces

- `capture_config.dart` — `autoCaptureSupported` gate (compile-time flag +
  Android-only platform check). Every UI entry point and plugin call sits
  behind it.
- `payment_notification_parser.dart` — pure-Dart regex parser
  (unit-tested in `test/capture/`). Rejects promos, requests, failures.
- `pending_capture.dart` — model + SharedPreferences store (device-local;
  suggestions are never synced, only saved records are).
- `cubit/capture_cubit.dart` — permission handling, notification stream
  subscription, dedupe, pending queue.
- `widgets/capture_review_sheet.dart` — review bottom sheet.

The runtime toggle lives in Expense Tracker → Settings → Automation and is
**off by default**; enabling it requests the system "Notification access"
permission.

## Limitations

- Captures happen while the app process is alive (foreground or backgrounded
  but not killed). Payments made while the app is fully stopped are missed.
- Web/iOS: feature is entirely absent (`autoCaptureSupported` is false).

## Publishing to the Play Store — REQUIRED steps

Google Play flags apps that request notification access. A store build must
exclude this feature *and* its manifest footprint:

1. **Disable the Dart code** (removes all UI/logic via tree-shaking):

   ```
   flutter build appbundle --dart-define=AUTO_CAPTURE=false
   ```

2. **Strip the plugin's manifest entries.** The `notification_listener_service`
   plugin merges a `<service>` with
   `android.permission.BIND_NOTIFICATION_LISTENER_SERVICE` into the final
   manifest even when the Dart side is disabled. Check the merged manifest
   (`android/app/build/intermediates/merged_manifests/...`) for the service's
   fully-qualified class name, then remove it in
   `android/app/src/main/AndroidManifest.xml` inside `<application>`:

   ```xml
   <service
       android:name="notification.listener.service.NotificationListener"
       tools:node="remove" />
   ```

   (add `xmlns:tools="http://schemas.android.com/tools"` on the `<manifest>`
   root if missing). For a cleaner setup, do this in a `store` product
   flavor's manifest so the sideload build keeps the service.

   Alternatively, simply remove the `notification_listener_service`
   dependency from `pubspec.yaml` for the store release — the only code
   importing it is `cubit/capture_cubit.dart`.
