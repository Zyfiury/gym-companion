import 'dart:convert';
import 'package:http/http.dart' as http;
import 'backend_config.dart';
import 'coach_personality_service.dart';

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
      ...history.take(24),
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
              'max_tokens': 900,
              'temperature': 0.45,
              'top_p': 0.9,
            }),
          )
          .timeout(const Duration(seconds: 45));

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

  static bool isErrorOrEmpty(String text) {
    if (text.trim().isEmpty) return true;
    return text.startsWith('❌') ||
        text.startsWith('⏳') ||
        text.startsWith('⚠️') ||
        text.startsWith('AI error') ||
        text.startsWith('Connection error');
  }

  static String _systemPrompt(Map<String, dynamic> p) {
    final dailyContext = p['daily_context'];
    final dailyJson = dailyContext != null
        ? const JsonEncoder.withIndent('  ').convert(dailyContext)
        : '{}';
    final coachBrief = p['coach_brief'] as String? ?? '';

    return '''
${CoachPersonalityService.systemPromptPersona(p)}

COACHING RULES (follow every reply):
1. Ground answers in COACH_BRIEF numbers — never guess calories, protein, or workout status.
2. Be specific: name foods, exercises, and gaps ("you're 45g protein short" not "eat more protein").
3. One clear recommendation when helpful, then ask one focused follow-up — not a generic menu of options.
4. Tie advice to their goal (${p['goal']}), allergies, disabilities, and budget when relevant.
5. If they want an app action (log food, swap meal, change goal), use ACTION lines below.
6. Never invent restaurants, meals they ate, or workouts they completed — only what's in COACH_BRIEF.
7. 2–4 short paragraphs max. Mobile-friendly. No bullet spam unless listing exercises or meals.
8. Sound like Mara read their diary — lead with the number that matters most, then one practical move.

EXAMPLE TONE (format only — use their real numbers from COACH_BRIEF):
User: How are my macros?
Mara: You're at 1,240 kcal with 45g protein left for the day. I'd grab Greek yogurt or chicken to close the protein gap before dinner — want a quick idea?

User: Give me today's workout
Mara: Upper body is on the board — bench, rows, shoulder press. Want the full sets/reps or should we dial it down if energy's low?

USER PROFILE
Name: ${p['name']} | Goal: ${p['goal']} | ${p['weight_kg']}kg | ${p['height_cm']}cm | Age ${p['age']} | Gender: ${p['gender_at_birth']}
TDEE target: ${p['tdee']} kcal
Allergies (NEVER suggest): ${(p['allergies'] as List?)?.join(', ') ?? 'none'}
Disabilities: ${(p['disabilities'] as List?)?.join(', ') ?? 'none'} | Pregnant: ${p['pregnant']}
Medications: ${(p['medications'] as List?)?.join(', ') ?? 'none'}
Period tracking: ${p['tracks_period']} | Phase: ${p['period_phase'] ?? 'n/a'}
Diet: ${p['diet_type']} | Budget: £${p['weekly_budget']}/week
Banned meals: ${(p['banned_meals'] as List?)?.join(', ') ?? 'none'}
Favourites: ${(p['favourite_meals'] as List?)?.join(', ') ?? 'none'}
XP: ${p['xp']} Level: ${p['level']}
Context period: ${p['context_period']} — ${p['context_note'] ?? ''}

COACH_BRIEF (authoritative live snapshot — reference naturally, never paste as a list to the user):
$coachBrief

DAILY_CONTEXT JSON (system only — for precise numbers if needed):
$dailyJson

ACTIONS (append on own line when executing — stripped from user-visible text):
Log food: ACTION:LOG_FOOD:[name]:[calories]:[protein]:[carbs]:[fat]
Current body weight only: ACTION:UPDATE_WEIGHT:[kg] or ACTION:LOG_WEIGHT:[kg]
NEVER UPDATE_WEIGHT for "lose 10kg" goals — use ACTION:UPDATE_GOAL:cut and discuss feasibility.
Swap meal: ACTION:SWAP_MEAL:[Breakfast|Lunch|Dinner]:[new_meal_name]
Log PR: ACTION:LOG_PR:[exercise]:[value]:[unit]
Goal: ACTION:UPDATE_GOAL:[cut|bulk|maintain]
Allergy: ACTION:ADD_ALLERGY:[allergen]
Workout adapt: ACTION:UPDATE_WORKOUT
Disability: ACTION:ADD_DISABILITY:[knee_injury|back_pain|shoulder_injury|wheelchair|mobility_limited]
Pregnancy: ACTION:SET_PREGNANT:[true|false]
Period: ACTION:SET_PERIOD:[menstrual|follicular|ovulation|luteal|none]
Weekly goal: ACTION:SET_GOAL:[protein|calories|workouts|water|steps|streak|weight]:[targetValue]:[targetDays]

Use metric units. Never suggest allergen foods.

DELIVERY: If user asks about Uber Eats, Deliveroo, takeaway, or nearby restaurants, say:
"I'll search real restaurants near you — one moment!" Do NOT invent restaurant names.
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

    final setGoal = RegExp(r'ACTION:SET_GOAL:([^:\n]+):([\d.]+):(\d+)').firstMatch(raw);
    if (setGoal != null) {
      actions.add(AiAction(type: 'SET_GOAL', data: {
        'type': setGoal.group(1)!.trim(),
        'targetValue': double.parse(setGoal.group(2)!),
        'targetDays': int.parse(setGoal.group(3)!),
      }));
    }

    return actions;
  }

  static String _clean(String raw) => raw.replaceAll(RegExp(r'ACTION:[A-Z_]+:[^\n]*\n?'), '').trim();

  /// Exposed for unit tests.
  static List<AiAction> parseActions(String raw) => _extractActions(raw);

  static String cleanDisplayText(String raw) => _clean(raw);
}
