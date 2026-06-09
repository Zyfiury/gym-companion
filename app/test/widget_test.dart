import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_companion/main.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await dotenv.load(fileName: '.env');
  });

  testWidgets('App loads', (WidgetTester tester) async {
    await tester.pumpWidget(const GymCompanionApp());
    await tester.pump();
    expect(find.text('Gym Companion'), findsOneWidget);
  });
}
