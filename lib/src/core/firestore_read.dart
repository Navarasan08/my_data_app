import 'package:cloud_firestore/cloud_firestore.dart';

/// Cache-first Firestore reads for fast app startup.
///
/// Firestore's offline persistence keeps a full local copy of everything the
/// app has read or written. Reading from that cache is a disk read — no
/// network round-trip — so startup stays fast no matter how much data the
/// user has accumulated. Callers are expected to follow up with a server
/// read in the background (see the repos' `refresh()` methods) so data edited
/// on another device still arrives.

/// Reads [query] from the local cache, falling back to the server when the
/// cache has nothing (first launch on a device, or platforms without
/// persistence where the cache read throws).
Future<QuerySnapshot<Map<String, dynamic>>> readQueryCacheFirst(
    Query<Map<String, dynamic>> query) async {
  try {
    final cached = await query.get(const GetOptions(source: Source.cache));
    if (cached.docs.isNotEmpty) return cached;
  } catch (_) {
    // Cache unavailable — fall through to the server read.
  }
  return query.get();
}

/// Reads [doc] from the local cache, falling back to the server when the doc
/// isn't cached.
Future<DocumentSnapshot<Map<String, dynamic>>> readDocCacheFirst(
    DocumentReference<Map<String, dynamic>> doc) async {
  try {
    final cached = await doc.get(const GetOptions(source: Source.cache));
    if (cached.exists) return cached;
  } catch (_) {
    // Cache unavailable — fall through to the server read.
  }
  return doc.get();
}
