import 'package:flutter/foundation.dart';
import '../firebase_options.dart';
import '../services/backend_config.dart';

/// Production release requirements.
class ReleaseConfig {
  static bool get isProductionReady {
    if (!kReleaseMode) return true;
    if (BackendConfig.allowSideloadTester) return true;
    return BackendConfig.hasFirebase && DefaultFirebaseOptions.currentPlatform != null;
  }

  static bool get allowLocalAuth => !kReleaseMode || BackendConfig.allowSideloadTester;
}
