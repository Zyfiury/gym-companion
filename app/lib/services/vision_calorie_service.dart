import 'dart:convert';

import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/user_data.dart';

import 'allergy_guard.dart';

import 'backend_config.dart';
import 'nutrition_lookup_service.dart';



class VisionFoodItem {

  final String name;

  final double grams;

  final int calories;

  final int protein;

  final int carbs;

  final int fat;

  final double confidence;

  final bool blocked;

  final String? blockReason;



  VisionFoodItem({

    required this.name,

    required this.grams,

    required this.calories,

    required this.protein,

    required this.carbs,

    required this.fat,

    required this.confidence,

    this.blocked = false,

    this.blockReason,

  });

}



class VisionCalorieResult {

  final List<VisionFoodItem> items;

  final double overallConfidence;

  final String? error;

  final bool isEstimated;



  VisionCalorieResult({required this.items, required this.overallConfidence, this.error, this.isEstimated = false});



  int get totalCalories => items.where((i) => !i.blocked).fold(0, (s, i) => s + i.calories);

  int get totalProtein => items.where((i) => !i.blocked).fold(0, (s, i) => s + i.protein);

}



class VisionCalorieService {

  static const _foodKeywords = [

    'food', 'meal', 'dish', 'fruit', 'vegetable', 'meat', 'chicken', 'rice', 'bread',

    'pasta', 'salad', 'sandwich', 'pizza', 'egg', 'fish', 'dessert', 'snack', 'bowl',

  ];



  static Future<VisionCalorieResult> analyze(File image, UserData user) async {

    if (!BackendConfig.hasGoogleVision) {

      return VisionCalorieResult(

        items: [],

        overallConfidence: 0,

        error: 'Add GOOGLE_VISION_API_KEY to .env and enable Cloud Vision API in Google Cloud Console.',

      );

    }



    final labels = await _detectLabels(image);

    if (labels.isEmpty) {

      return VisionCalorieResult(

        items: [],

        overallConfidence: 0,

        error: 'No food detected in image. Try a clearer photo with good lighting.',

      );

    }



    final macros = await _resolveMacros(labels);

    if (macros.isEmpty) {

      return VisionCalorieResult(

        items: [],

        overallConfidence: 0,

        error: 'Could not estimate macros for this photo. Try again or log food manually.',

      );

    }



    final items = <VisionFoodItem>[];

    var anyEstimated = false;

    for (final m in macros) {

      final name = m['name'] as String;

      final guard = AllergyGuard.checkText(name, UserAllergies.fromUser(user));

      if (m['estimated'] == true) anyEstimated = true;

      items.add(VisionFoodItem(

        name: name,

        grams: (m['grams'] as num).toDouble(),

        calories: (m['calories'] as num).round(),

        protein: (m['protein'] as num).round(),

        carbs: (m['carbs'] as num).round(),

        fat: (m['fat'] as num).round(),

        confidence: (m['confidence'] as num).toDouble(),

        blocked: !guard.isSafe,

        blockReason: guard.isSafe ? null : guard.message,

      ));

    }

    final conf = items.isEmpty ? 0.0 : items.map((i) => i.confidence).reduce((a, b) => a + b) / items.length;

    return VisionCalorieResult(items: items, overallConfidence: conf, isEstimated: anyEstimated);

  }



  static Future<List<String>> _detectLabels(File image) async {

    final key = BackendConfig.googleVisionApiKey;

    if (key == null) return const [];



    try {

      final bytes = await image.readAsBytes();

      final b64 = base64Encode(bytes);

      final res = await http

          .post(

            Uri.parse('https://vision.googleapis.com/v1/images:annotate?key=$key'),

            headers: {'Content-Type': 'application/json'},

            body: jsonEncode({

              'requests': [

                {

                  'image': {'content': b64},

                  'features': [

                    {'type': 'LABEL_DETECTION', 'maxResults': 15},

                    {'type': 'OBJECT_LOCALIZATION', 'maxResults': 10},

                  ],

                },

              ],

            }),

          )

          .timeout(const Duration(seconds: 20));



      if (res.statusCode != 200) return const [];



      final data = jsonDecode(res.body) as Map<String, dynamic>;

      final responses = (data['responses'] as List?) ?? [];

      if (responses.isEmpty) return const [];



      final r = responses.first as Map<String, dynamic>;

      final labels = <String>[];

      for (final l in (r['labelAnnotations'] as List?) ?? []) {

        final desc = (l as Map)['description'] as String? ?? '';

        if (_foodKeywords.any((k) => desc.toLowerCase().contains(k))) labels.add(desc);

      }

      for (final o in (r['localizedObjectAnnotations'] as List?) ?? []) {

        final name = (o as Map)['name'] as String? ?? '';

        if (_foodKeywords.any((k) => name.toLowerCase().contains(k)) || name.toLowerCase() != 'food') {

          labels.add(name);

        }

      }

      return labels.isEmpty ? const [] : labels.toSet().toList();

    } catch (_) {

      return const [];

    }

  }



  static Future<List<Map<String, dynamic>>> _resolveMacros(List<String> labels) async {
    final resolved = <Map<String, dynamic>>[];
    final unresolved = <String>[];

    for (final label in labels.take(6)) {
      final match = await NutritionLookupService.fromOpenFoodFacts(label);
      if (match != null && match.calories > 0) {
        resolved.add({
          'name': match.name,
          'grams': 250,
          'calories': match.calories,
          'protein': match.protein,
          'carbs': match.carbs,
          'fat': match.fat,
          'confidence': 0.88,
          'estimated': false,
        });
      } else {
        unresolved.add(label);
      }
    }

    if (unresolved.isNotEmpty) {
      final groq = await _estimateMacrosGroq(unresolved);
      for (final m in groq) {
        m['estimated'] = true;
        resolved.add(m);
      }
    }
    return resolved;
  }

  static Future<List<Map<String, dynamic>>> _estimateMacrosGroq(List<String> labels) async {

    if (!BackendConfig.hasGroq) return const [];



    try {

      final res = await http

          .post(

            Uri.parse('https://api.groq.com/openai/v1/chat/completions'),

            headers: {

              'Authorization': 'Bearer ${BackendConfig.groqApiKey}',

              'Content-Type': 'application/json',

            },

            body: jsonEncode({

              'model': 'llama-3.3-70b-versatile',

              'messages': [

                {

                  'role': 'user',

                  'content':

                      'Estimate portions and macros for: ${labels.join(', ')}. Return JSON array only: [{"name":"","grams":0,"calories":0,"protein":0,"carbs":0,"fat":0,"confidence":0.0}]',

                },

              ],

              'max_tokens': 400,

              'temperature': 0.2,

            }),

          )

          .timeout(const Duration(seconds: 20));

      if (res.statusCode == 200) {

        final data = jsonDecode(res.body);

        final raw = data['choices'][0]['message']['content'] as String;

        final match = RegExp(r'\[[\s\S]*\]').firstMatch(raw);

        if (match != null) {

          return (jsonDecode(match.group(0)!) as List).cast<Map<String, dynamic>>();

        }

      }

    } catch (_) {}

    return const [];

  }

}


