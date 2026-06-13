import 'package:flutter_test/flutter_test.dart';
import 'package:gym_companion/utils/macro_helpers.dart';

void main() {
  test('estimates fibre and sugar from carbs when missing', () {
    final micros = MacroHelpers.resolveMicros(carbs: 100);
    expect(micros.fiber, 12);
    expect(micros.sugar, 25);
  });

  test('sums macros and micros from food entries', () {
    final totals = MacroHelpers.sumFromEntries([
      {
        'date': '2026-06-13',
        'calories': 500,
        'protein': 40,
        'carbs': 50,
        'fat': 10,
      },
      {
        'date': '2026-06-12',
        'calories': 900,
        'protein': 80,
        'carbs': 100,
        'fat': 20,
      },
    ], onlyDate: '2026-06-13');

    expect(totals.calories, 500);
    expect(totals.protein, 40);
    expect(totals.fiber, 6);
    expect(totals.sugar, 13);
  });
}
