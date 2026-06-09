import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_companion/services/backend_config.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await dotenv.load(fileName: '.env');
  });

  test('detects configured backends from .env', () {
    expect(BackendConfig.hasGroq, isTrue);
    expect(BackendConfig.hasSupabase, isTrue);
    expect(BackendConfig.hasFirebase, isTrue);
    expect(BackendConfig.groqApiKey, isNotEmpty);
    expect(BackendConfig.hasYouTube, isTrue);
    expect(BackendConfig.hasGooglePlaces, isTrue);
    expect(BackendConfig.hasGoogleVision, isTrue);
  });

  test('openclaw HTTP base derived from gateway URL', () {
    if (BackendConfig.hasOpenClaw) {
      expect(BackendConfig.openclawHttpBase, startsWith('http'));
    } else {
      expect(BackendConfig.openclawHttpBase, isNull);
    }
  });
}
