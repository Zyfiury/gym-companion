import 'package:flutter_test/flutter_test.dart';
import 'package:gym_companion/services/voice_food_service.dart';

void main() {
  test('parse rejects empty speech', () async {
    final r = await VoiceFoodService.parse('');
    expect(r.error, isNotNull);
    expect(r.calories, 0);
  });

  test('toProductMap includes macro fields', () {
    const r = VoiceFoodResult(
      name: 'Chicken rice',
      calories: 500,
      protein: 40,
      carbs: 50,
      fat: 10,
    );
    final m = r.toProductMap();
    expect(m['name'], 'Chicken rice');
    expect(m['calories'], 500.0);
    expect(m['protein'], 40.0);
  });
}
