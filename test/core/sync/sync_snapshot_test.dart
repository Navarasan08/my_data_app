import 'package:flutter_test/flutter_test.dart';
import 'package:my_data_app/src/core/sync/sync_snapshot.dart';

void main() {
  group('combineSyncStatus', () {
    test('empty input is live', () {
      expect(combineSyncStatus(const []), SyncStatus.live);
    });

    test('all live is live', () {
      expect(
        combineSyncStatus(const [SyncStatus.live, SyncStatus.live]),
        SyncStatus.live,
      );
    });

    test('any cached downgrades to cached', () {
      expect(
        combineSyncStatus(const [SyncStatus.live, SyncStatus.cached]),
        SyncStatus.cached,
      );
    });

    test('any loading wins over everything', () {
      expect(
        combineSyncStatus(const [
          SyncStatus.live,
          SyncStatus.cached,
          SyncStatus.loading,
        ]),
        SyncStatus.loading,
      );
    });
  });

  group('SyncSnapshot', () {
    test('copyWith keeps unspecified fields and can clear error', () {
      const base = SyncSnapshot<int>(
        data: 1,
        status: SyncStatus.cached,
        hasPendingWrites: true,
        error: 'boom',
      );
      final next = base.copyWith(status: SyncStatus.live);
      expect(next.data, 1);
      expect(next.status, SyncStatus.live);
      expect(next.hasPendingWrites, isTrue);
      expect(next.error, 'boom');

      final cleared = base.copyWith(clearError: true);
      expect(cleared.error, isNull);
    });

    test('isLoading / isLive reflect status', () {
      const loading = SyncSnapshot<int>(data: 0, status: SyncStatus.loading);
      const live = SyncSnapshot<int>(data: 0, status: SyncStatus.live);
      expect(loading.isLoading, isTrue);
      expect(loading.isLive, isFalse);
      expect(live.isLive, isTrue);
    });
  });
}
