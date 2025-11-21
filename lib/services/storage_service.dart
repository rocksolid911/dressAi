import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../core/constants/app_constants.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  // Upload clothing item image
  Future<String> uploadClothingImage({
    required File imageFile,
    required String userId,
  }) async {
    try {
      final String fileName = '${_uuid.v4()}.jpg';
      final String path = '${AppConstants.clothingImagesPath}/$userId/$fileName';

      final Reference ref = _storage.ref().child(path);
      final UploadTask uploadTask = ref.putFile(imageFile);

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: ${e.toString()}');
    }
  }

  // Upload user avatar
  Future<String> uploadUserAvatar({
    required File imageFile,
    required String userId,
  }) async {
    try {
      final String fileName = 'avatar_$userId.jpg';
      final String path = '${AppConstants.userAvatarsPath}/$fileName';

      final Reference ref = _storage.ref().child(path);
      final UploadTask uploadTask = ref.putFile(imageFile);

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload avatar: ${e.toString()}');
    }
  }

  // Delete image
  Future<void> deleteImage(String imageUrl) async {
    try {
      final Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Failed to delete image: ${e.toString()}');
    }
  }

  // Get download URL from path
  Future<String> getDownloadUrl(String path) async {
    try {
      final Reference ref = _storage.ref().child(path);
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to get download URL: ${e.toString()}');
    }
  }
}
