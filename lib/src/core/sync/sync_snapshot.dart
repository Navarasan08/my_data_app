/// Where the data currently held by a repository came from.
///
/// Firestore listeners fire first from the local cache and again once the
/// server has answered. Surfacing that distinction lets the UI tell "no data
/// yet confirmed" apart from "the user genuinely has no data" — the root of
/// the "empty screen that fills in later" bug the one-shot reads had.
enum SyncStatus {
  /// No snapshot has arrived yet (listener just attached).
  loading,

  /// Data came from the local cache; the server has not confirmed it yet.
  /// Typically lasts milliseconds when online, indefinitely when offline.
  cached,

  /// Data is confirmed by the server.
  live,
}

extension SyncStatusX on SyncStatus {
  bool get isLoading => this == SyncStatus.loading;
  bool get isLive => this == SyncStatus.live;
}

/// Folds several sources' statuses into one: `loading` wins over `cached`,
/// which wins over `live`. A repository made of multiple collections is only
/// live once every one of them is.
SyncStatus combineSyncStatus(Iterable<SyncStatus> statuses) {
  var result = SyncStatus.live;
  for (final s in statuses) {
    if (s == SyncStatus.loading) return SyncStatus.loading;
    if (s == SyncStatus.cached) result = SyncStatus.cached;
  }
  return result;
}

/// A value plus the sync metadata that came with it.
class SyncSnapshot<T> {
  final T data;
  final SyncStatus status;

  /// True while a local write has not yet been acknowledged by the server.
  final bool hasPendingWrites;

  /// Last listener error, if any. Data is kept from the previous good
  /// snapshot so the UI never blanks out because of a transient failure.
  final Object? error;

  const SyncSnapshot({
    required this.data,
    required this.status,
    this.hasPendingWrites = false,
    this.error,
  });

  bool get isLoading => status.isLoading;
  bool get isLive => status.isLive;

  SyncSnapshot<T> copyWith({
    T? data,
    SyncStatus? status,
    bool? hasPendingWrites,
    Object? error,
    bool clearError = false,
  }) {
    return SyncSnapshot<T>(
      data: data ?? this.data,
      status: status ?? this.status,
      hasPendingWrites: hasPendingWrites ?? this.hasPendingWrites,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  String toString() =>
      'SyncSnapshot($status, pending: $hasPendingWrites, error: $error)';
}
