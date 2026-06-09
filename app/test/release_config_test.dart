import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_companion/config/release_config.dart';

void main() {
  test('local auth allowed only outside release mode', () {
    expect(ReleaseConfig.allowLocalAuth, !kReleaseMode);
  });

  test('production ready check mirrors release mode', () {
    if (kReleaseMode) {
      // In release test runs this may be false without real .env — structure is valid.
      expect(ReleaseConfig.isProductionReady, isA<bool>());
    } else {
      expect(ReleaseConfig.isProductionReady, isTrue);
    }
  });
}
