import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'staggered_entry.dart';

/// Consistent elevated surface used across the app.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool bordered;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
    this.bordered = true,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;

    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: bordered ? Border.all(color: t.borderSubtle, width: 1) : null,
        boxShadow: t.cardShadow,
      ),
      child: child,
    );

    if (onTap == null) return card;
    return PressableScale(onTap: onTap, child: card);
  }
}

class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.88,
        color: context.appTheme.textMuted,
      ),
    );
  }
}

/// Circular macro progress - hero element on dashboard.
class MacroRing extends StatelessWidget {
  final double progress;
  final String value;
  final String label;
  final String sublabel;
  final Color color;
  final double size;
  final int pulseTrigger;

  const MacroRing({
    super.key,
    required this.progress,
    required this.value,
    required this.label,
    required this.sublabel,
    required this.color,
    this.size = 120,
    this.pulseTrigger = 0,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedMacroRing(
      progress: progress,
      value: value,
      label: label,
      color: color,
      size: size,
      pulseTrigger: pulseTrigger,
    );
  }
}

class StatPill extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final VoidCallback? onTap;

  const StatPill({super.key, required this.icon, required this.value, required this.label, this.onTap});

  Color _iconColor(BuildContext context) {
    final c = context.appColors;
    return switch (label) {
      'Water' => c.dusk,
      'Streak' || 'XP' => c.primary,
      _ => c.sand,
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final iconColor = _iconColor(context);
    final iconBg = iconColor.withValues(alpha: context.isDarkTheme ? 0.12 : 0.08);
    final isStreak = label == 'Streak';
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: iconColor),
            ),
            const SizedBox(height: 6),
            AnimatedSwitcher(
              duration: Duration(milliseconds: isStreak ? 250 : 300),
              transitionBuilder: (child, anim) => isStreak
                  ? ScaleTransition(scale: anim, child: child)
                  : SlideTransition(
                      position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(anim),
                      child: child,
                    ),
              child: Text(
                value,
                key: ValueKey(value),
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: t.textPrimary),
              ),
            ),
            Text(
              label.toUpperCase(),
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.88, color: t.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class ActionTile extends StatelessWidget {
  final String id;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const ActionTile({super.key, required this.id, required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;

    return Semantics(
      identifier: id,
      button: true,
      child: PressableScale(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          decoration: BoxDecoration(
            color: t.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: t.borderSubtle),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.appColors.primary.withValues(alpha: context.isDarkTheme ? 0.15 : 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: context.appColors.primary),
              ),
              const SizedBox(height: 10),
              Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: t.textPrimary)),
            ],
          ),
        ),
      ),
    );
  }
}

class MacroBar extends StatelessWidget {
  final String label;
  final int current;
  final int target;
  final Color color;

  const MacroBar({super.key, required this.label, required this.current, required this.target, required this.color});

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final pct = target > 0 ? current / target : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.88, color: t.textMuted)),
            Text('$current / $target', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: t.textPrimary)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: AnimatedProgressBar(value: pct, color: color, trackColor: t.progressTrack, height: 5),
        ),
      ],
    );
  }
}

/// Coach avatar - optional one-shot pulse on the main header only.
class CoachAvatar extends StatelessWidget {
  final double size;
  final bool pulse;

  const CoachAvatar({super.key, this.size = 52, this.pulse = false});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final iconSize = size * 0.46;
    final avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(gradient: LinearGradient(colors: [c.primary, c.sand]), shape: BoxShape.circle),
      child: Icon(Icons.auto_awesome, color: c.onPrimary, size: iconSize),
    );
    if (!pulse) return avatar;
    return PulseGlow(size: size, child: avatar);
  }
}
