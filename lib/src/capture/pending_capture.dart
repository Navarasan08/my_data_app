import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// A payment detected from another app's notification, waiting for the user
/// to review it (turn it into a HomeRecord or dismiss it). Device-local —
/// suggestions aren't synced to Firestore; only saved records are.
class PendingCapture {
  final String id;
  final double amount;
  final String counterparty;
  final bool isIncome;
  final String sourceApp;
  final DateTime capturedAt;

  const PendingCapture({
    required this.id,
    required this.amount,
    required this.counterparty,
    required this.isIncome,
    required this.sourceApp,
    required this.capturedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'counterparty': counterparty,
        'isIncome': isIncome,
        'sourceApp': sourceApp,
        'capturedAt': capturedAt.toIso8601String(),
      };

  factory PendingCapture.fromJson(Map<String, dynamic> json) =>
      PendingCapture(
        id: json['id'] as String,
        amount: (json['amount'] as num).toDouble(),
        counterparty: json['counterparty'] as String? ?? '',
        isIncome: json['isIncome'] as bool? ?? false,
        sourceApp: json['sourceApp'] as String? ?? '',
        capturedAt: DateTime.parse(json['capturedAt'] as String),
      );
}

/// SharedPreferences-backed store for the auto-capture toggle and the queue
/// of pending captures.
class PendingCaptureStore {
  static const _pendingKey = 'auto_capture_pending';
  static const _enabledKey = 'auto_capture_enabled';

  /// Oldest suggestions are dropped past this cap so the queue can't grow
  /// unbounded if the user ignores it for months.
  static const _maxPending = 50;

  Future<bool> getEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? false;
  }

  Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, value);
  }

  Future<List<PendingCapture>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) =>
              PendingCapture.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> save(List<PendingCapture> pending) async {
    final prefs = await SharedPreferences.getInstance();
    final capped = pending.length > _maxPending
        ? pending.sublist(pending.length - _maxPending)
        : pending;
    await prefs.setString(
        _pendingKey, jsonEncode(capped.map((c) => c.toJson()).toList()));
  }
}
