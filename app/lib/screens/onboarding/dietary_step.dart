import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../widgets/onboarding/obsidian_shell.dart';
import '../../widgets/onboarding/onboarding_card.dart';

class DietaryStep extends StatelessWidget {
  final List<({String id, String label, IconData icon})> options;
  final Set<String> selected;
  final void Function(String id) onToggle;

  const DietaryStep({
    super.key,
    required this.options,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ObsidianStepHeader(
          category: 'Nutrition',
          title: 'Dietary preferences',
          subtitle: 'Pick any that apply — meal plans will follow these.',
          index: 3,
        )
            .animate()
            .fadeIn()
            .moveY(begin: 20, end: 0),
        SizedBox(height: ObsidianTokens.spacingLg),
        ...options.asMap().entries.map((e) {
          final o = e.value;
          return OnboardingDietCard(
            title: o.label,
            icon: o.icon,
            selected: selected.contains(o.id),
            animIndex: e.key + 1,
            onTap: () => onToggle(o.id),
          );
        }),
      ],
    );
  }
}
