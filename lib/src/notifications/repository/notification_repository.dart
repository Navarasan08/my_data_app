import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_data_app/src/notifications/model/app_notification.dart';

abstract class NotificationRepository {
  List<AppNotification> getAll();
  void add(AppNotification n);
  void update(AppNotification n);
  void delete(String id);
  void deleteAll();
  Future<void> init();
}

class FirestoreNotificationRepository implements NotificationRepository {
  final String uid;
  final FirebaseFirestore _firestore;
  List<AppNotification> _items = [];

  FirestoreNotificationRepository({
    required this.uid,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('users').doc(uid).collection('notifications');

  @override
  Future<void> init() async {
    final snap = await _collection.get();
    _items = snap.docs.map((d) => AppNotification.fromJson(d.data())).toList();
  }

  @override
  List<AppNotification> getAll() => List.unmodifiable(_items);

  @override
  void add(AppNotification n) {
    _items.add(n);
    _collection.doc(n.id).set(n.toJson());
  }

  @override
  void update(AppNotification n) {
    final i = _items.indexWhere((x) => x.id == n.id);
    if (i != -1) {
      _items[i] = n;
      _collection.doc(n.id).set(n.toJson());
    }
  }

  @override
  void delete(String id) {
    _items.removeWhere((x) => x.id == id);
    _collection.doc(id).delete();
  }

  @override
  void deleteAll() {
    final ids = _items.map((x) => x.id).toList();
    _items.clear();
    for (final id in ids) {
      _collection.doc(id).delete();
    }
  }
}
