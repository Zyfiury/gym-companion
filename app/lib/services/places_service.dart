import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'backend_config.dart';
import 'location_service.dart';

class NearbySupermarket {
  final String name;
  final String address;
  final String placeId;
  final double? distanceKm;

  const NearbySupermarket({
    required this.name,
    required this.address,
    required this.placeId,
    this.distanceKm,
  });
}

class NearbyRestaurant {
  final String name;
  final String address;
  final double rating;
  final int userRatingsTotal;
  final double? distanceKm;
  final List<String> types;
  final String placeId;
  final bool openNow;

  const NearbyRestaurant({
    required this.name,
    required this.address,
    required this.rating,
    required this.userRatingsTotal,
    required this.types,
    required this.placeId,
    this.distanceKm,
    this.openNow = true,
  });
}

class PlacesService {
  static const _base = 'https://maps.googleapis.com/maps/api/place';

  /// Fast food, takeaway, and restaurants near the user (merged, deduped).
  static Future<List<NearbyRestaurant>> findFastFoodAndTakeaway(
    UserLocation location, {
    int radiusMeters = 3500,
    int maxResults = 15,
  }) async {
    final merged = <String, NearbyRestaurant>{};
    final searches = [
      {'type': 'meal_takeaway', 'keyword': ''},
      {'type': 'fast_food_restaurant', 'keyword': ''},
      {'type': 'restaurant', 'keyword': 'takeaway delivery'},
    ];
    for (final s in searches) {
      final batch = await _nearbyRestaurants(
        location,
        type: s['type']!,
        keyword: s['keyword']!,
        radiusMeters: radiusMeters,
        maxResults: maxResults,
      );
      for (final r in batch) {
        if (r.placeId.isNotEmpty) merged[r.placeId] = r;
      }
    }
    final list = merged.values.toList();
    list.sort((a, b) {
      final scoreA = _restaurantScore(a);
      final scoreB = _restaurantScore(b);
      return scoreB.compareTo(scoreA);
    });
    return list.take(maxResults).toList();
  }

  static Future<List<NearbyRestaurant>> findDineInRestaurants(
    UserLocation location, {
    int radiusMeters = 3500,
    int maxResults = 12,
  }) async {
    final merged = <String, NearbyRestaurant>{};
    final searches = [
      {'type': 'restaurant', 'keyword': 'dine in sit down'},
      {'type': 'restaurant', 'keyword': 'family restaurant'},
    ];
    for (final s in searches) {
      final batch = await _nearbyRestaurants(
        location,
        type: s['type']!,
        keyword: s['keyword']!,
        radiusMeters: radiusMeters,
        maxResults: maxResults,
      );
      for (final r in batch) {
        if (r.placeId.isNotEmpty) merged[r.placeId] = r;
      }
    }
    final list = merged.values.toList();
    list.sort((a, b) => _restaurantScore(b).compareTo(_restaurantScore(a)));
    return list.take(maxResults).toList();
  }

  static Future<List<NearbyRestaurant>> findDeliveryRestaurants(
    UserLocation location, {
    int radiusMeters = 3500,
    int maxResults = 12,
  }) =>
      findFastFoodAndTakeaway(location, radiusMeters: radiusMeters, maxResults: maxResults);

  static double _restaurantScore(NearbyRestaurant r) {
    var score = r.rating * 2 + (r.userRatingsTotal > 50 ? 1 : 0) - (r.distanceKm ?? 5);
    if (r.types.any((t) => t.contains('fast_food') || t.contains('meal_takeaway'))) score += 2;
    return score;
  }

  static Future<List<NearbyRestaurant>> _nearbyRestaurants(
    UserLocation location, {
    required String type,
    String keyword = '',
    int radiusMeters = 3500,
    int maxResults = 12,
  }) async {
    final key = BackendConfig.googlePlacesApiKey;
    if (key == null) return [];

    final params = <String, String>{
      'location': '${location.latitude},${location.longitude}',
      'radius': '$radiusMeters',
      'type': type,
      'key': key,
    };
    if (keyword.isNotEmpty) params['keyword'] = keyword;

    final uri = Uri.parse('$_base/nearbysearch/json').replace(queryParameters: params);

    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return [];

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['status'] != 'OK' && data['status'] != 'ZERO_RESULTS') return [];

      final results = (data['results'] as List?) ?? [];
      final restaurants = <NearbyRestaurant>[];

      for (final raw in results.take(maxResults)) {
        final r = raw as Map<String, dynamic>;
        final geometry = r['geometry'] as Map<String, dynamic>?;
        final loc = geometry?['location'] as Map<String, dynamic>?;
        double? distKm;
        if (loc != null) {
          final lat = (loc['lat'] as num).toDouble();
          final lng = (loc['lng'] as num).toDouble();
          final meters = Geolocator.distanceBetween(
            location.latitude,
            location.longitude,
            lat,
            lng,
          );
          distKm = meters / 1000;
        }

        restaurants.add(NearbyRestaurant(
          name: r['name'] as String? ?? 'Restaurant',
          address: r['vicinity'] as String? ?? r['formatted_address'] as String? ?? '',
          rating: (r['rating'] as num?)?.toDouble() ?? 0,
          userRatingsTotal: r['user_ratings_total'] as int? ?? 0,
          types: (r['types'] as List?)?.cast<String>() ?? const [],
          placeId: r['place_id'] as String? ?? '',
          distanceKm: distKm,
          openNow: (r['opening_hours'] as Map?)?['open_now'] as bool? ?? true,
        ));
      }

      return restaurants;
    } catch (_) {
      return [];
    }
  }

  static Future<List<NearbySupermarket>> findSupermarkets(
    UserLocation location, {
    int radiusMeters = 8047,
    int maxResults = 12,
  }) async {
    final key = BackendConfig.googlePlacesApiKey;
    if (key == null) return [];

    final found = <String, NearbySupermarket>{};
    final searches = [
      {'type': 'supermarket', 'keyword': ''},
      {'type': 'grocery_or_supermarket', 'keyword': ''},
      {'type': 'store', 'keyword': 'grocery food'},
    ];

    for (final search in searches) {
      await _collectSupermarkets(
        location,
        found,
        type: search['type']!,
        keyword: search['keyword']!,
        radiusMeters: radiusMeters,
        maxResults: maxResults,
        key: key,
      );
      if (found.length >= maxResults) break;
    }

    final list = found.values.toList();
    list.sort((a, b) => (a.distanceKm ?? 99).compareTo(b.distanceKm ?? 99));
    return list.take(maxResults).toList();
  }

  static Future<void> _collectSupermarkets(
    UserLocation location,
    Map<String, NearbySupermarket> found, {
    required String type,
    required String keyword,
    required int radiusMeters,
    required int maxResults,
    required String key,
  }) async {
    final params = <String, String>{
      'location': '${location.latitude},${location.longitude}',
      'radius': '$radiusMeters',
      'type': type,
      'key': key,
    };
    if (keyword.isNotEmpty) params['keyword'] = keyword;

    final uri = Uri.parse('$_base/nearbysearch/json').replace(queryParameters: params);
    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['status'] != 'OK' && data['status'] != 'ZERO_RESULTS') return;

      for (final raw in (data['results'] as List?) ?? []) {
        final r = raw as Map<String, dynamic>;
        final name = r['name'] as String? ?? 'Store';
        final placeId = r['place_id'] as String? ?? '';
        if (placeId.isEmpty || found.containsKey(placeId)) continue;

        final geometry = r['geometry'] as Map<String, dynamic>?;
        final loc = geometry?['location'] as Map<String, dynamic>?;
        double? distKm;
        if (loc != null) {
          final meters = Geolocator.distanceBetween(
            location.latitude,
            location.longitude,
            (loc['lat'] as num).toDouble(),
            (loc['lng'] as num).toDouble(),
          );
          distKm = meters / 1000;
        }

        found[placeId] = NearbySupermarket(
          name: name,
          address: r['vicinity'] as String? ?? r['formatted_address'] as String? ?? '',
          placeId: placeId,
          distanceKm: distKm,
        );
        if (found.length >= maxResults) return;
      }
    } catch (_) {}
  }

  static Future<String?> reverseGeocodeLabel(UserLocation location) async {
    final key = BackendConfig.googlePlacesApiKey;
    if (key == null) return null;

    final uri = Uri.parse('https://maps.googleapis.com/maps/api/geocode/json').replace(
      queryParameters: {
        'latlng': '${location.latitude},${location.longitude}',
        'result_type': 'postal_code|locality|neighborhood',
        'key': key,
      },
    );

    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final results = (data['results'] as List?) ?? [];
      if (results.isEmpty) return null;
      return (results.first as Map<String, dynamic>)['formatted_address'] as String?;
    } catch (_) {
      return null;
    }
  }
}
