import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import 'backend_config.dart';

/// Uploads meal photos to Firebase Storage: users/{uid}/mealPhotos/{date}/{ts}.jpg
class MealPhotoService {
  MealPhotoService._();

  static Future<String?> upload({
    required String uid,
    required File image,
    String? date,
  }) async {
    if (!BackendConfig.hasFirebase) return null;
    try {
      final day = date ?? DateTime.now().toIso8601String().substring(0, 10);
      final ts = DateTime.now().millisecondsSinceEpoch;
      final ref = FirebaseStorage.instance.ref('users/$uid/mealPhotos/$day/$ts.jpg');
      await ref.putFile(image, SettableMetadata(contentType: 'image/jpeg'));
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('MealPhotoService.upload failed: $e');
      return null;
    }
  }
}
