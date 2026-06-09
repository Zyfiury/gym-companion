import 'package:flutter_test/flutter_test.dart';
import 'package:gym_companion/models/user_data.dart';
import 'package:gym_companion/services/allergy_guard.dart';

void main() {
  test('demo yogurt barcode conflicts with dairy allergy', () {
    final user = UserData.defaults()..allergies = ['dairy'];
    final guard = AllergyGuard.checkProduct(
      name: 'Greek Yogurt 500g',
      allergenTags: const ['milk', 'dairy', 'yogurt'],
      prefs: UserAllergies.fromUser(user),
    );
    expect(guard.isSafe, isFalse);
    expect(guard.message, contains('dairy'));
  });
}
