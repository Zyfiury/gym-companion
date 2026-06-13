import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_companion/features/logging/food_log_actions.dart';
import 'package:gym_companion/models/user_data.dart';
import 'package:gym_companion/providers/app_state.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('food log actions card shows voice pill and four log options', (tester) async {
    final state = AppState();
    state.user = UserData.defaults();
    state.loading = false;

    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: state,
        child: const MaterialApp(
          home: Scaffold(body: FoodLogActionsCard()),
        ),
      ),
    );

    expect(find.text('Log food'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Scan'), findsOneWidget);
    expect(find.text('Photo'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Tell me what you ate…'), findsOneWidget);

    // Manual barcode entry is tucked away until tapped.
    expect(find.text('Look up & Log'), findsNothing);
    await tester.tap(find.text('Enter barcode manually'));
    await tester.pumpAndSettle();
    expect(find.text('Look up & Log'), findsOneWidget);
  });
}
