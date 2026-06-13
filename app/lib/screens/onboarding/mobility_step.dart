import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../widgets/onboarding/obsidian_shell.dart';
import '../../widgets/onboarding/onboarding_chip.dart';

class MobilityStep extends StatelessWidget {
  final Map<String, String> options;
  final Set<String> selected;
  final TextEditingController customController;
  final void Function(String key) onToggle;
  final void Function(String text) onCustomSubmit;

  const MobilityStep({
    super.key,
    required this.options,
    required this.selected,
    required this.customController,
    required this.onToggle,
    required this.onCustomSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ObsidianStepHeader(
          category: 'Health',
          title: 'Mobility & health',
          subtitle: 'Optional - we adapt exercises to keep you safe.',
          index: 1,
        )
            .animate()
            .fadeIn()
            .moveY(begin: 20, end: 0),
        SizedBox(height: ObsidianTokens.spacingLg),
        OnboardingChipGrid(
          items: options.entries
              .map((e) => OnboardingChipItem(id: e.key, label: e.value, selected: selected.contains(e.key)))
              .toList(),
          onToggle: onToggle,
        ),
        SizedBox(height: ObsidianTokens.spacingLg),
        OnboardingBottomLineInput(
          controller: customController,
          hint: 'Anything else we should know?',
          onSubmit: () => onCustomSubmit(customController.text),
        ),
      ],
    );
  }
}
