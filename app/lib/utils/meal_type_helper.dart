/// Meal slot helpers - defaults from time of day (MFP-style).
class MealTypeHelper {
  static const slots = ['Breakfast', 'Lunch', 'Dinner', 'Snacks'];

  static String infer([DateTime? when]) {
    final h = (when ?? DateTime.now()).hour;
    if (h < 11) return 'Breakfast';
    if (h < 15) return 'Lunch';
    if (h < 18) return 'Dinner';
    return 'Snacks';
  }
}
