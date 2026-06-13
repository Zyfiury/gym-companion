import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../widgets/onboarding/custom_slider.dart';
import '../../widgets/onboarding/obsidian_shell.dart';

class BudgetStep extends StatelessWidget {
  final double weeklyBudget;
  final ValueChanged<double> onChanged;

  const BudgetStep({super.key, required this.weeklyBudget, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final stores = ['Any nearby shop', 'Supermarkets', 'Local grocers', 'Markets'];
    final activeCount = weeklyBudget < 40 ? 2 : weeklyBudget < 80 ? 3 : 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ObsidianStepHeader(
          category: 'Budget',
          title: 'Weekly food budget',
          subtitle: 'We find the best value at shops near you - chains, independents, and local grocers.',
          index: 5,
        )
            .animate()
            .fadeIn()
            .moveY(begin: 20, end: 0),
        const Spacer(),
        Center(
          child: ObsidianHeroStat(
            semanticsId: 'onboard-budget',
            value: '£${weeklyBudget.round()}',
            unit: 'per week on groceries',
          ),
        ),
        SizedBox(height: ObsidianTokens.spacingLg),
        ObsidianSlider(
          label: 'BUDGET',
          value: weeklyBudget,
          min: 20,
          max: 150,
          divisions: 26,
          labelFor: (v) => '£${v.round()}',
          onChanged: onChanged,
        ),
        SizedBox(height: ObsidianTokens.spacingLg),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: stores.asMap().entries.map((e) {
            final lit = e.key < activeCount;
            return AnimatedOpacity(
              duration: const Duration(milliseconds: ObsidianTokens.springMs),
              opacity: lit ? 1.0 : 0.25,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: ObsidianTokens.spacingSm,
                  vertical: ObsidianTokens.spacingXs,
                ),
                decoration: BoxDecoration(
                  color: lit ? ObsidianTokens.heroAccent.withValues(alpha: 0.12) : ObsidianTokens.surfaceMuted,
                  borderRadius: BorderRadius.circular(ObsidianTokens.radiusSm),
                  border: Border.all(color: lit ? ObsidianTokens.heroAccent.withValues(alpha: 0.35) : ObsidianTokens.glassBorder),
                ),
                child: Text(
                  e.value,
                  style: ObsidianTypography.label(
                    size: 11,
                    color: lit ? ObsidianTokens.heroAccent : ObsidianTokens.textMuted,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const Spacer(flex: 2),
      ],
    );
  }
}
