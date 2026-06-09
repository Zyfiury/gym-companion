import 'package:url_launcher/url_launcher.dart';

class GroceryService {
  static String _storeSearchUrl(String store, String item) {
    final q = Uri.encodeComponent(item);
    final s = store.toLowerCase();
    if (s.contains('tesco')) return 'https://www.tesco.com/groceries/en-GB/search?query=$q';
    if (s.contains('sainsbury')) return 'https://www.sainsburys.co.uk/gol-ui/SearchResults/$q';
    if (s.contains('asda')) return 'https://groceries.asda.com/search/$q';
    if (s.contains('aldi')) return 'https://www.aldi.co.uk/results?q=$q';
    if (s.contains('lidl')) return 'https://www.lidl.co.uk/search?query=$q';
    if (s.contains('morrisons')) return 'https://groceries.morrisons.com/search?q=$q';
    return 'https://www.tesco.com/groceries/en-GB/search?query=$q';
  }

  static Future<void> searchStore(String store, String item) async {
    await launchUrl(Uri.parse(_storeSearchUrl(store, item)), mode: LaunchMode.externalApplication);
  }

  static Future<void> orderShoppingList(List<String> items, {String store = 'Tesco'}) async {
    if (items.isEmpty) return;
    final query = items.take(3).join(', ');
    await searchStore(store, query);
  }
}