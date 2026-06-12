import 'dart:convert';
import 'package:http/http.dart' as http;
import 'backend_config.dart';

class AiAction {
  final String type;
  final Map<String, dynamic> data;
  AiAction({required this.type, required this.data});
}

class AiResponse {
  final String displayText;
  final List<AiAction> actions;
  AiResponse({required this.displayText, required this.actions});
}

class GroqChatService {
  static const _url = 'https://api.groq.com/openai/v1/chat/completions';
  static const _model = 'llama-3.3-70b-versatile';

  static Future<AiResponse> chat({
    required String userMessage,
    required Map<String, dynamic> userProfile,
    required List<Map<String, String>> history,
  }) async {
    if (!BackendConfig.hasGroq) {
      return AiResponse(
        displayText: '⚠️ Add your GROQ_API_KEY to .env for real AI chat. Using rule-based fallback.',
        actions: [],
      );
    }

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': _systemPrompt(userProfile)},
      ...history.take(20),
      {'role': 'user', 'content': userMessage},
    ];

    try {
      final response = await http
          .post(
            Uri.parse(_url),
            headers: {
              'Authorization': 'Bearer ${BackendConfig.groqApiKey}',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': _model,
              'messages': messages,
              'max_tokens': 700,
              'temperature': 0.75,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final raw = data['choices'][0]['message']['content'] as String;
        return AiResponse(displayText: _clean(raw), actions: _extractActions(raw));
      }
      if (response.statusCode == 401) {
        return AiResponse(displayText: '❌ Invalid Groq API key.', actions: []);
      }
      if (response.statusCode == 429) {
        return AiResponse(displayText: '⏳ Rate limited. Try again shortly.', actions: []);
      }
      return AiResponse(displayText: 'AI error (${response.statusCode}). Try again.', actions: []);
    } catch (e) {
      return AiResponse(displayText: 'Connection error. Check internet and try again.', actions: []);
    }
  }

  static String _systemPrompt(Map<String, dynamic> p) {
    final dailyContext = p['daily_context'];
    final dailyJson = dailyContext != null ? dailyContext.toString() : '{}';
    return '''
You are an expert AI fitness and nutrition coach in Gym Companion. Be warm, concise, and personalised.

USER: ${p['name']} | Goal: ${p['goal']} | ${p['weight_kg']}kg | ${p['height_cm']}cm | Age ${p['age']} | Gender: ${p['gender_at_birth']}
TDEE target: ${p['tdee']} kcal
Allergies (NEVER suggest): ${(p['allergies'] as List?)?.join(', ') ?? 'none'}
Disabilities: ${(p['disabilities'] as List?)?.join(', ') ?? 'none'} | Pregnant: ${p['pregnant']}
Medications: ${(p['medications'] as List?)?.join(', ') ?? 'none'}
Period tracking: ${p['tracks_period']} | Phase: ${p['period_phase'] ?? 'n/a'}
Diet: ${p['diet_type']} | Budget: £${p['weekly_budget']}/week
Banned meals: ${(p['banned_meals'] as List?)?.join(', ') ?? 'none'}
XP: ${p['xp']} Level: ${p['level']}

Context period: ${p['context_period']} — ${p['context_note'] ?? ''}

DAILY_CONTEXT (system only — reference naturally, NEVER paste raw JSON to the user):
$dailyJson

Use daily_context for accurate answers about calories remaining, workout completion, steps, and macros today.

When logging food append on its own line: ACTION:LOG_FOOD:[name]:[calories]:[protein]:[carbs]:[fat]
Current weight ONLY (e.g. "I weigh 110kg", "set my weight to 72kg"): ACTION:UPDATE_WEIGHT:[kg] or ACTION:LOG_WEIGHT:[kg]
NEVER use UPDATE_WEIGHT for weight LOSS goals ("lose 10kg", "drop 5kg") — those are targets to lose, not the user's body weight. For loss goals use ACTION:UPDATE_GOAL:cut and discuss feasibility; only UPDATE_WEIGHT if they state their current weight.
Swap meal: ACTION:SWAP_MEAL:[Breakfast|Lunch|Dinner]:[new_meal_name]
Log PR: ACTION:LOG_PR:[exercise]:[value]:[unit]
Goal change: ACTION:UPDATE_GOAL:[cut|bulk|maintain]
Add allergy: ACTION:ADD_ALLERGY:[allergen]
Workout change/adapt: ACTION:UPDATE_WORKOUT
Add disability: ACTION:ADD_DISABILITY:[knee_injury|back_pain|shoulder_injury|wheelchair|mobility_limited]
Pregnancy: ACTION:SET_PREGNANT:[true|false]
Period phase: ACTION:SET_PERIOD:[menstrual|follicular|ovulation|luteal|none]

Use metric units. Never suggest allergen foods. Keep replies short for mobile.

DELIVERY: If the user asks about Uber Eats, Deliveroo, takeaway, or restaurants near them, say:
"I'll search real restaurants near you — one moment!" The app handles location search automatically; do NOT invent restaurant names.
''';
  }

  static List<AiAction> _extractActions(String raw) {
    final actions = <AiAction>[];

    final log = RegExp(r'ACTION:LOG_FOOD:([^:\n]+):(\d+(?:\.\d+)?):(\d+(?:\.\d+)?):(\d+(?:\.\d+)?):(\d+(?:\.\d+)?)').firstMatch(raw);
    if (log != null) {
      actions.add(AiAction(type: 'LOG_FOOD', data: {
        'name': log.group(1)!.trim(),
        'calories': double.parse(log.group(2)!),
        'protein': double.parse(log.group(3)!),
        'carbs': double.parse(log.group(4)!),
        'fat': double.parse(log.group(5)!),
      }));
    }

    final w = RegExp(r'ACTION:(?:UPDATE_WEIGHT|LOG_WEIGHT):([\d.]+)').firstMatch(raw);
    if (w != null) actions.add(AiAction(type: 'UPDATE_WEIGHT', data: {'weight_kg': double.parse(w.group(1)!)}));

    final swap = RegExp(r'ACTION:SWAP_MEAL:([^:\n]+):([^\n]+)').firstMatch(raw);
    if (swap != null) {
      actions.add(AiAction(type: 'SWAP_MEAL', data: {'meal_type': swap.group(1)!.trim(), 'name': swap.group(2)!.trim()}));
    }

    final pr = RegExp(r'ACTION:LOG_PR:([^:\n]+):([\d.]+):([^\n]+)').firstMatch(raw);
    if (pr != null) {
      actions.add(AiAction(type: 'LOG_PR', data: {
        'exercise': pr.group(1)!.trim(),
        'value': double.parse(pr.group(2)!),
        'unit': pr.group(3)!.trim(),
      }));
    }

    if (RegExp(r'ACTION:COMPLETE_WORKOUT:([^\n]+)').hasMatch(raw)) {
      final cw = RegExp(r'ACTION:COMPLETE_WORKOUT:([^\n]+)').firstMatch(raw);
      actions.add(AiAction(type: 'COMPLETE_WORKOUT', data: {'name': cw?.group(1)?.trim() ?? 'Workout'}));
    }

    final g = RegExp(r'ACTION:UPDATE_GOAL:(cut|bulk|maintain)').firstMatch(raw);
    if (g != null) actions.add(AiAction(type: 'UPDATE_GOAL', data: {'goal': g.group(1)!}));

    final a = RegExp(r'ACTION:ADD_ALLERGY:([^\n]+)').firstMatch(raw);
    if (a != null) actions.add(AiAction(type: 'ADD_ALLERGY', data: {'allergen': a.group(1)!.trim().toLowerCase()}));

    final xp = RegExp(r'ACTION:ADD_XP:(\d+)').firstMatch(raw);
    if (xp != null) actions.add(AiAction(type: 'ADD_XP', data: {'amount': int.parse(xp.group(1)!)}));

    if (RegExp(r'ACTION:UPDATE_WORKOUT').hasMatch(raw)) {
      actions.add(AiAction(type: 'UPDATE_WORKOUT', data: {}));
    }

    final dis = RegExp(r'ACTION:ADD_DISABILITY:([^\n]+)').firstMatch(raw);
    if (dis != null) actions.add(AiAction(type: 'ADD_DISABILITY', data: {'tag': dis.group(1)!.trim()}));

    final preg = RegExp(r'ACTION:SET_PREGNANT:(true|false)').firstMatch(raw);
    if (preg != null) actions.add(AiAction(type: 'SET_PREGNANT', data: {'value': preg.group(1) == 'true'}));

    final period = RegExp(r'ACTION:SET_PERIOD:([^\n]+)').firstMatch(raw);
    if (period != null) {
      final phase = period.group(1)!.trim();
      actions.add(AiAction(type: 'SET_PERIOD', data: {'phase': phase == 'none' ? null : phase}));
    }

    return actions;
  }

  static String _clean(String raw) => raw.replaceAll(RegExp(r'ACTION:[A-Z_]+:[^\n]*\n?'), '').trim();

  /// Exposed for unit tests.
  static List<AiAction> parseActions(String raw) => _extractActions(raw);

  static String cleanDisplayText(String raw) => _clean(raw);
}
