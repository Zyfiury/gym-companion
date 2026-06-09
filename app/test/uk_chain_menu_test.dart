import 'package:flutter_test/flutter_test.dart';
import 'package:gym_companion/data/uk_chain_menu.dart';
import 'package:gym_companion/services/allergy_guard.dart';
import 'package:gym_companion/services/nutrition_lookup_service.dart';

void main() {
  test('matches McDonalds and returns published item', () {
    final item = UkChainMenu.pickBestItem("McDonald's Oxford Street", goal: 'cut');
    expect(item, isNotNull);
    expect(item!.calories, greaterThan(0));
    expect(item.highProtein || item.protein >= 15, isTrue);
  });

  test('chain lookup marks verified nutrition', () {
    final match = NutritionLookupService.fromChain('Greggs City Centre', goal: 'bulk');
    expect(match, isNotNull);
    expect(match!.isVerified, isTrue);
    expect(match.source, NutritionSource.chainMenu);
  });

  test('unknown restaurant returns null from chain', () {
    expect(UkChainMenu.matchRestaurant('Random Local Cafe'), isNull);
  });

  test('pickBestSafeItem skips dairy dishes for dairy allergy', () {
    const prefs = UserAllergies(allergies: ['dairy']);
    final item = UkChainMenu.pickBestSafeItem("Pret a Manger", goal: 'cut', prefs: prefs);
    expect(item, isNotNull);
    expect(item!.name.toLowerCase(), isNot(contains('egg')));
    expect(AllergyGuard.checkText(item.name, prefs).isSafe, isTrue);
  });
}
