/// Curated per-100g nutrition for common whole foods (USDA-aligned averages).
class CommonFoodsDatabase {
  static const List<Map<String, dynamic>> items = [
    {'name': 'Chicken breast, cooked', 'calories': 165.0, 'protein': 31.0, 'carbs': 0.0, 'fat': 3.6, 'fiber': 0.0, 'sugar': 0.0, 'sodiumMg': 740.0},
    {'name': 'Salmon, cooked', 'calories': 206.0, 'protein': 22.0, 'carbs': 0.0, 'fat': 12.0, 'fiber': 0.0, 'sugar': 0.0, 'sodiumMg': 590.0},
    {'name': 'Egg, large', 'calories': 155.0, 'protein': 13.0, 'carbs': 1.1, 'fat': 11.0, 'fiber': 0.0, 'sugar': 1.1, 'sodiumMg': 124.0},
    {'name': 'Greek yogurt, plain', 'calories': 97.0, 'protein': 9.0, 'carbs': 3.6, 'fat': 5.0, 'fiber': 0.0, 'sugar': 3.2, 'sodiumMg': 460.0},
    {'name': 'Oats, dry', 'calories': 389.0, 'protein': 17.0, 'carbs': 66.0, 'fat': 7.0, 'fiber': 10.0, 'sugar': 1.0, 'sodiumMg': 2.0},
    {'name': 'White rice, cooked', 'calories': 130.0, 'protein': 2.7, 'carbs': 28.0, 'fat': 0.3, 'fiber': 0.4, 'sugar': 0.1, 'sodiumMg': 1.0},
    {'name': 'Brown rice, cooked', 'calories': 123.0, 'protein': 2.7, 'carbs': 26.0, 'fat': 1.0, 'fiber': 1.8, 'sugar': 0.4, 'sodiumMg': 4.0},
    {'name': 'Sweet potato, baked', 'calories': 90.0, 'protein': 2.0, 'carbs': 21.0, 'fat': 0.2, 'fiber': 3.3, 'sugar': 6.5, 'sodiumMg': 36.0},
    {'name': 'Broccoli, cooked', 'calories': 35.0, 'protein': 2.4, 'carbs': 7.0, 'fat': 0.4, 'fiber': 3.3, 'sugar': 1.4, 'sodiumMg': 41.0},
    {'name': 'Banana', 'calories': 89.0, 'protein': 1.1, 'carbs': 23.0, 'fat': 0.3, 'fiber': 2.6, 'sugar': 12.0, 'sodiumMg': 1.0},
    {'name': 'Apple', 'calories': 52.0, 'protein': 0.3, 'carbs': 14.0, 'fat': 0.2, 'fiber': 2.4, 'sugar': 10.0, 'sodiumMg': 1.0},
    {'name': 'Avocado', 'calories': 160.0, 'protein': 2.0, 'carbs': 9.0, 'fat': 15.0, 'fiber': 7.0, 'sugar': 0.7, 'sodiumMg': 7.0},
    {'name': 'Almonds', 'calories': 579.0, 'protein': 21.0, 'carbs': 22.0, 'fat': 50.0, 'fiber': 12.0, 'sugar': 4.4, 'sodiumMg': 1.0},
    {'name': 'Peanut butter', 'calories': 588.0, 'protein': 25.0, 'carbs': 20.0, 'fat': 50.0, 'fiber': 6.0, 'sugar': 9.0, 'sodiumMg': 430.0},
    {'name': 'Whole milk', 'calories': 61.0, 'protein': 3.2, 'carbs': 4.8, 'fat': 3.3, 'fiber': 0.0, 'sugar': 5.0, 'sodiumMg': 430.0},
    {'name': 'Cheddar cheese', 'calories': 403.0, 'protein': 25.0, 'carbs': 1.3, 'fat': 33.0, 'fiber': 0.0, 'sugar': 0.5, 'sodiumMg': 620.0},
    {'name': 'Ground beef, lean', 'calories': 250.0, 'protein': 26.0, 'carbs': 0.0, 'fat': 15.0, 'fiber': 0.0, 'sugar': 0.0, 'sodiumMg': 720.0},
    {'name': 'Tuna, canned in water', 'calories': 116.0, 'protein': 26.0, 'carbs': 0.0, 'fat': 0.8, 'fiber': 0.0, 'sugar': 0.0, 'sodiumMg': 320.0},
    {'name': 'Whole wheat bread', 'calories': 247.0, 'protein': 13.0, 'carbs': 41.0, 'fat': 3.4, 'fiber': 7.0, 'sugar': 5.0, 'sodiumMg': 490.0},
    {'name': 'Pasta, cooked', 'calories': 131.0, 'protein': 5.0, 'carbs': 25.0, 'fat': 1.1, 'fiber': 1.8, 'sugar': 0.6, 'sodiumMg': 1.0},
    {'name': 'Protein powder, whey', 'calories': 400.0, 'protein': 80.0, 'carbs': 8.0, 'fat': 5.0, 'fiber': 0.0, 'sugar': 4.0, 'sodiumMg': 200.0},
    {'name': 'Protein bar', 'calories': 350.0, 'protein': 20.0, 'carbs': 35.0, 'fat': 12.0, 'fiber': 5.0, 'sugar': 15.0, 'sodiumMg': 180.0},
    {'name': 'Latte, whole milk', 'calories': 43.0, 'protein': 2.2, 'carbs': 3.4, 'fat': 2.3, 'fiber': 0.0, 'sugar': 3.4, 'sodiumMg': 300.0},
    {'name': 'Olive oil', 'calories': 884.0, 'protein': 0.0, 'carbs': 0.0, 'fat': 100.0, 'fiber': 0.0, 'sugar': 0.0, 'sodiumMg': 2.0},
  ];

  static List<Map<String, dynamic>> search(String query) {
    final q = query.toLowerCase().trim();
    if (q.length < 2) return [];
    return items
        .where((f) => (f['name'] as String).toLowerCase().contains(q))
        .map((f) => {
              ...f,
              'brand': 'Common foods',
              'source': 'verified',
              'verified': true,
              'per_100g': true,
              'imageUrl': null,
              'allergens': <String>[],
            })
        .take(8)
        .toList();
  }
}
