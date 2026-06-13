import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../widgets/onboarding/obsidian_shell.dart';
import '../../widgets/onboarding/onboarding_card.dart';

class NutritionStep extends StatelessWidget {
  final List<({String id, String title, String subtitle, IconData icon})> modes;
  final String selected;
  final ValueChanged<String> onSelect;

  const NutritionStep({
    super.key,
    required this.modes,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ObsidianStepHeader(
          category: 'Lifestyle',
          title: 'How do you eat?',
          subtitle: 'Kitchen, delivery, or dining out - we plan around it.',
          index: 6,
        )
            .animate()
            .fadeIn()
            .moveY(begin: 20, end: 0),
        SizedBox(height: ObsidianTokens.spacingLg),
        ...modes.asMap().entries.map((e) {
          final m = e.value;
          return OnboardingNutritionCard(
            title: m.title,
            subtitle: m.subtitle,
            icon: m.icon,
            selected: selected == m.id,
            semanticsId: 'nutrition-${m.id}',
            animIndex: e.key + 1,
            onTap: () => onSelect(m.id),
          );
        }),
      ],
    );
  }
}
