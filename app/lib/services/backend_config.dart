import 'package:flutter_dotenv/flutter_dotenv.dart';

class BackendConfig {
  static String _cleanUrl(String raw) =>
      raw.trim().replaceAll(RegExp(r'^https:\s*'), 'https://');

  static bool get hasSupabase {
    final url = _cleanUrl(dotenv.env['SUPABASE_URL'] ?? '');
    final key = (dotenv.env['SUPABASE_ANON_KEY'] ?? '').trim();
    return url.isNotEmpty && key.isNotEmpty && !url.contains('your-project');
  }

  static bool get hasGroq {
    final key = dotenv.env['GROQ_API_KEY'] ?? '';
    return key.isNotEmpty && !key.contains('your-groq');
  }

  static bool get hasRevenueCat {
    final key = dotenv.env['REVENUECAT_KEY'] ?? '';
    return key.isNotEmpty && !key.contains('your-revenuecat');
  }

  static bool get devProOverride {
    final v = (dotenv.env['DEV_PRO_OVERRIDE'] ?? '').trim().toLowerCase();
    return v == 'true' || v == '1';
  }

  static bool get allowSideloadTester {
    final v = (dotenv.env['ALLOW_SIDELOAD_TESTER'] ?? '').trim().toLowerCase();
    return v == 'true' || v == '1';
  }

  static bool get hasFirebase {
    final projectId = (dotenv.env['FIREBASE_PROJECT_ID'] ?? '').trim();
    final apiKey = (dotenv.env['FIREBASE_API_KEY'] ?? '').trim();
    final androidAppId = (dotenv.env['FIREBASE_ANDROID_APP_ID'] ?? dotenv.env['FIREBASE_APP_ID'] ?? '').trim();
    final iosAppId = (dotenv.env['FIREBASE_IOS_APP_ID'] ?? dotenv.env['FIREBASE_APP_ID'] ?? '').trim();
    final hasRealKey = apiKey.isNotEmpty &&
        !apiKey.contains('your-firebase') &&
        !apiKey.contains('REPLACE');
    final hasRealAppId = (androidAppId.isNotEmpty && !androidAppId.contains('your-android') && !androidAppId.contains('REPLACE')) ||
        (iosAppId.isNotEmpty && !iosAppId.contains('REPLACE'));
    return projectId.isNotEmpty && hasRealKey && hasRealAppId && !projectId.contains('your-project');
  }

  static bool get hasYouTube {
    final key = dotenv.env['YOUTUBE_API_KEY'] ?? '';
    return key.isNotEmpty && !key.contains('your-youtube');
  }

  static bool get hasGooglePlaces {
    final key = googlePlacesApiKey;
    return key != null && key.isNotEmpty;
  }

  /// Places API key — dedicated key or shared Google Cloud API key.
  static String? get googlePlacesApiKey {
    final places = (dotenv.env['GOOGLE_PLACES_API_KEY'] ?? '').trim();
    if (places.isNotEmpty && !places.contains('your-')) return places;
    final youtube = (dotenv.env['YOUTUBE_API_KEY'] ?? '').trim();
    if (youtube.isNotEmpty && !youtube.contains('your-youtube')) return youtube;
    return null;
  }

  static bool get hasOpenClaw {
    final url = dotenv.env['OPENCLAW_GATEWAY_URL'] ?? '';
    return url.isNotEmpty;
  }

  static String? get supabaseUrl => _cleanUrl(dotenv.env['SUPABASE_URL'] ?? '');
  static String? get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY']?.trim();
  static String? get groqApiKey => dotenv.env['GROQ_API_KEY']?.trim();
  static String? get revenueCatKey => dotenv.env['REVENUECAT_KEY']?.trim();
  static String? get youtubeApiKey => dotenv.env['YOUTUBE_API_KEY']?.trim();

  static String? get googleVisionApiKey {
    final vision = (dotenv.env['GOOGLE_VISION_API_KEY'] ?? '').trim();
    if (vision.isNotEmpty && !vision.contains('your-')) return vision;
    return googlePlacesApiKey;
  }

  static bool get hasDedicatedGoogleVision {
    final vision = (dotenv.env['GOOGLE_VISION_API_KEY'] ?? '').trim();
    return vision.isNotEmpty && !vision.contains('your-');
  }

  static bool get hasGoogleVision => googleVisionApiKey != null;

  /// HTTP base URL derived from ws:// gateway URL.
  static String? get openclawHttpBase {
    final url = dotenv.env['OPENCLAW_GATEWAY_URL'] ?? '';
    if (url.isEmpty) return null;
    return url.replaceFirst(RegExp(r'^wss?'), 'http').replaceAll(RegExp(r'/$'), '');
  }
}
