import 'package:flutter/material.dart';

import '../models/workout_status.dart';
import '../providers/app_state.dart';
import 'daily_context_builder.dart';

/// Coach identity + copy generation (SOUL voice, daily opener, dynamic chips).
class CoachPersonalityService {
  CoachPersonalityService._();

  static const coachName = 'Mara';

  /// Condensed from SOUL.md - wired into Groq system prompt.
  static const soulInstructions = '''
Your name is Mara. You are the user's gym companion in Gym Companion - not a drill sergeant or miracle-pill salesman.

Beliefs: Small wins compound. Progress isn't linear; plateaus are normal. Celebrate effort. No bro-science, no shame, no guilt trips.

Voice: Warm, clear, honest. Use their first name when natural. Short paragraphs for mobile. Occasional ✅ for confirmations only.

Nutrition: Real food, real budgets. Work within macros and allergies (non-negotiable). Delivery and eat-out are fine.

Training: Plans they can actually finish. Form over ego. Adjust gently when energy is low or they're sore.

Never paste raw JSON or say "DAILY_CONTEXT". Reference their data naturally ("you're 40g protein short" not "according to the data").

Coaching style: Lead with insight from their numbers, then one practical next step. Sound like a knowledgeable friend who read their diary — not a FAQ bot. If they're struggling, acknowledge it before advising.
''';

  static String systemPromptPersona(Map<String, dynamic> profile) {
    final first = _firstName(profile['name'] as String?);
    return '''
$soulInstructions

You are coaching $first. Stay in character as Mara in every reply.
''';
  }

  static String dailyOpener(AppState state) {
    final first = _firstName(state.displayName);
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Morning' : hour < 17 ? 'Hey' : 'Evening';
    final ctx = DailyContextBuilder.fromAppState(state);

    final lines = <String>['$greeting $first 👋'];

    final workoutName = state.todayWorkoutName ?? ctx.workoutToday?['name'] as String?;
    switch (state.todayWorkoutStatus) {
      case WorkoutStatus.completed:
        if (workoutName != null && workoutName.isNotEmpty) {
          lines.add("Nice - $workoutName is logged. Want a recovery meal or tomorrow's plan?");
        } else {
          lines.add("You've already crushed today's session. Want help fuelling up or planning tomorrow?");
        }
      case WorkoutStatus.skipped:
        lines.add("No worries if today got away from you - want a lighter session or a fresh meal plan?");
      case WorkoutStatus.modified:
        lines.add("We adapted today's workout for how you're feeling. Want to review it or tweak meals?");
      case WorkoutStatus.planned:
        if (workoutName != null && workoutName.isNotEmpty) {
          lines.add("$workoutName is still on the board today. Want the details or should we adjust it?");
        } else if (state.isTrainingDay) {
          lines.add("Training day - want your workout breakdown or a pre-session snack idea?");
        }
    }

    final proteinTarget = ctx.macros['protein']?['target']?.round() ?? 0;
    final proteinEaten = ctx.macros['protein']?['eaten']?.round() ?? 0;
    if (proteinTarget > 0) {
      final short = proteinTarget - proteinEaten;
      if (short > 25) {
        lines.add("You're ${short}g protein short so far - I can suggest a quick hit.");
      }
    }

    final remaining = ctx.caloriesRemaining;
    if (remaining > 0 && remaining < 400 && hour >= 16) {
      lines.add('About $remaining kcal left today - want a dinner that fits?');
    }

    final streak = ctx.streak;
    if (streak >= 7) {
      lines.add("$streak-day streak - that's real consistency.");
    }

    if (state.recentPRs.isNotEmpty) {
      lines.add("Still buzzing about ${state.recentPRs.first} - ready to build on it?");
    }

    if (lines.length == 1) {
      lines.add("I'm here for workouts, meals, delivery, and the honest check-ins. What's on your mind?");
    }

    return lines.join('\n');
  }

  static List<({IconData icon, String text})> dynamicSuggestions(AppState state) {
    final ctx = DailyContextBuilder.fromAppState(state);
    final hour = DateTime.now().hour;
    final picks = <({IconData icon, String text})>[];

    if (state.todayWorkoutStatus == WorkoutStatus.completed) {
      picks.add((icon: Icons.celebration_outlined, text: 'I just finished my workout!'));
    } else {
      picks.add((icon: Icons.fitness_center, text: "Give me today's workout"));
    }

    final proteinTarget = ctx.macros['protein']?['target']?.round() ?? 0;
    final proteinEaten = ctx.macros['protein']?['eaten']?.round() ?? 0;
    if (proteinTarget > 0 && proteinEaten < proteinTarget * 0.75) {
      picks.add((icon: Icons.restaurant, text: 'High-protein meal ideas'));
    } else {
      picks.add((icon: Icons.pie_chart_outline, text: 'How are my macros looking?'));
    }

    if (hour >= 17) {
      picks.add((icon: Icons.delivery_dining, text: 'Find dinner delivery near me'));
    } else if (state.todayEnergyLevel <= 2 && state.todayEnergyLevel > 0) {
      picks.add((icon: Icons.self_improvement, text: 'Lighten my workout - low energy'));
    } else {
      picks.add((icon: Icons.swap_horiz, text: 'Swap my lunch'));
    }

    if (state.todayWorkoutStatus != WorkoutStatus.completed) {
      picks.add((icon: Icons.restaurant, text: 'Log 200g chicken breast'));
    }

    final seen = <String>{};
    final out = <({IconData icon, String text})>[];
    for (final p in picks) {
      if (seen.add(p.text)) out.add(p);
      if (out.length >= 4) break;
    }
    return out;
  }

  static String _firstName(String? raw) {
    final trimmed = raw?.trim() ?? '';
    if (trimmed.isEmpty) return 'there';
    return trimmed.split(RegExp(r'\s+')).first;
  }
}
