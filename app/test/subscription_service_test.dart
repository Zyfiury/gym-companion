import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gym_companion/services/subscription_service.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await dotenv.load(fileName: '.env');
  });

  test('isPro returns false without RevenueCat in test env', () async {
    final pro = await SubscriptionService.isPro();
    expect(pro, isFalse);
  });
}
