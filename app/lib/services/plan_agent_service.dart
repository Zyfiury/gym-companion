import 'dart:convert';

import 'package:http/http.dart' as http;

import 'backend_config.dart';
import 'firebase_service.dart';
import 'supabase_service.dart';

class PlanAgentService {
  static Future<void> generateWeeklyPlanIfNeeded() async {
    if (!BackendConfig.hasGroq) return;
    if (!BackendConfig.hasFirebase && !BackendConfig.hasSupabase) return;

    Map<String, dynamic>? profile;
    Map<String, dynamic>? existing;
    String? uid;

    if (BackendConfig.hasFirebase && FirebaseService.currentUser != null) {
      uid = FirebaseService.currentUser!.uid;
      final user = await FirebaseService.loadUserData(uid);
      if (user == null) return;
      profile = {
        'goal': user.goal,
        'weight_kg': user.weight,
        'tdee': user.tdee,
        'allergies': user.allergies,
        'diet_type': user.dietType,
        'weekly_budget': user.weeklyBudget,
      };
      existing = await FirebaseService.getCurrentWeekPlan(uid);
    } else if (BackendConfig.hasSupabase) {
      profile = await SupabaseService.getProfile();
      if (profile == null) return;
      existing = await SupabaseService.getCurrentWeekPlan();
    }

    if (profile == null || existing != null) return;

    final prompt = '''
Generate a 7-day fitness and meal plan as JSON for:
Goal: ${profile['goal']} | Weight: ${profile['weight_kg']}kg | TDEE: ${profile['tdee']} kcal
Allergies (NEVER include): ${(profile['allergies'] as List?)?.join(', ') ?? 'none'}
Diet: ${profile['diet_type']} | Budget: £${profile['weekly_budget']}

Return ONLY valid JSON with keys: macros, workouts (array of {day, focus, exercises}), meals (array of {mealType, name, description, macros, ingredients, steps}), shoppingList.
''';

    try {
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer ${BackendConfig.groqApiKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile',
          'messages': [
            {'role': 'system', 'content': 'Respond with valid JSON only.'},
            {'role': 'user', 'content': prompt},
          ],
          'max_tokens': 3000,
          'temperature': 0.5,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        var raw = data['choices'][0]['message']['content'] as String;
        raw = raw.replaceAll('```json', '').replaceAll('```', '').trim();
        final plan = jsonDecode(raw) as Map<String, dynamic>;
        if (uid != null) {
          await FirebaseService.saveWeeklyPlan(uid, plan);
        } else {
          await SupabaseService.saveWeeklyPlan(plan);
        }
      }
    } catch (_) {}
  }
}
