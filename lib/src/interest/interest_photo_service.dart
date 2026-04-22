import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

/// Photo upload helper for interest records and their payment proofs.
///
/// Files are stored under
///   `users/{uid}/interest/{recordId}/[payments/{paymentId}/]<ts>_<i>.jpg`
class InterestPhotoService {
  final String uid;
  final FirebaseStorage _storage;
  final ImagePicker _picker;

  InterestPhotoService({
    required this.uid,
    FirebaseStorage? storage,
    ImagePicker? picker,
  })  : _storage = storage ?? FirebaseStorage.instance,
        _picker = picker ?? ImagePicker();

  Reference _baseRef(String recordId, {String? paymentId}) {
    var ref = _storage
        .ref()
        .child('users')
        .child(uid)
        .child('interest')
        .child(recordId);
    if (paymentId != null) ref = ref.child('payments').child(paymentId);
    return ref;
  }

  Future<List<String>> pickAndUploadGallery(
    String recordId, {
    String? paymentId,
  }) async {
    final files = await _picker.pickMultiImage(imageQuality: 75);
    if (files.isEmpty) return const [];
    final urls = <String>[];
    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      final ts = DateTime.now().millisecondsSinceEpoch;
      final ref = _baseRef(recordId, paymentId: paymentId).child('${ts}_$i.jpg');
      await ref.putFile(
        File(file.path),
        SettableMetadata(contentType: 'image/jpeg'),
      );
      urls.add(await ref.getDownloadURL());
    }
    return urls;
  }

  Future<String?> pickFromCameraAndUpload(
    String recordId, {
    String? paymentId,
  }) async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 75,
    );
    if (file == null) return null;
    final ts = DateTime.now().millisecondsSinceEpoch;
    final ref = _baseRef(recordId, paymentId: paymentId).child('$ts.jpg');
    await ref.putFile(
      File(file.path),
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return ref.getDownloadURL();
  }

  Future<void> deleteByUrl(String url) async {
    try {
      await _storage.refFromURL(url).delete();
    } catch (_) {}
  }
}
