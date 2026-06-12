import '../models/user_data.dart';
import 'location_service.dart';
import 'places_service.dart';

/// Resolves which shop to use for pricing and grocery links — any nearby store, not fixed chains.
class StoreService {
  static const defaultLabel = 'Local store';

  static String resolveStoreName(UserData user) {
    return user.weeklyPlan.shoppingList?['supermarket'] as String? ??
        user.monthlyPlan?.supermarket ??
        defaultLabel;
  }

  static Future<List<NearbySupermarket>> nearbyStores({int maxResults = 12}) async {
    final result = await LocationService.resolveLocation();
    final location = result.location;
    if (location == null) return const [];
    return PlacesService.findSupermarkets(location, maxResults: maxResults);
  }

  static Future<String> resolveStoreForUser(UserData user) async {
    final saved = resolveStoreName(user);
    if (saved != defaultLabel) return saved;

    final stores = await nearbyStores(maxResults: 1);
    if (stores.isNotEmpty) return stores.first.name;
    return defaultLabel;
  }
}
