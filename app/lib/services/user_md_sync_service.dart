import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_data.dart';
import 'backend_config.dart';
import 'sync_service.dart';

/// Syncs user profile to USER.md for OpenClaw agents.
class UserMdSyncService {
  static const _workspaceUserMd = r'C:\Users\omarz\.openclaw\workspace\gymapp\USER.md';

  static const _prefsKey = 'gymapp_user_md_snapshot';

  static Future<void> syncUser(UserData user, {String? displayName}) async {
    final markdown = _buildMarkdown(user, displayName: displayName);
    await _saveSnapshot(markdown);
    if (!kIsWeb && Platform.isWindows) {
      await _writeLocalWindows(markdown);
    }
    await _queueGateway(markdown, user.userId);
  }

  static Future<void> _saveSnapshot(String markdown) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, markdown);
  }

  static String _buildMarkdown(UserData u, {String? displayName}) {
    final buf = StringBuffer();
    buf.writeln('# USER.md — Profile & Progress\n');
    buf.writeln('## Profile');
    buf.writeln('- **Goal:** ${u.goal}');
    buf.writeln('- **Weight:** ${u.weight} kg');
    buf.writeln('- **Height:** ${u.height} cm');
    buf.writeln('- **Age:** ${u.age}');
    buf.writeln('- **TDEE:** ${u.tdee} kcal');
    buf.writeln('- **Weekly budget:** £${u.weeklyBudget.toStringAsFixed(0)}');
    buf.writeln('- **Nutrition mode:** ${u.nutritionMode}');
    buf.writeln('- **Dietary restrictions:** ${u.dietaryRestrictions}');
    buf.writeln('- **Dietary preferences:** ${u.dietaryPreferences.join(', ')}');
    buf.writeln('- **Allergies:** ${u.allergies}');
    buf.writeln('- **Disabilities:** ${u.disabilities.join(', ')}');
    buf.writeln('- **Diet type:** ${u.dietType}');
    buf.writeln('- **Meal variety:** ${u.mealVariety}\n');

    buf.writeln('## OnboardingAnswers');
    buf.writeln('- **Age:** ${u.onboardingAnswers['age'] ?? u.age}');
    buf.writeln('- **Disabilities:** ${u.onboardingAnswers['disabilities'] ?? u.disabilities}');
    buf.writeln('- **Allergies:** ${u.onboardingAnswers['allergies'] ?? u.allergies}');
    buf.writeln('- **Dietary preferences:** ${u.onboardingAnswers['dietaryPreferences'] ?? u.dietaryPreferences}');
    buf.writeln('- **Goal:** ${u.onboardingAnswers['goal'] ?? u.goal}');
    buf.writeln('- **Weekly budget:** £${u.onboardingAnswers['weeklyBudget'] ?? u.weeklyBudget}');
    buf.writeln('- **Nutrition mode:** ${u.onboardingAnswers['nutritionMode'] ?? u.nutritionMode}');
    buf.writeln('- **Completed at:** ${u.onboardingAnswers['completedAt'] ?? ''}\n');

    if (u.customWorkouts.isNotEmpty) {
      buf.writeln('## CustomWorkouts');
      for (final w in u.customWorkouts) {
        buf.writeln('### ${w.name}');
        for (final e in w.exercises) {
          buf.writeln('- ${e.name}: ${e.sets}×${e.reps}, rest ${e.restSeconds}s');
        }
      }
      buf.writeln();
    }

    buf.writeln('## Weekly Plan');
    final macros = u.weeklyPlan.macros;
    buf.writeln('### Macros (daily targets)');
    buf.writeln('| Macro | Target |');
    buf.writeln('|-------|--------|');
    for (final e in macros.entries) {
      buf.writeln('| ${e.key} | ${e.value} |');
    }
    buf.writeln('\n### Workout split');
    for (final w in u.weeklyPlan.workouts) {
      buf.writeln('- **${w.day}** — ${w.focus}: ${w.exercises.join(', ')}');
    }
    if (u.weeklyPlan.meals.isNotEmpty) {
      buf.writeln('\n### Meal plan');
      for (final m in u.weeklyPlan.meals) {
        buf.writeln('- ${m.mealType}: ${m.name} (${m.macros['calories']} kcal)');
      }
    }
    if (u.weeklyPlan.shoppingList != null) {
      final sl = u.weeklyPlan.shoppingList!;
      buf.writeln('\n### Shopping list — ${sl['supermarket'] ?? 'Store'} (${sl['totalEstimatedCost'] ?? ''})');
      final items = sl['items'] as List? ?? [];
      for (final item in items) {
        final m = item as Map<String, dynamic>;
        buf.writeln('- ${m['item']} × ${m['quantity']} — ${m['price']}');
      }
    }

    if (u.monthlyPlan != null) {
      buf.writeln('\n## MonthlyPlan');
      buf.writeln('- **Supermarket:** ${u.monthlyPlan!.supermarket ?? ''}');
      buf.writeln('- **Start:** ${u.monthlyPlan!.startDate}');
      buf.writeln('- **Meals:** ${u.monthlyPlan!.meals.length} planned');
    }

    return buf.toString();
  }

  static Future<void> _writeLocalWindows(String markdown) async {
    try {
      final file = File(_workspaceUserMd);
      if (file.parent.existsSync()) {
        await file.writeAsString(markdown);
      }
    } catch (_) {}
  }

  static Future<void> _queueGateway(String markdown, String userId) async {
    final base = BackendConfig.openclawHttpBase;
    if (base == null) {
      await SyncService.enqueue({
        'type': 'USER_MD_SYNC',
        'payload': {'userId': userId, 'markdown': markdown},
      });
      return;
    }
    try {
      await http
          .post(
            Uri.parse('$base/api/sync'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'type': 'USER_MD_SYNC', 'userId': userId, 'markdown': markdown}),
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      await SyncService.enqueue({
        'type': 'USER_MD_SYNC',
        'payload': {'userId': userId, 'markdown': markdown},
      });
    }
  }
}
