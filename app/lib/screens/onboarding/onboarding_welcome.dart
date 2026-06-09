import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../widgets/onboarding/nav_bar.dart';
import '../../widgets/onboarding/obsidian_shell.dart';

class OnboardingWelcome extends StatelessWidget {
  final VoidCallback onStart;

  const OnboardingWelcome({super.key, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return ObsidianShell(
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(ObsidianTokens.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              Container(
                width: ObsidianTokens.spacingXl * 2.5,
                height: ObsidianTokens.spacingXl * 2.5,
                decoration: BoxDecoration(
                  color: ObsidianTokens.surfaceDark,
                  borderRadius: BorderRadius.circular(ObsidianTokens.radiusLg),
                  border: ObsidianTokens.glassBorderDecoration(),
                  boxShadow: ObsidianTokens.glassShadow(),
                ),
                child: const Icon(Icons.fitness_center_rounded, color: ObsidianTokens.heroAccent, size: 40),
              )
                  .animate()
                  .fadeIn(duration: const Duration(milliseconds: ObsidianTokens.staggerMs))
                  .moveY(begin: 20, end: 0),
              SizedBox(height: ObsidianTokens.spacingLg),
              Text('Build your\nprotocol', style: ObsidianTypography.displayLarge())
                  .animate(delay: const Duration(milliseconds: ObsidianTokens.staggerMs))
                  .fadeIn()
                  .moveY(begin: 20, end: 0),
              SizedBox(height: ObsidianTokens.spacingSm),
              Text(
                'Seven questions. Precision nutrition and training calibrated to your body.',
                style: ObsidianTypography.body(),
              )
                  .animate(delay: const Duration(milliseconds: ObsidianTokens.staggerMs * 2))
                  .fadeIn()
                  .moveY(begin: 20, end: 0),
              const Spacer(),
              ..._features.asMap().entries.map((e) {
                return Padding(
                  padding: EdgeInsets.only(bottom: ObsidianTokens.spacingSm),
                  child: ObsidianGlass(
                    child: Row(
                      children: [
                        Icon(e.value.$2, color: ObsidianTokens.heroAccent, size: ObsidianTokens.spacingMd + ObsidianTokens.spacingXs),
                        SizedBox(width: ObsidianTokens.spacingMd),
                        Expanded(child: Text(e.value.$1, style: ObsidianTypography.body(size: 14, color: ObsidianTokens.textPrimary, weight: FontWeight.w600))),
                      ],
                    ),
                  )
                      .animate(delay: Duration(milliseconds: ObsidianTokens.staggerMs * (3 + e.key)))
                      .fadeIn()
                      .moveY(begin: 20, end: 0),
                );
              }),
              const Spacer(flex: 2),
              OnboardingNavBar(
                showBack: false,
                primaryLabel: 'Get started',
                primarySemanticsId: 'onboard-get-started',
                onPrimary: onStart,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const _features = [
    ('Workouts matched to your level', Icons.fitness_center_rounded),
    ('Meals within your diet & budget', Icons.restaurant_menu_rounded),
    ('Track weight, macros, and PRs', Icons.show_chart_rounded),
  ];
}
