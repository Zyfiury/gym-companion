import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'backend_config.dart';

class ExerciseVideo {
  final String videoId;
  final String title;
  final String thumbnail;

  ExerciseVideo({required this.videoId, required this.title, required this.thumbnail});
}

/// YouTube Data API — exercise and recipe videos with local cache.
class YouTubeService {
  static const _exerciseCacheKey = 'youtube_video_cache_v1';
  static const _recipeCacheKey = 'youtube_recipe_cache_v1';

  static bool get hasKey => BackendConfig.hasYouTube;

  static Future<ExerciseVideo?> getExerciseVideo(String exerciseName, {List<String>? modifiers}) async {
    if (!hasKey) return null;

    final modKey = modifiers?.isNotEmpty == true ? '${exerciseName}_${modifiers!.join('_')}' : exerciseName;
    return _getCachedOrSearch(modKey, () {
      final prefix = modifiers?.isNotEmpty == true ? '${modifiers!.join(' ')} ' : '';
      return '$prefix$exerciseName form tutorial';
    });
  }

  /// Search with a full query string and explicit cache key (mobility-aware).
  static Future<ExerciseVideo?> searchExercise(String searchQuery, {required String cacheKey}) async {
    if (!hasKey) return null;
    return _getCachedOrSearch(cacheKey, () => searchQuery);
  }

  static Future<void> clearExerciseCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_exerciseCacheKey);
  }

  static Future<ExerciseVideo?> _getCachedOrSearch(String cacheKey, String Function() buildQuery) async {
    final cache = await _loadCache(_exerciseCacheKey);
    if (cache.containsKey(cacheKey)) {
      final c = cache[cacheKey] as Map<String, dynamic>;
      return ExerciseVideo(
        videoId: c['videoId'] as String,
        title: c['title'] as String,
        thumbnail: c['thumbnail'] as String,
      );
    }

    final q = Uri.encodeComponent(buildQuery());
    final video = await _searchVideo(q);
    if (video == null) return null;

    cache[cacheKey] = {'videoId': video.videoId, 'title': video.title, 'thumbnail': video.thumbnail};
    await _saveCache(_exerciseCacheKey, cache);
    return video;
  }

  static Future<ExerciseVideo?> getRecipeVideo(String mealName) async {
    if (!hasKey) return null;

    final cache = await _loadCache(_recipeCacheKey);
    if (cache.containsKey(mealName)) {
      final c = cache[mealName] as Map<String, dynamic>;
      return ExerciseVideo(
        videoId: c['videoId'] as String,
        title: c['title'] as String,
        thumbnail: c['thumbnail'] as String,
      );
    }

    final q = Uri.encodeComponent('$mealName easy recipe tutorial');
    final video = await _searchVideo(q);
    if (video == null) return null;

    cache[mealName] = {'videoId': video.videoId, 'title': video.title, 'thumbnail': video.thumbnail};
    await _saveCache(_recipeCacheKey, cache);
    return video;
  }

  static Future<ExerciseVideo?> _searchVideo(String encodedQuery) async {
    final url =
        'https://www.googleapis.com/youtube/v3/search?part=snippet&q=$encodedQuery&type=video&maxResults=1&videoEmbeddable=true&key=${BackendConfig.youtubeApiKey}';

    try {
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final items = data['items'] as List? ?? [];
      if (items.isEmpty) return null;
      final item = items.first as Map<String, dynamic>;
      final id = item['id']?['videoId'] as String?;
      final snippet = item['snippet'] as Map<String, dynamic>?;
      if (id == null || snippet == null) return null;

      return ExerciseVideo(
        videoId: id,
        title: snippet['title'] as String? ?? '',
        thumbnail: snippet['thumbnails']?['medium']?['url'] as String? ?? '',
      );
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>> _loadCache(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return {};
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  static Future<void> _saveCache(String key, Map<String, dynamic> cache) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(cache));
  }
}
