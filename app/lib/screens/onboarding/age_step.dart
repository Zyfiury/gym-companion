import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../widgets/onboarding/age_wheel.dart';
import '../../widgets/onboarding/obsidian_shell.dart';

class AgeStep extends StatelessWidget {
  final int age;
  final ValueChanged<int> onAgeChanged;

  const AgeStep({super.key, required this.age, required this.onAgeChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ObsidianStepHeader(
          category: 'About you',
          title: 'How old are you?',
          subtitle: 'Used for calorie and recovery estimates.',
          index: 0,
        )
            .animate()
            .fadeIn(duration: const Duration(milliseconds: ObsidianTokens.staggerMs))
            .moveY(begin: 20, end: 0),
        const Spacer(),
        Center(
          child: SimpleAgePicker(
            age: age,
            semanticsId: 'onboard-age-picker',
            onChanged: onAgeChanged,
          ),
        ),
        const Spacer(),
      ],
    );
  }
}
