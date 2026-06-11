import '../services/backend_config.dart';
import 'package:flutter/foundation.dart';

/// Production vs development configuration.
class AppConfig {
  static const appName = 'Gym Companion';
  static const version = '1.0.0';

  /// Test accounts visible in debug/profile and sideload tester builds.
  static bool get showTestAccounts => !kReleaseMode || BackendConfig.allowSideloadTester;

  /// Social login requires Firebase.
  static bool get showSocialLogin => true;

  /// GitHub Pages — update owner/repo if your fork differs (see PLAY_STORE_RELEASE.md).
  static const privacyPolicyUrl = 'https://omarz.github.io/gym-companion/legal/privacy.html';
  static const termsOfServiceUrl = 'https://omarz.github.io/gym-companion/legal/terms.html';
  static const supportEmail = 'support@gymcompanion.app';

  static const proMonthlyPrice = '£7.99/month';
  static const proAnnualPrice = '£59.99/year';
}
