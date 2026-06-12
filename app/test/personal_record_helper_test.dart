import 'package:flutter_test/flutter_test.dart';
import 'package:gym_companion/models/user_data.dart';
import 'package:gym_companion/utils/personal_record_helper.dart';

void main() {
  test('normalize maps legacy lift fields', () {
    final record = PersonalRecordHelper.normalize({
      'lift': 'Deadlift',
      'value': '140kg × 5',
      'date': '2026-06-07',
    });
    expect(record['exercise'], 'Deadlift');
    expect(record['value'], 140.0);
  });

  test('merge sorts newest first', () {
    final merged = PersonalRecordHelper.merge([
      {'exercise': 'Squat', 'value': 100, 'unit': 'kg', 'date': '2026-06-01'},
      {'exercise': 'Bench Press', 'value': 80, 'unit': 'kg', 'date': '2026-06-07'},
    ]);
    expect(merged.first['exercise'], 'Bench Press');
  });

  test('exerciseSuggestions includes weekly plan lifts', () {
    final user = UserData.defaults();
    final suggestions = PersonalRecordHelper.exerciseSuggestions(user);
    expect(suggestions, contains('Bench Press'));
    expect(suggestions, contains('Squat'));
  });

  test('formatValue adds unit spacing', () {
    expect(PersonalRecordHelper.formatValue(100, 'kg'), '100 kg');
  });

  test('isNewBest detects kg PR', () {
    final records = [
      {'exercise': 'Bench Press', 'value': 80, 'unit': 'kg'},
    ];
    expect(PersonalRecordHelper.isNewBest(records, exercise: 'Bench Press', value: 85, unit: 'kg'), isTrue);
    expect(PersonalRecordHelper.isNewBest(records, exercise: 'Bench Press', value: 80, unit: 'kg'), isFalse);
  });

  test('previousBest returns highest kg for exercise', () {
    final records = [
      {'exercise': 'Squat', 'value': 100, 'unit': 'kg'},
      {'exercise': 'Squat', 'value': 120, 'unit': 'kg'},
    ];
    expect(PersonalRecordHelper.previousBest(records, exercise: 'Squat', unit: 'kg'), 120);
  });
}
