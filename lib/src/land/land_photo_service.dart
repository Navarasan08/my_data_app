import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class LandPhotoService {
  final String uid;
  final FirebaseStorage _storage;
  final ImagePicker _picker;

  LandPhotoService({
    required this.uid,
    FirebaseStorage? storage,
    ImagePicker? picker,
  })  : _storage = storage ?? FirebaseStorage.instance,
        _picker = picker ?? ImagePicker();

  /// Pick one or more images from the gallery and upload them under
  /// users/{uid}/lands/{landId}/<timestamp>_<idx>.jpg. Returns the download
  /// URLs of uploaded files.
  Future<List<String>> pickAndUpload(String landId) async {
    final List<XFile> files = await _picker.pickMultiImage(imageQuality: 75);
    if (files.isEmpty) return const [];

    final urls = <String>[];
    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      final ts = DateTime.now().millisecondsSinceEpoch;
      final ref = _storage
          .ref()
          .child('users')
          .child(uid)
          .child('lands')
          .child(landId)
          .child('${ts}_$i.jpg');

      await ref.putFile(
        File(file.path),
        SettableMetadata(contentType: 'image/jpeg'),
      );
      urls.add(await ref.getDownloadURL());
    }
    return urls;
  }

  /// Pick a single image from the camera and upload it. Returns the URL or null.
  Future<String?> pickFromCameraAndUpload(String landId) async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 75,
    );
    if (file == null) return null;
    final ts = DateTime.now().millisecondsSinceEpoch;
    final ref = _storage
        .ref()
        .child('users')
        .child(uid)
        .child('lands')
        .child(landId)
        .child('$ts.jpg');

    await ref.putFile(
      File(file.path),
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return ref.getDownloadURL();
  }

  /// Delete a photo by its download URL.
  Future<void> deleteByUrl(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (_) {
      // ignore errors — the URL may be invalid or already deleted
    }
  }
}
