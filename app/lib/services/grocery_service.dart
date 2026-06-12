import 'package:url_launcher/url_launcher.dart';

class GroceryService {
  static String storeSearchUrl(String store, String item) {
    final q = Uri.encodeComponent(item);
    final s = store.toLowerCase();

    if (s.contains('tesco')) return 'https://www.tesco.com/groceries/en-GB/search?query=$q';
    if (s.contains('sainsbury')) return 'https://www.sainsburys.co.uk/gol-ui/SearchResults/$q';
    if (s.contains('asda')) return 'https://groceries.asda.com/search/$q';
    if (s.contains('aldi')) return 'https://www.aldi.co.uk/results?q=$q';
    if (s.contains('lidl')) return 'https://www.lidl.co.uk/search?query=$q';
    if (s.contains('morrisons')) return 'https://groceries.morrisons.com/search?q=$q';
    if (s.contains('waitrose')) return 'https://www.waitrose.com/ecom/shop/search?&searchTerm=$q';
    if (s.contains('ocado')) return 'https://www.ocado.com/search?entry=$q';
    if (s.contains('iceland')) return 'https://www.iceland.co.uk/search?q=$q';
    if (s.contains('co-op') || s.contains('coop')) return 'https://www.coop.co.uk/search?q=$q';
    if (s.contains('marks') || s.contains('spencer')) return 'https://www.marksandspencer.com/l/search?q=$q';
    if (s.contains('farmfoods')) return 'https://www.farmfoods.co.uk/search?q=$q';
    if (s.contains('heron')) return 'https://www.heronfoods.com/?s=$q';

    final combined = Uri.encodeComponent('$item groceries $store');
    return 'https://www.google.co.uk/search?q=$combined';
  }

  static String storeMapsUrl(String store, {String? placeId}) {
    if (placeId != null && placeId.isNotEmpty) {
      return 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(store)}&query_place_id=$placeId';
    }
    return 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(store)}';
  }

  static Future<void> searchStore(String store, String item) async {
    await launchUrl(Uri.parse(storeSearchUrl(store, item)), mode: LaunchMode.externalApplication);
  }

  static Future<void> openStore(String store, {String? placeId}) async {
    await launchUrl(Uri.parse(storeMapsUrl(store, placeId: placeId)), mode: LaunchMode.externalApplication);
  }

  static Future<void> orderShoppingList(
    List<String> items, {
    String store = 'Local store',
    String? placeId,
  }) async {
    if (items.isEmpty) return;
    final query = items.take(5).join(', ');
    if (_hasOnlineGrocery(store)) {
      await searchStore(store, query);
      return;
    }
    if (placeId != null && placeId.isNotEmpty) {
      final q = Uri.encodeComponent('$query grocery');
      await launchUrl(
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$q&query_place_id=$placeId'),
        mode: LaunchMode.externalApplication,
      );
      return;
    }
    await launchUrl(
      Uri.parse(storeSearchUrl(store, query)),
      mode: LaunchMode.externalApplication,
    );
  }

  static bool _hasOnlineGrocery(String store) {
    final s = store.toLowerCase();
    return s.contains('tesco') ||
        s.contains('sainsbury') ||
        s.contains('asda') ||
        s.contains('aldi') ||
        s.contains('lidl') ||
        s.contains('morrisons') ||
        s.contains('waitrose') ||
        s.contains('ocado') ||
        s.contains('iceland') ||
        s.contains('co-op') ||
        s.contains('coop') ||
        s.contains('marks') ||
        s.contains('spencer');
  }
}
