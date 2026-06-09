import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Firebase config from `.env` — populated after `flutterfire configure` or manually.
class DefaultFirebaseOptions {
  static FirebaseOptions? get currentPlatform {
    final apiKey = (dotenv.env['FIREBASE_API_KEY'] ?? '').trim();
    final senderId = (dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '').trim();
    final projectId = (dotenv.env['FIREBASE_PROJECT_ID'] ?? '').trim();

    if (apiKey.isEmpty || projectId.isEmpty || projectId.contains('your-project')) {
      return null;
    }

    if (kIsWeb) return null;

    if (defaultTargetPlatform == TargetPlatform.android) {
      final appId = (dotenv.env['FIREBASE_ANDROID_APP_ID'] ?? dotenv.env['FIREBASE_APP_ID'] ?? '').trim();
      if (appId.isEmpty) return null;
      return FirebaseOptions(
        apiKey: apiKey,
        appId: appId,
        messagingSenderId: senderId,
        projectId: projectId,
      );
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final appId = (dotenv.env['FIREBASE_IOS_APP_ID'] ?? dotenv.env['FIREBASE_APP_ID'] ?? '').trim();
      if (appId.isEmpty) return null;
      final iosBundleId = (dotenv.env['FIREBASE_IOS_BUNDLE_ID'] ?? 'com.gymcompanion.gym_companion').trim();
      return FirebaseOptions(
        apiKey: apiKey,
        appId: appId,
        messagingSenderId: senderId,
        projectId: projectId,
        iosBundleId: iosBundleId,
      );
    }

    return null;
  }
}
