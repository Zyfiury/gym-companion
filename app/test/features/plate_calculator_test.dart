import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_companion/features/workout/plate_calculator_sheet.dart';
import 'package:gym_companion/models/user_data.dart';
import 'package:gym_companion/providers/app_state.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('plate calculator sheet opens', (tester) async {
    final state = AppState();
    state.user = UserData.defaults();

    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: state,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => showPlateCalculatorSheet(context, initialWeightKg: 100),
                child: const Text('Plates'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Plates'));
    await tester.pumpAndSettle();

    expect(find.text('Plate calculator'), findsOneWidget);
    expect(find.text('Total: 100.0 kg'), findsOneWidget);
  });
}
