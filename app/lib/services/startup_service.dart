import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import 'backend_config.dart';
import '../firebase_options.dart';
import 'firebase_service.dart';
import 'notification_service.dart';
import 'plan_agent_service.dart';
import 'subscription_service.dart';
import 'supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Heavy SDK setup — safe to run after the first frame.
class StartupService {
  static bool _deferredDone = false;

  static Future<void> initFirebase() async {
    if (!BackendConfig.hasFirebase) return;
    try {
      if (Firebase.apps.isNotEmpty) return;

      // Android: use google-services.json (avoids .env / native config mismatch crashes).
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        await Firebase.initializeApp();
      } else {
        final options = DefaultFirebaseOptions.currentPlatform;
        if (options == null) return;
        await Firebase.initializeApp(options: options);
      }

      await FirebaseService.enableOfflineSync();

      if (kReleaseMode) {
        FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
        PlatformDispatcher.instance.onError = (error, stack) {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
          return true;
        };
      }

      if (FirebaseService.currentUser != null) {
        unawaited(PlanAgentService.generateWeeklyPlanIfNeeded());
      }
    } catch (e, st) {
      debugPrint('Firebase init failed: $e\n$st');
    }
  }

  static Future<void> initSupabase() async {
    if (!BackendConfig.hasSupabase) return;
    try {
      await Supabase.initialize(
        url: BackendConfig.supabaseUrl!,
        anonKey: BackendConfig.supabaseAnonKey!,
      );
      if (!BackendConfig.hasFirebase && SupabaseService.currentUser != null) {
        unawaited(PlanAgentService.generateWeeklyPlanIfNeeded());
      }
    } catch (e, st) {
      debugPrint('Supabase init failed: $e\n$st');
    }
  }

  static Future<void> runDeferredStartup() async {
    if (_deferredDone) return;
    _deferredDone = true;
    await SubscriptionService.init();
    try {
      await NotificationService.init();
    } catch (e, st) {
      debugPrint('Notification init failed: $e\n$st');
    }
  }
}
