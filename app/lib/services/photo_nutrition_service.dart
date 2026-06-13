import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'backend_config.dart';

enum PhotoConfidence { low, medium, high }

class PhotoNutritionItem {
  final String name;
  final double estimatedGrams;
  final int calories;

  const PhotoNutritionItem({
    required this.name,
    required this.estimatedGrams,
    required this.calories,
  });

  factory PhotoNutritionItem.fromJson(Map<String, dynamic> j) => PhotoNutritionItem(
        name: j['name'] as String? ?? 'Food',
        estimatedGrams: (j['estimatedGrams'] as num?)?.toDouble() ?? 0,
        calories: (j['calories'] as num?)?.round() ?? 0,
      );
}

class PhotoNutritionResult {
  final String mealName;
  final int estimatedCalories;
  final PhotoConfidence confidence;
  final int protein;
  final int carbs;
  final int fat;
  final int fiber;
  final int sugar;
  final int sodiumMg;
  final List<PhotoNutritionItem> items;
  final String portionNote;
  final String? error;

  const PhotoNutritionResult({
    required this.mealName,
    required this.estimatedCalories,
    required this.confidence,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber = 0,
    this.sugar = 0,
    this.sodiumMg = 0,
    required this.items,
    this.portionNote = '',
    this.error,
  });

  bool get needsCaution => confidence == PhotoConfidence.low || error != null;
}

class PhotoNutritionService {
  static const _model = 'meta-llama/llama-4-scout-17b-16e-instruct';

  static Future<PhotoNutritionResult> analyze(File image) async {
    if (!BackendConfig.hasGroq) {
      return const PhotoNutritionResult(
        mealName: 'Meal',
        estimatedCalories: 0,
        confidence: PhotoConfidence.low,
        protein: 0,
        carbs: 0,
        fat: 0,
        items: [],
        error: 'Groq API key required for photo analysis',
      );
    }

    try {
      final bytes = await image.readAsBytes();
      final b64 = base64Encode(bytes);
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
                      'You are a nutrition expert. Return ONLY valid JSON, no markdown, no explanation: '
                      '{"mealName":"","estimatedCalories":0,"confidence":"low|medium|high",'
                      '"macros":{"protein":0,"carbs":0,"fat":0,"fiber":0,"sugar":0,"sodiumMg":0},'
                      '"items":[{"name":"","estimatedGrams":0,"calories":0}],'
                      '"portionNote":""}',
                },
                {
                  'role': 'user',
                  'content': [
                    {'type': 'text', 'text': 'Analyse this meal photo and estimate nutrition.'},
                    {'type': 'image_url', 'image_url': {'url': 'data:image/jpeg;base64,$b64'}},
                  ],
                },
              ],
              'max_tokens': 600,
              'temperature': 0.2,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode != 200) {
        return PhotoNutritionResult(
          mealName: 'Meal',
          estimatedCalories: 0,
          confidence: PhotoConfidence.low,
          protein: 0,
          carbs: 0,
          fat: 0,
          items: [],
          error: 'Something went wrong - tap to retry',
        );
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final raw = data['choices'][0]['message']['content'] as String;
      final match = RegExp(r'\{[\s\S]*\}').firstMatch(raw);
      if (match == null) {
        return _lowConfidence('Could not read the photo - edit values before logging');
      }

      final j = jsonDecode(match.group(0)!) as Map<String, dynamic>;
      final macros = j['macros'] as Map<String, dynamic>? ?? {};
      final confStr = j['confidence'] as String? ?? 'low';
      final confidence = PhotoConfidence.values.firstWhere(
        (c) => c.name == confStr,
        orElse: () => PhotoConfidence.low,
      );
      final items = (j['items'] as List?)
              ?.map((e) => PhotoNutritionItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];

      final protein = (macros['protein'] as num?)?.round() ?? 0;
      final carbs = (macros['carbs'] as num?)?.round() ?? 0;
      final fat = (macros['fat'] as num?)?.round() ?? 0;
      var fiber = (macros['fiber'] as num?)?.round() ?? 0;
      var sugar = (macros['sugar'] as num?)?.round() ?? 0;
      var sodiumMg = (macros['sodiumMg'] as num?)?.round() ?? 0;
      if (fiber == 0 && carbs > 0) fiber = (carbs * 0.12).round();
      if (sugar == 0 && carbs > 0) sugar = (carbs * 0.25).round();
      if (sodiumMg == 0) sodiumMg = 450;

      if (items.isEmpty && (j['estimatedCalories'] as num? ?? 0) == 0) {
        return _lowConfidence("Couldn't identify food in this photo. Try again or log manually.");
      }

      return PhotoNutritionResult(
        mealName: j['mealName'] as String? ?? 'Meal',
        estimatedCalories: (j['estimatedCalories'] as num?)?.round() ?? 0,
        confidence: confidence,
        protein: protein,
        carbs: carbs,
        fat: fat,
        fiber: fiber,
        sugar: sugar,
        sodiumMg: sodiumMg,
        items: items,
        portionNote: j['portionNote'] as String? ?? '',
      );
    } catch (_) {
      return _lowConfidence('Something went wrong - tap to retry');
    }
  }

  static PhotoNutritionResult _lowConfidence(String message) => PhotoNutritionResult(
        mealName: 'Meal',
        estimatedCalories: 0,
        confidence: PhotoConfidence.low,
        protein: 0,
        carbs: 0,
        fat: 0,
        items: [],
        error: message,
      );

  static PhotoNutritionResult scale(PhotoNutritionResult base, double multiplier) {
    return PhotoNutritionResult(
      mealName: base.mealName,
      estimatedCalories: (base.estimatedCalories * multiplier).round(),
      confidence: base.confidence,
      protein: (base.protein * multiplier).round(),
      carbs: (base.carbs * multiplier).round(),
      fat: (base.fat * multiplier).round(),
      fiber: (base.fiber * multiplier).round(),
      sugar: (base.sugar * multiplier).round(),
      sodiumMg: (base.sodiumMg * multiplier).round(),
      items: base.items
          .map(
            (i) => PhotoNutritionItem(
              name: i.name,
              estimatedGrams: i.estimatedGrams * multiplier,
              calories: (i.calories * multiplier).round(),
            ),
          )
          .toList(),
      portionNote: base.portionNote,
      error: base.error,
    );
  }
}
