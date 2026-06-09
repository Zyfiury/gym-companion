import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/tdee_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/onboarding/custom_slider.dart';
import '../../widgets/onboarding/goal_card.dart';
import '../../widgets/onboarding/obsidian_shell.dart';
import '../../widgets/onboarding/onboarding_chip.dart';

class GoalStep extends StatelessWidget {
  final int age;
  final double weight;
  final double height;
  final String goal;
  final String genderAtBirth;
  final ValueChanged<double> onWeightChanged;
  final ValueChanged<double> onHeightChanged;
  final ValueChanged<String> onGoalChanged;
  final ValueChanged<String> onGenderChanged;

  const GoalStep({
    super.key,
    required this.age,
    required this.weight,
    required this.height,
    required this.goal,
    required this.genderAtBirth,
    required this.onWeightChanged,
    required this.onHeightChanged,
    required this.onGoalChanged,
    required this.onGenderChanged,
  });

  @override
  Widget build(BuildContext context) {
    final plan = TdeeService.plan(
      weightKg: weight,
      heightCm: height,
      age: age,
      goal: goal.isEmpty ? 'maintain' : goal,
      genderAtBirth: genderAtBirth,
    );
    final inputsLine = TdeeService.inputsSummary(
      weightKg: weight,
      heightCm: height,
      age: age,
      genderAtBirth: genderAtBirth,
    );
    final displayCalories = goal.isEmpty ? plan.maintenance : plan.target;

    return ListView(
      children: [
        ObsidianStepHeader(
          category: 'Goals',
          title: 'Your body & goal',
          subtitle: 'Calories from your weight, height, age & goal (Mifflin-St Jeor).',
          index: 4,
        )
            .animate()
            .fadeIn()
            .moveY(begin: 20, end: 0),
        SizedBox(height: ObsidianTokens.spacingLg),
        Center(
          child: TdeeHeroDisplay(
            value: displayCalories,
            unit: goal.isEmpty ? 'kcal maintenance' : 'kcal / day',
            subtitle: goal.isEmpty
                ? 'Select a goal below to see your daily target'
                : TdeeService.planSubtitle(plan),
            semanticsId: 'onboard-tdee-preview',
          ),
        )
            .animate(delay: const Duration(milliseconds: ObsidianTokens.staggerMs))
            .fadeIn()
            .moveY(begin: 20, end: 0),
        SizedBox(height: ObsidianTokens.spacingMd),
        Center(
          child: Text(inputsLine, style: ObsidianTypography.body(size: 13, color: ObsidianTokens.textMuted)),
        ),
        SizedBox(height: ObsidianTokens.spacingLg),
        Text('SEX AT BIRTH', style: ObsidianTypography.label()),
        SizedBox(height: ObsidianTokens.spacingSm),
        Row(
          children: [
            Expanded(
              child: OnboardingChip(
                label: 'Male',
                selected: genderAtBirth == 'male',
                semanticsId: 'gender-male',
                onTap: () => onGenderChanged('male'),
              ),
            ),
            SizedBox(width: ObsidianTokens.spacingSm),
            Expanded(
              child: OnboardingChip(
                label: 'Female',
                selected: genderAtBirth == 'female',
                semanticsId: 'gender-female',
                onTap: () => onGenderChanged('female'),
              ),
            ),
          ],
        ),
        SizedBox(height: ObsidianTokens.spacingLg),
        ObsidianSlider(
          label: 'WEIGHT',
          value: weight,
          min: 45,
          max: 130,
          divisions: 85,
          labelFor: (v) => '${v.round()} kg',
          onChanged: onWeightChanged,
        ),
        SizedBox(height: ObsidianTokens.spacingMd),
        ObsidianSlider(
          label: 'HEIGHT',
          value: height,
          min: 140,
          max: 210,
          divisions: 70,
          labelFor: (v) => '${v.round()} cm',
          onChanged: onHeightChanged,
        ),
        SizedBox(height: ObsidianTokens.spacingLg),
        GoalCard(
          title: 'Cut',
          descriptor: 'lose fat',
          icon: Icons.trending_down_rounded,
          selected: goal == 'cut',
          semanticsId: 'goal-cut',
          animIndex: 1,
          onTap: () => onGoalChanged('cut'),
        ),
        GoalCard(
          title: 'Bulk',
          descriptor: 'build muscle',
          icon: Icons.fitness_center_rounded,
          selected: goal == 'bulk',
          semanticsId: 'goal-bulk',
          animIndex: 2,
          onTap: () => onGoalChanged('bulk'),
        ),
        GoalCard(
          title: 'Maintain',
          descriptor: 'stay steady',
          icon: Icons.balance_rounded,
          selected: goal == 'maintain',
          semanticsId: 'goal-maintain',
          animIndex: 3,
          onTap: () => onGoalChanged('maintain'),
        ),
      ],
    );
  }
}
