import 'dart:convert';

import 'package:http/http.dart' as http;

import 'backend_config.dart';
import 'nutrition_lookup_service.dart';

class VoiceFoodResult {
  final String name;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final int fiber;
  final int sugar;
  final int sodiumMg;
  final String? error;

  const VoiceFoodResult({
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber = 0,
    this.sugar = 0,
    this.sodiumMg = 0,
    this.error,
  });

  Map<String, dynamic> toProductMap() => {
        'name': name,
        'brand': '',
        'calories': calories.toDouble(),
        'protein': protein.toDouble(),
        'carbs': carbs.toDouble(),
        'fat': fat.toDouble(),
        'fiber': fiber.toDouble(),
        'sugar': sugar.toDouble(),
        'sodiumMg': sodiumMg.toDouble(),
        'allergens': <String>[],
      };
}

/// Parses spoken meal descriptions via Groq, with Open Food Facts fallback.
class VoiceFoodService {
  static const _model = 'llama-3.3-70b-versatile';

  static Future<VoiceFoodResult> parse(String spoken) async {
    final trimmed = spoken.trim();
    if (trimmed.length < 3) {
      return const VoiceFoodResult(
        name: '',
        calories: 0,
        protein: 0,
        carbs: 0,
        fat: 0,
        error: 'Say what you ate - e.g. "chicken rice bowl"',
      );
    }

    if (BackendConfig.hasGroq) {
      final groq = await _parseWithGroq(trimmed);
      if (groq != null) return groq;
    }

    final match = await NutritionLookupService.fromOpenFoodFacts(trimmed);
    if (match != null) {
      return VoiceFoodResult(
        name: match.name,
        calories: match.calories,
        protein: match.protein,
        carbs: match.carbs,
        fat: match.fat,
        fiber: match.fiber,
        sugar: match.sugar,
        sodiumMg: match.sodiumMg,
      );
    }

    return VoiceFoodResult(
      name: trimmed,
      calories: 400,
      protein: 25,
      carbs: 40,
      fat: 12,
      error: 'Estimated values - edit before logging',
    );
  }

  static Future<VoiceFoodResult?> _parseWithGroq(String spoken) async {
    try {
      final res = await http
          .post(
            Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
            headers: {
              'Authorization': 'Bearer ${BackendConfig.groqApiKey}',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': _model,
              'messages': [
                {
                  'role': 'system',
                  'content':
                      'Parse the meal description. Return ONLY valid JSON: '
                      '{"name":"","calories":0,"protein":0,"carbs":0,"fat":0}',
                },
                {'role': 'user', 'content': spoken},
              ],
              'max_tokens': 200,
              'temperature': 0.2,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final raw = data['choices'][0]['message']['content'] as String;
      final match = RegExp(r'\{[\s\S]*\}').firstMatch(raw);
      if (match == null) return null;
      final j = jsonDecode(match.group(0)!) as Map<String, dynamic>;
      return VoiceFoodResult(
        name: j['name'] as String? ?? spoken,
        calories: (j['calories'] as num?)?.round() ?? 0,
        protein: (j['protein'] as num?)?.round() ?? 0,
        carbs: (j['carbs'] as num?)?.round() ?? 0,
        fat: (j['fat'] as num?)?.round() ?? 0,
      );
    } catch (_) {
      return null;
    }
  }
}
