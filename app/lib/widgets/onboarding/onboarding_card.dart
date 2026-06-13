import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';

class OnboardingDietCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final int animIndex;

  const OnboardingDietCard({
    super.key,
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.animIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: ObsidianTokens.springMs),
        curve: Curves.easeOutCubic,
        height: ObsidianTokens.cardHeightDiet,
        margin: EdgeInsets.only(bottom: ObsidianTokens.spacingSm),
        decoration: BoxDecoration(
          color: selected ? ObsidianTokens.heroAccent.withValues(alpha: 0.06) : ObsidianTokens.surfaceDark,
          borderRadius: BorderRadius.circular(ObsidianTokens.radiusMd),
          border: Border.all(
            color: selected ? ObsidianTokens.heroAccent.withValues(alpha: 0.4) : ObsidianTokens.glassBorder,
          ),
          boxShadow: selected ? ObsidianTokens.glassShadow() : null,
        ),
        child: Row(
          children: [
            if (selected)
              Container(
                width: ObsidianTokens.accentStripe,
                decoration: const BoxDecoration(
                  color: ObsidianTokens.heroAccent,
                  borderRadius: BorderRadius.horizontal(left: Radius.circular(ObsidianTokens.radiusMd)),
                ),
              ),
            SizedBox(width: ObsidianTokens.spacingMd),
            Container(
              width: ObsidianTokens.spacingXl,
              height: ObsidianTokens.spacingXl,
              decoration: BoxDecoration(
                color: ObsidianTokens.heroAccent.withValues(alpha: selected ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(ObsidianTokens.radiusSm),
              ),
              child: Icon(icon, color: ObsidianTokens.heroAccent, size: ObsidianTokens.spacingMd),
            ),
            SizedBox(width: ObsidianTokens.spacingMd),
            Expanded(
              child: Text(title, style: ObsidianTypography.body(size: 16, color: ObsidianTokens.textPrimary, weight: FontWeight.w600)),
            ),
            _PillToggle(on: selected),
            SizedBox(width: ObsidianTokens.spacingMd),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: animIndex * ObsidianTokens.staggerMs))
        .fadeIn(duration: const Duration(milliseconds: ObsidianTokens.staggerMs))
        .moveY(begin: 20, end: 0, curve: Curves.easeOutCubic);
  }
}

class _PillToggle extends StatelessWidget {
  final bool on;

  const _PillToggle({required this.on});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: ObsidianTokens.springMs),
      curve: Curves.elasticOut,
      width: ObsidianTokens.spacingXl + ObsidianTokens.spacingSm,
      height: ObsidianTokens.spacingMd + ObsidianTokens.spacingXs,
      padding: EdgeInsets.all(ObsidianTokens.spacingXs / 2),
      decoration: BoxDecoration(
        color: on ? ObsidianTokens.heroAccent : ObsidianTokens.track,
        borderRadius: BorderRadius.circular(ObsidianTokens.radiusPill),
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: ObsidianTokens.springMs),
        curve: Curves.elasticOut,
        alignment: on ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: ObsidianTokens.spacingMd,
          height: ObsidianTokens.spacingMd,
          decoration: BoxDecoration(
            color: on ? ObsidianTokens.textOnAccent : ObsidianTokens.textMuted,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class OnboardingNutritionCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final String? semanticsId;
  final int animIndex;

  const OnboardingNutritionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.semanticsId,
    this.animIndex = 0,
  });

  @override
  State<OnboardingNutritionCard> createState() => _OnboardingNutritionCardState();
}

class _OnboardingNutritionCardState extends State<OnboardingNutritionCard> {
  bool _shimmer = false;

  @override
  void didUpdateWidget(OnboardingNutritionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected && !oldWidget.selected) {
      setState(() => _shimmer = true);
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) setState(() => _shimmer = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final card = GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: ObsidianTokens.springMs),
        height: ObsidianTokens.cardHeightNutrition,
        margin: EdgeInsets.only(bottom: ObsidianTokens.spacingSm),
        decoration: BoxDecoration(
          color: widget.selected ? ObsidianTokens.heroAccentDark : ObsidianTokens.surfaceDark,
          borderRadius: BorderRadius.circular(ObsidianTokens.radiusMd),
          border: Border.all(color: widget.selected ? ObsidianTokens.heroAccent.withValues(alpha: 0.5) : ObsidianTokens.glassBorder),
        ),
        child: Stack(
          children: [
            if (widget.selected)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: ObsidianTokens.accentStripe,
                  decoration: const BoxDecoration(
                    color: ObsidianTokens.heroAccent,
                    borderRadius: BorderRadius.horizontal(left: Radius.circular(ObsidianTokens.radiusMd)),
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.all(ObsidianTokens.spacingMd),
              child: Row(
                children: [
                  Container(
                    width: ObsidianTokens.spacingXl + ObsidianTokens.spacingXs,
                    height: ObsidianTokens.spacingXl + ObsidianTokens.spacingXs,
                    decoration: BoxDecoration(
                      color: widget.selected ? ObsidianTokens.heroAccent : ObsidianTokens.heroAccent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(ObsidianTokens.radiusSm),
                    ),
                    child: Icon(widget.icon, color: widget.selected ? ObsidianTokens.textOnAccent : ObsidianTokens.heroAccent),
                  ),
                  SizedBox(width: ObsidianTokens.spacingMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(widget.title, style: ObsidianTypography.body(size: 16, color: ObsidianTokens.textPrimary, weight: FontWeight.w700)),
                        Text(widget.subtitle, style: ObsidianTypography.body(size: 13, color: ObsidianTokens.textMuted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_shimmer)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(ObsidianTokens.radiusMd),
                    gradient: LinearGradient(
                      colors: [Colors.transparent, ObsidianTokens.textOnAccent.withValues(alpha: 0.08), Colors.transparent],
                    ),
                  ),
                ).animate().shimmer(duration: const Duration(milliseconds: 600)),
              ),
          ],
        ),
      ),
    );

    final wrapped = widget.semanticsId == null
        ? card
        : Semantics(identifier: widget.semanticsId, button: true, child: card);

    return wrapped
        .animate(delay: Duration(milliseconds: widget.animIndex * ObsidianTokens.staggerMs))
        .fadeIn(duration: const Duration(milliseconds: ObsidianTokens.staggerMs))
        .moveY(begin: 20, end: 0);
  }
}
