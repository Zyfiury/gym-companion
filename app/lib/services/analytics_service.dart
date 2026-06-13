import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'backend_config.dart';

/// Firebase Analytics - no-ops when Firebase is unavailable.
class AnalyticsService {
  static FirebaseAnalytics? get _analytics {
    if (!BackendConfig.hasFirebase || Firebase.apps.isEmpty) return null;
    try {
      return FirebaseAnalytics.instance;
    } catch (_) {
      return null;
    }
  }

  static Future<void> logEvent(String name, [Map<String, Object>? params]) async {
    if (kDebugMode) return;
    try {
      await _analytics?.logEvent(name: name, parameters: params);
    } catch (_) {}
  }

  static Future<void> login(String method) => logEvent('login', {'method': method});
  static Future<void> signUp(String method) => logEvent('sign_up', {'method': method});
  static Future<void> onboardingComplete() => logEvent('onboarding_complete');
  static Future<void> paywallView(String source) => logEvent('paywall_view', {'source': source});
  static Future<void> purchaseStart(String plan) => logEvent('purchase_start', {'plan': plan});
  static Future<void> purchaseSuccess(String plan) => logEvent('purchase', {'plan': plan});
  static Future<void> chatMessage() => logEvent('chat_message');
  static Future<void> foodLogged(String source) => logEvent('food_logged', {'source': source});
}
