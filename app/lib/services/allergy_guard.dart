/// Allergy Guard — blocks unsafe foods, meals, and video titles.
class AllergyGuard {
  static const allergenKeywords = {
    'peanuts': ['peanut', 'peanuts', 'groundnut'],
    'tree_nuts': ['almond', 'walnut', 'cashew', 'hazelnut', 'pecan', 'pistachio'],
    'dairy': ['milk', 'cheese', 'yogurt', 'yoghurt', 'whey', 'cream', 'butter', 'dairy', 'lactose'],
    'eggs': ['egg', 'eggs', 'albumin'],
    'gluten': ['wheat', 'gluten', 'barley', 'rye', 'flour', 'bread', 'pasta'],
    'soy': ['soy', 'soya', 'tofu', 'edamame'],
    'shellfish': ['shrimp', 'prawn', 'crab', 'lobster', 'shellfish'],
    'fish': ['salmon', 'tuna', 'cod', 'fish', 'anchovy'],
    'sesame': ['sesame', 'tahini'],
  };

  static const allAllergenOptions = [
    'peanuts', 'tree_nuts', 'dairy', 'eggs', 'gluten', 'soy', 'shellfish', 'fish', 'sesame',
  ];

  static GuardResult checkText(String text, UserAllergies prefs) {
    final lower = text.toLowerCase();
    final hits = <String>[];

    for (final allergy in prefs.allergies) {
      final keywords = allergenKeywords[allergy] ?? [allergy];
      for (final kw in keywords) {
        if (lower.contains(kw)) hits.add(_label(allergy));
      }
    }

    for (final ex in prefs.excludedIngredients) {
      if (ex.isNotEmpty && lower.contains(ex.toLowerCase())) hits.add(ex);
    }

    if (prefs.dietType == 'vegetarian' || prefs.dietType == 'vegan') {
      for (final meat in ['chicken', 'beef', 'pork', 'bacon', 'ham', 'turkey', 'lamb']) {
        if (lower.contains(meat)) hits.add(meat);
      }
    }
    if (prefs.dietType == 'vegan') {
      for (final v in ['egg', 'milk', 'cheese', 'honey', 'yogurt']) {
        if (lower.contains(v)) hits.add(v);
      }
    }

    if (hits.isEmpty) return GuardResult.safe();
    return GuardResult.blocked(hits.toSet().toList());
  }

  static GuardResult checkMeal({required String name, required String description, required List<String> ingredients, required UserAllergies prefs}) {
    final combined = '$name $description ${ingredients.join(' ')}';
    return checkText(combined, prefs);
  }

  static GuardResult checkProduct({required String name, List<String> allergenTags = const [], required UserAllergies prefs}) {
    final combined = '$name ${allergenTags.join(' ')}';
    return checkText(combined, prefs);
  }

  static String _label(String key) => key.replaceAll('_', ' ');
}

class UserAllergies {
  final List<String> allergies;
  final List<String> excludedIngredients;
  final String dietType;

  const UserAllergies({this.allergies = const [], this.excludedIngredients = const [], this.dietType = 'omnivore'});

  factory UserAllergies.fromUser(dynamic user) {
    return UserAllergies(
      allergies: List<String>.from(user.allergies ?? []),
      excludedIngredients: List<String>.from(user.excludedIngredients ?? []),
      dietType: user.dietType as String? ?? 'omnivore',
    );
  }
}

class GuardResult {
  final bool isSafe;
  final List<String> conflicts;

  GuardResult._(this.isSafe, this.conflicts);

  factory GuardResult.safe() => GuardResult._(true, []);
  factory GuardResult.blocked(List<String> conflicts) => GuardResult._(false, conflicts);

  String get message => isSafe
      ? 'Safe for your profile.'
      : 'Contains ${conflicts.join(', ')} — blocked due to your allergies/preferences.';
}
