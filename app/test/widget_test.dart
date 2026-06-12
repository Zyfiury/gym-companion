import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_companion/main.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await dotenv.load(fileName: '.env');
  });

  testWidgets('App loads', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: GymCompanionApp(),
      ),
    );

    // Avoid pumpAndSettle — splash/login may have endlessly animating widgets.
    for (var i = 0; i < 80; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    final hasBrand = find.text('Gym Companion').evaluate().isNotEmpty;
    final hasLogin = find.text('Log in').evaluate().isNotEmpty;
    final hasHome = find.text('Home').evaluate().isNotEmpty;
    expect(hasBrand || hasLogin || hasHome, isTrue);
  });
}
