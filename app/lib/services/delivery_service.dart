import '../models/user_data.dart';
import 'allergy_guard.dart';
import 'backend_config.dart';
import 'location_service.dart';
import 'nutrition_lookup_service.dart';
import 'places_service.dart';

class DeliveryOption {
  final String restaurant;
  final String address;
  final double rating;
  final double? distanceKm;
  final String dish;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final String price;
  final int score;
  final String uberEatsUrl;
  final String deliverooUrl;
  final String justEatUrl;
  final bool macrosEstimated;
  final String? nutritionSource;

  const DeliveryOption({
    required this.restaurant,
    required this.address,
    required this.rating,
    required this.dish,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.price,
    required this.score,
    required this.uberEatsUrl,
    required this.deliverooUrl,
    required this.justEatUrl,
    this.distanceKm,
    this.macrosEstimated = true,
    this.nutritionSource,
  });

  Map<String, dynamic> toJson() => {
        'restaurant': restaurant,
        'address': address,
        'rating': rating,
        'distanceKm': distanceKm,
        'dish': dish,
        'macros': '$calories kcal, ${protein}g P, ${carbs}g C, ${fat}g F',
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'price': price,
        'score': score,
        'uberEatsUrl': uberEatsUrl,
        'deliverooUrl': deliverooUrl,
        'justEatUrl': justEatUrl,
        'macrosEstimated': macrosEstimated,
        'nutritionSource': nutritionSource,
      };
}

class DeliveryResult {
  final String reply;
  final List<DeliveryOption> options;
  final String? areaLabel;

  const DeliveryResult({
    required this.reply,
    required this.options,
    this.areaLabel,
  });
}

class DeliveryService {
  static final _deliveryRe = RegExp(
    r'\b(?:uber\s*eats?|deliveroo|just\s*eat|takeaway|take\s*away|delivery|deliver|order\s*food|order\s*in|restaurant|restaurants|fast\s*food|near\s*me|around\s*my\s*area|my\s*area|nearby)\b',
    caseSensitive: false,
  );

  static bool isDeliveryQuery(String text) => _deliveryRe.hasMatch(text);

  static Future<DeliveryResult> suggestForMode(UserData user, {required bool dineIn}) =>
      suggestNearby(dineIn ? 'restaurants near me dine in' : 'takeaway delivery near me', user, dineIn: dineIn);

  static Future<DeliveryResult> suggestNearby(String query, UserData user, {bool dineIn = false}) async {
    if (!BackendConfig.hasGooglePlaces) {
      return DeliveryResult(
        reply: '⚠️ Add GOOGLE_PLACES_API_KEY to your .env to find real restaurants near you.\n'
            'Enable Places API in Google Cloud Console (same project as your YouTube key).',
        options: const [],
      );
    }

    final locationResult = await LocationService.resolveLocation();
    final location = locationResult.location;

    if (location == null) {
      return DeliveryResult(
        reply: '📍 ${locationResult.message}',
        options: const [],
      );
    }

    final areaLabel = await PlacesService.reverseGeocodeLabel(location);
    final restaurants = dineIn
        ? await PlacesService.findDineInRestaurants(location)
        : await PlacesService.findFastFoodAndTakeaway(location);

    if (restaurants.isEmpty) {
      return DeliveryResult(
        reply: '😕 No ${dineIn ? 'restaurants' : 'takeaway or fast food places'} found within 3.5 km of ${areaLabel ?? "your location"}.',
        options: const [],
        areaLabel: areaLabel,
      );
    }

    final calTarget = user.weeklyPlan.macros['calories'] ?? user.tdee;
    final calRemaining = (calTarget - user.dailyMacrosLogged.calories).clamp(200, 2000);
    final proteinTarget = user.weeklyPlan.macros['protein'] ?? (user.weight * 2).round();

    final prefs = UserAllergies.fromUser(user);
    final options = <DeliveryOption>[];
    for (final r in restaurants.take(10)) {
      final nutrition = await NutritionLookupService.forRestaurant(
        restaurantName: r.name,
        placeTypes: r.types,
        goal: user.goal,
        prefs: prefs,
      );

      final guard = AllergyGuard.checkText(nutrition.name, prefs);
      if (!guard.isSafe) continue;

      final score = _scoreDish(
        calories: nutrition.calories,
        protein: nutrition.protein,
        calRemaining: calRemaining,
        proteinTarget: proteinTarget,
        goal: user.goal,
        rating: r.rating,
        distanceKm: r.distanceKm,
        verified: nutrition.isVerified,
      );

      final sourceLabel = switch (nutrition.source) {
        NutritionSource.chainMenu => 'published menu',
        NutritionSource.openFoodFacts => 'Open Food Facts',
        NutritionSource.estimated => 'estimate',
      };

      options.add(DeliveryOption(
        restaurant: r.name,
        address: r.address,
        rating: r.rating,
        distanceKm: r.distanceKm,
        dish: nutrition.name,
        calories: nutrition.calories,
        protein: nutrition.protein,
        carbs: nutrition.carbs,
        fat: nutrition.fat,
        price: nutrition.priceGbp ?? 'See menu',
        score: score,
        uberEatsUrl: _uberEatsUrl(r.name, areaLabel),
        deliverooUrl: _deliverooUrl(r.name),
        justEatUrl: _justEatUrl(r.name, areaLabel),
        macrosEstimated: !nutrition.isVerified,
        nutritionSource: sourceLabel,
      ));
    }

    options.sort((a, b) => b.score.compareTo(a.score));
    final top = options.take(5).toList();

    if (top.isEmpty) {
      final allergyLabel = prefs.allergies.isEmpty
          ? 'your diet preferences'
          : prefs.allergies.map((a) => a.replaceAll('_', ' ')).join(', ');
      return DeliveryResult(
        reply: '⚠️ Found places nearby but nothing looked safe for $allergyLabel.\n'
            'Update allergies in Profile → Nutrition, or try Eat out / cook at home.',
        options: const [],
        areaLabel: areaLabel,
      );
    }

    final area = areaLabel ?? 'your area';
    final calLeft = calTarget - user.dailyMacrosLogged.calories;
    final header = dineIn ? '🍽 Restaurants near $area' : '🍽 Fast food & takeaway near $area';
    final buffer = StringBuffer()
      ..writeln('$header (${calLeft > 0 ? '$calLeft kcal left today' : 'macros logged'}):')
      ..writeln('Real places from Google Maps — dishes matched to published chain menus or Open Food Facts.')
      ..writeln();

    for (var i = 0; i < top.length; i++) {
      final o = top[i];
      final dist = o.distanceKm != null ? ' · ${o.distanceKm!.toStringAsFixed(1)} km' : '';
      final stars = o.rating > 0 ? ' ⭐${o.rating.toStringAsFixed(1)}' : '';
      final src = o.nutritionSource != null ? ' (${o.nutritionSource})' : '';
      buffer.writeln('${i + 1}. **${o.restaurant}**$stars$dist');
      buffer.writeln('   ${o.dish} — ${o.calories} kcal, ${o.protein}g protein · ${o.price}$src');
      buffer.writeln('   ${o.address}');
      if (i < top.length - 1) buffer.writeln();
    }

    buffer.writeln();
    buffer.writeln('Tap a platform below to order 👇');

    return DeliveryResult(reply: buffer.toString(), options: top, areaLabel: areaLabel);
  }

  static int _scoreDish({
    required int calories,
    required int protein,
    required int calRemaining,
    required int proteinTarget,
    required String goal,
    required double rating,
    required double? distanceKm,
    required bool verified,
  }) {
    var score = 50;
    if (verified) score += 15;
    final calDiff = (calories - calRemaining).abs();
    if (calDiff < 150) {
      score += 25;
    } else if (calDiff < 300) {
      score += 12;
    }

    if (goal == 'cut' || goal == 'bulk') {
      if (protein >= 35) score += 15;
      if (protein >= 40) score += 5;
    }

    score += (rating * 4).round();
    if (distanceKm != null) {
      if (distanceKm < 1) {
        score += 10;
      } else if (distanceKm < 2) {
        score += 5;
      }
    }
    return score.clamp(0, 100);
  }

  static String _uberEatsUrl(String restaurant, String? area) {
    final q = Uri.encodeComponent(area != null ? '$restaurant $area' : restaurant);
    return 'https://www.ubereats.com/gb/search?q=$q';
  }

  static String _deliverooUrl(String restaurant) {
    return 'https://deliveroo.co.uk/search?query=${Uri.encodeComponent(restaurant)}';
  }

  static String _justEatUrl(String restaurant, String? area) {
    final q = Uri.encodeComponent(area != null ? '$restaurant $area' : restaurant);
    return 'https://www.just-eat.co.uk/search?q=$q';
  }
}
