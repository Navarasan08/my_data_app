import 'package:flutter/foundation.dart';

/// Compile-time switch for the payment auto-capture feature (notification
/// listener). Defaults to ON for local/sideload builds; a Play Store build
/// MUST disable it:
///
///   flutter build apk --dart-define=AUTO_CAPTURE=false
///
/// which tree-shakes every capture code path and UI entry point. See
/// `lib/src/capture/README.md` for how to also strip the listener service
/// from the Android manifest for store review.
const bool kAutoCaptureBuildEnabled =
    bool.fromEnvironment('AUTO_CAPTURE', defaultValue: true);

/// Whether auto-capture can run on this build + platform. Reading other
/// apps' notifications only exists on Android; web and iOS never support it.
bool get autoCaptureSupported =>
    kAutoCaptureBuildEnabled &&
    !kIsWeb &&
    defaultTargetPlatform == TargetPlatform.android;
