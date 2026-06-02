import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Shows the app's version and build number, e.g. `v1.0.0 (1)`.
///
/// Loads [PackageInfo] once and caches it statically so repeated uses (splash,
/// dashboard, etc.) don't each hit the platform channel. Renders nothing until
/// the info is available, so it can be dropped anywhere without layout jank.
class AppVersionText extends StatefulWidget {
  final TextStyle? style;

  /// Prefix shown before the version number. Defaults to `v`.
  final String prefix;

  const AppVersionText({super.key, this.style, this.prefix = 'v'});

  @override
  State<AppVersionText> createState() => _AppVersionTextState();
}

class _AppVersionTextState extends State<AppVersionText> {
  static PackageInfo? _cached;
  PackageInfo? _info;

  @override
  void initState() {
    super.initState();
    if (_cached != null) {
      _info = _cached;
    } else {
      PackageInfo.fromPlatform().then((value) {
        _cached = value;
        if (mounted) setState(() => _info = value);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = _info;
    if (info == null) return const SizedBox.shrink();
    return Text(
      '${widget.prefix}${info.version} (${info.buildNumber})',
      style: widget.style,
    );
  }
}
