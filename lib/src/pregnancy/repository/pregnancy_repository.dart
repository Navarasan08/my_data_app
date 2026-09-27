import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_data_app/src/core/sync/firestore_document_source.dart';
import 'package:my_data_app/src/core/sync/firestore_list_store.dart';
import 'package:my_data_app/src/core/sync/sync_node.dart';
import 'package:my_data_app/src/pregnancy/model/pregnancy_model.dart';

abstract class PregnancyRepository implements SyncNode {
  PregnancyProfile getProfile();
  void saveProfile(PregnancyProfile profile);

  List<PregnancyCheckItem> getChecks();
  void addCheck(PregnancyCheckItem item);
  void updateCheck(PregnancyCheckItem item);
  void deleteCheck(String id);

  /// Writes the standard schedule. Items already present (same id) are
  /// left untouched, so this is safe to call more than once.
  void seedDefaultChecks();

  List<PregnancyLog> getLogs();
  void addLog(PregnancyLog log);
  void updateLog(PregnancyLog log);
  void deleteLog(String id);

  /// Removes every check and log. The profile is the caller's business.
  void clearAll();
}

/// Listener-based Firestore implementation: the profile document plus two
/// realtime collections, folded into one sync node.
class FirestorePregnancyRepository extends CompositeSyncNode
    implements PregnancyRepository {
  final String uid;
  final FirestoreDocumentSource<PregnancyProfile> _profile;
  final FirestoreListStore<PregnancyCheckItem> _checks;
  final FirestoreListStore<PregnancyLog> _logs;

  factory FirestorePregnancyRepository({
    required String uid,
    FirebaseFirestore? firestore,
  }) {
    final user = (firestore ?? FirebaseFirestore.instance)
        .collection('users')
        .doc(uid);
    final profile = FirestoreDocumentSource<PregnancyProfile>(
      ref: user.collection('pregnancy_settings').doc('profile'),
      fromDoc: PregnancyProfile.fromJson,
      initial: PregnancyProfile.defaults,
      debugLabel: 'pregnancy_profile',
    );
    final checks = FirestoreListStore<PregnancyCheckItem>(
      collection: user.collection('pregnancy_checks'),
      fromDoc: (json, _) => PregnancyCheckItem.fromJson(json),
      toJson: (c) => c.toJson(),
      idOf: (c) => c.id,
      debugLabel: 'pregnancy_checks',
    );
    final logs = FirestoreListStore<PregnancyLog>(
      collection: user.collection('pregnancy_logs'),
      fromDoc: (json, _) => PregnancyLog.fromJson(json),
      toJson: (l) => l.toJson(),
      idOf: (l) => l.id,
      debugLabel: 'pregnancy_logs',
    );
    return FirestorePregnancyRepository._(uid, profile, checks, logs);
  }

  FirestorePregnancyRepository._(
    this.uid,
    this._profile,
    this._checks,
    this._logs,
  ) : super([_profile, _checks, _logs]) {
    // Subscribed before the composite's own listener (which attaches in
    // start()), so the overlay is gone by the time consumers are notified
    // of the profile snapshot — and only then, never on a checks change.
    _profile.changes.listen((_) => _profileOverlay = null);
  }

  /// Local copy of the profile so a save is visible synchronously, like
  /// the list stores' optimistic writes. Dropped on the next profile
  /// snapshot, which always includes the write.
  PregnancyProfile? _profileOverlay;

  @override
  PregnancyProfile getProfile() => _profileOverlay ?? _profile.current.data;

  @override
  void saveProfile(PregnancyProfile profile) {
    _profileOverlay = profile;
    fireAndForget(
      _profile.ref.set(profile.toJson()),
      label: 'pregnancy_profile',
    );
    notifyChanged();
  }

  @override
  List<PregnancyCheckItem> getChecks() => _checks.items;

  @override
  void addCheck(PregnancyCheckItem item) => _checks.save(item);

  @override
  void updateCheck(PregnancyCheckItem item) => _checks.save(item);

  @override
  void deleteCheck(String id) => _checks.remove(id);

  @override
  void seedDefaultChecks() {
    final existing = _checks.items.map((c) => c.id).toSet();
    for (final item in PregnancyCheckItem.seedDefaults) {
      if (!existing.contains(item.id)) _checks.save(item);
    }
  }

  @override
  List<PregnancyLog> getLogs() => _logs.items;

  @override
  void addLog(PregnancyLog log) => _logs.save(log);

  @override
  void updateLog(PregnancyLog log) => _logs.save(log);

  @override
  void deleteLog(String id) => _logs.remove(id);

  @override
  void clearAll() {
    _checks.removeWhere((_) => true);
    _logs.removeWhere((_) => true);
  }
}
