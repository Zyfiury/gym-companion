import 'package:flutter_test/flutter_test.dart';
import 'package:gym_companion/services/plate_calculator_service.dart';

void main() {
  test('calculates exact 100kg with 20kg bar', () {
    final r = PlateCalculatorService.calculate(targetKg: 100, barWeightKg: 20);
    expect(r.totalWeight, 100);
    expect(r.platesPerSide, isNotEmpty);
  });

  test('finds closest for odd weight', () {
    final r = PlateCalculatorService.calculate(targetKg: 83, barWeightKg: 20);
    expect(r.isClosestMatch, isTrue);
    expect((r.totalWeight - 83).abs(), lessThanOrEqualTo(2.5));
  });
}
