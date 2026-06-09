import '../services/allergy_guard.dart';

/// Published UK fast-food / takeaway nutrition (per item, typical menu).
/// Sources: chain allergen/nutrition PDFs and official calculators (rounded).
class ChainMenuItem {
  final String name;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final String priceGbp;
  final bool highProtein;

  const ChainMenuItem({
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.priceGbp,
    this.highProtein = false,
  });
}

class UkChainProfile {
  final List<String> namePatterns;
  final List<ChainMenuItem> items;

  const UkChainProfile({required this.namePatterns, required this.items});
}

class UkChainMenu {
  static const profiles = <UkChainProfile>[
    UkChainProfile(
      namePatterns: ['mcdonald', 'mcdonalds', "mcdonald's"],
      items: [
        ChainMenuItem(name: 'Grilled Chicken Salad', calories: 133, protein: 20, carbs: 6, fat: 4, priceGbp: '£3.99', highProtein: true),
        ChainMenuItem(name: 'Chicken McNuggets (6pc)', calories: 259, protein: 16, carbs: 16, fat: 15, priceGbp: '£4.79'),
        ChainMenuItem(name: 'McChicken Sandwich', calories: 388, protein: 17, carbs: 40, fat: 18, priceGbp: '£4.49'),
        ChainMenuItem(name: 'Egg McMuffin', calories: 297, protein: 17, carbs: 28, fat: 13, priceGbp: '£2.99'),
        ChainMenuItem(name: 'Spicy Veggie Wrap', calories: 364, protein: 13, carbs: 47, fat: 13, priceGbp: '£3.99'),
      ],
    ),
    UkChainProfile(
      namePatterns: ['kfc', 'kentucky fried'],
      items: [
        ChainMenuItem(name: 'Original Recipe Chicken Fillet Burger', calories: 450, protein: 24, carbs: 41, fat: 20, priceGbp: '£5.99'),
        ChainMenuItem(name: 'Grilled BBQ Chicken Wrap', calories: 310, protein: 22, carbs: 32, fat: 10, priceGbp: '£4.99', highProtein: true),
        ChainMenuItem(name: 'Popcorn Chicken (Regular)', calories: 285, protein: 17, carbs: 19, fat: 15, priceGbp: '£3.49'),
        ChainMenuItem(name: 'Original Recipe Chicken Piece', calories: 248, protein: 21, carbs: 8, fat: 15, priceGbp: '£2.49', highProtein: true),
      ],
    ),
    UkChainProfile(
      namePatterns: ['subway'],
      items: [
        ChainMenuItem(name: 'Rotisserie Chicken Sub (6")', calories: 310, protein: 26, carbs: 40, fat: 5, priceGbp: '£4.79', highProtein: true),
        ChainMenuItem(name: 'Turkey Breast Sub (6")', calories: 264, protein: 18, carbs: 40, fat: 3, priceGbp: '£4.29', highProtein: true),
        ChainMenuItem(name: 'Veggie Delite Sub (6")', calories: 200, protein: 8, carbs: 38, fat: 2, priceGbp: '£3.99'),
      ],
    ),
    UkChainProfile(
      namePatterns: ['greggs'],
      items: [
        ChainMenuItem(name: 'Chicken Bake', calories: 453, protein: 22, carbs: 41, fat: 21, priceGbp: '£2.15'),
        ChainMenuItem(name: 'Sausage Roll', calories: 328, protein: 9, carbs: 25, fat: 22, priceGbp: '£1.25'),
        ChainMenuItem(name: 'Balanced Choice Chicken Salad', calories: 195, protein: 20, carbs: 12, fat: 7, priceGbp: '£3.50', highProtein: true),
      ],
    ),
    UkChainProfile(
      namePatterns: ['nando'],
      items: [
        ChainMenuItem(name: 'Grilled Chicken Butterfly Burger', calories: 435, protein: 42, carbs: 35, fat: 12, priceGbp: '£9.25', highProtein: true),
        ChainMenuItem(name: '1/4 Chicken (Plain)', calories: 298, protein: 45, carbs: 0, fat: 12, priceGbp: '£7.25', highProtein: true),
        ChainMenuItem(name: 'Grains Bowl with Chicken', calories: 520, protein: 38, carbs: 52, fat: 14, priceGbp: '£10.95', highProtein: true),
      ],
    ),
    UkChainProfile(
      namePatterns: ['burger king', 'burgerking'],
      items: [
        ChainMenuItem(name: 'Chicken Royale', calories: 480, protein: 22, carbs: 45, fat: 23, priceGbp: '£5.99'),
        ChainMenuItem(name: 'Grilled Chicken Salad', calories: 180, protein: 24, carbs: 8, fat: 6, priceGbp: '£4.99', highProtein: true),
        ChainMenuItem(name: 'Whopper Jr', calories: 310, protein: 14, carbs: 28, fat: 16, priceGbp: '£4.49'),
      ],
    ),
    UkChainProfile(
      namePatterns: ['domino', 'dominos', "domino's"],
      items: [
        ChainMenuItem(name: 'Chicken Feast (2 slices med)', calories: 380, protein: 18, carbs: 42, fat: 16, priceGbp: '£4.50'),
        ChainMenuItem(name: 'Vegi Supreme (2 slices med)', calories: 320, protein: 12, carbs: 44, fat: 10, priceGbp: '£4.00'),
      ],
    ),
    UkChainProfile(
      namePatterns: ['pret', 'pret a manger'],
      items: [
        ChainMenuItem(name: 'Chef\'s Italian Chicken Salad', calories: 295, protein: 28, carbs: 12, fat: 14, priceGbp: '£5.99', highProtein: true),
        ChainMenuItem(name: 'Tuna Mayo & Cucumber Baguette', calories: 420, protein: 22, carbs: 48, fat: 16, priceGbp: '£4.75'),
        ChainMenuItem(name: 'Egg & Spinach Protein Pot', calories: 204, protein: 17, carbs: 3, fat: 14, priceGbp: '£2.99', highProtein: true),
      ],
    ),
    UkChainProfile(
      namePatterns: ['costa'],
      items: [
        ChainMenuItem(name: 'Ham & Cheese Toastie', calories: 380, protein: 20, carbs: 32, fat: 18, priceGbp: '£4.25'),
        ChainMenuItem(name: 'Chicken & Bacon Panini', calories: 450, protein: 26, carbs: 38, fat: 20, priceGbp: '£4.95', highProtein: true),
      ],
    ),
    UkChainProfile(
      namePatterns: ['five guys', 'fiveguys'],
      items: [
        ChainMenuItem(name: 'Little Hamburger', calories: 480, protein: 23, carbs: 39, fat: 26, priceGbp: '£8.50'),
        ChainMenuItem(name: 'Grilled Cheese Sandwich', calories: 440, protein: 18, carbs: 42, fat: 22, priceGbp: '£5.50'),
      ],
    ),
    UkChainProfile(
      namePatterns: ['chipotle'],
      items: [
        ChainMenuItem(name: 'Chicken Burrito Bowl', calories: 630, protein: 42, carbs: 55, fat: 22, priceGbp: '£9.95', highProtein: true),
        ChainMenuItem(name: 'Chicken Salad Bowl', calories: 420, protein: 38, carbs: 18, fat: 18, priceGbp: '£9.25', highProtein: true),
      ],
    ),
    UkChainProfile(
      namePatterns: ['leon'],
      items: [
        ChainMenuItem(name: 'LOVE Burger', calories: 420, protein: 22, carbs: 38, fat: 18, priceGbp: '£6.95'),
        ChainMenuItem(name: 'Chicken Box', calories: 480, protein: 35, carbs: 42, fat: 14, priceGbp: '£7.50', highProtein: true),
      ],
    ),
    UkChainProfile(
      namePatterns: ['wagamama'],
      items: [
        ChainMenuItem(name: 'Chicken Ramen', calories: 520, protein: 38, carbs: 58, fat: 12, priceGbp: '£12.50', highProtein: true),
        ChainMenuItem(name: 'Firecracker Prawn', calories: 480, protein: 28, carbs: 62, fat: 10, priceGbp: '£11.95'),
      ],
    ),
    UkChainProfile(
      namePatterns: ['pizza hut', 'pizzahut'],
      items: [
        ChainMenuItem(name: 'Chicken & Sweetcorn (2 slices med)', calories: 360, protein: 16, carbs: 44, fat: 14, priceGbp: '£4.20'),
        ChainMenuItem(name: 'Margherita (2 slices med)', calories: 320, protein: 14, carbs: 46, fat: 10, priceGbp: '£3.80'),
      ],
    ),
  ];

  static UkChainProfile? matchRestaurant(String restaurantName) {
    final lower = restaurantName.toLowerCase();
    for (final p in profiles) {
      for (final pattern in p.namePatterns) {
        if (lower.contains(pattern)) return p;
      }
    }
    return null;
  }

  static ChainMenuItem? pickBestItem(String restaurantName, {String goal = 'maintain', bool preferHighProtein = true}) {
    final profile = matchRestaurant(restaurantName);
    if (profile == null || profile.items.isEmpty) return null;
    return _pickFromItems(profile.items, goal: goal, preferHighProtein: preferHighProtein);
  }

  /// Prefer high-protein chain items that pass allergy/diet checks on the dish name.
  static ChainMenuItem? pickBestSafeItem(
    String restaurantName, {
    String goal = 'maintain',
    required UserAllergies prefs,
    bool preferHighProtein = true,
  }) {
    final profile = matchRestaurant(restaurantName);
    if (profile == null || profile.items.isEmpty) return null;
    final safe = profile.items.where((item) => AllergyGuard.checkText(item.name, prefs).isSafe).toList();
    if (safe.isEmpty) return null;
    return _pickFromItems(safe, goal: goal, preferHighProtein: preferHighProtein);
  }

  static ChainMenuItem _pickFromItems(List<ChainMenuItem> items, {required String goal, required bool preferHighProtein}) {
    final sorted = List<ChainMenuItem>.from(items);
    if (preferHighProtein || goal == 'cut' || goal == 'bulk') {
      sorted.sort((a, b) {
        if (a.highProtein != b.highProtein) return a.highProtein ? -1 : 1;
        return b.protein.compareTo(a.protein);
      });
    }
    return sorted.first;
  }
}
