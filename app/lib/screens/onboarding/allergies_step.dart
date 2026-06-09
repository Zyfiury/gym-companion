import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../widgets/onboarding/obsidian_shell.dart';
import '../../widgets/onboarding/onboarding_chip.dart';

class AllergiesStep extends StatelessWidget {
  final List<String> options;
  final Set<String> selected;
  final TextEditingController customController;
  final void Function(String key) onToggle;
  final VoidCallback onCustomAdd;

  const AllergiesStep({
    super.key,
    required this.options,
    required this.selected,
    required this.customController,
    required this.onToggle,
    required this.onCustomAdd,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ObsidianStepHeader(
          category: 'Nutrition',
          title: 'Food allergies',
          subtitle: 'We flag recipes and meals that are not safe for you.',
          index: 2,
        )
            .animate()
            .fadeIn()
            .moveY(begin: 20, end: 0),
        SizedBox(height: ObsidianTokens.spacingLg),
        OnboardingChipGrid(
          items: options.map((a) {
            final label = a.replaceAll('_', ' ');
            final pretty = label[0].toUpperCase() + label.substring(1);
            return OnboardingChipItem(
              id: a,
              label: pretty,
              selected: selected.contains(a),
              semanticsId: 'onboard-allergy-$a',
            );
          }).toList(),
          onToggle: onToggle,
        ),
        SizedBox(height: ObsidianTokens.spacingLg),
        OnboardingBottomLineInput(
          controller: customController,
          hint: 'Add custom allergy',
          onSubmit: onCustomAdd,
        ),
      ],
    );
  }
}
