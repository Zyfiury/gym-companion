import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';

class GoalCard extends StatelessWidget {
  final String title;
  final String descriptor;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final String? semanticsId;
  final int animIndex;

  const GoalCard({
    super.key,
    required this.title,
    required this.descriptor,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.semanticsId,
    this.animIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final card = GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: ObsidianTokens.springMs),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.all(ObsidianTokens.spacingMd),
        decoration: BoxDecoration(
          color: selected ? ObsidianTokens.heroAccent.withValues(alpha: 0.08) : ObsidianTokens.surfaceDark,
          borderRadius: BorderRadius.circular(ObsidianTokens.radiusMd),
          border: Border.all(
            color: selected ? ObsidianTokens.heroAccent : ObsidianTokens.glassBorder,
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected ? ObsidianTokens.glassShadow(tint: ObsidianTokens.heroAccent) : null,
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(ObsidianTokens.spacingSm),
              decoration: BoxDecoration(
                color: ObsidianTokens.heroAccent.withValues(alpha: selected ? 0.25 : 0.1),
                borderRadius: BorderRadius.circular(ObsidianTokens.radiusSm),
              ),
              child: Icon(icon, color: ObsidianTokens.heroAccent, size: ObsidianTokens.spacingMd + ObsidianTokens.spacingXs),
            ),
            SizedBox(width: ObsidianTokens.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: ObsidianTypography.display(size: 18, weight: FontWeight.w800)),
                  Text(descriptor, style: ObsidianTypography.body(size: 13, color: ObsidianTokens.textMuted)),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: ObsidianTokens.springMs),
              child: selected
                  ? const Icon(Icons.check_circle_rounded, key: ValueKey('on'), color: ObsidianTokens.heroAccent)
                  : SizedBox(width: ObsidianTokens.spacingMd, key: const ValueKey('off')),
            ),
          ],
        ),
      ),
    );

    final wrapped = semanticsId == null ? card : Semantics(identifier: semanticsId!, button: true, child: card);
    return wrapped
        .animate(delay: Duration(milliseconds: animIndex * ObsidianTokens.staggerMs))
        .fadeIn(duration: const Duration(milliseconds: ObsidianTokens.staggerMs))
        .moveY(begin: 20, end: 0);
  }
}

class TdeeHeroDisplay extends StatefulWidget {
  final int value;
  final String unit;
  final String? subtitle;
  final String? semanticsId;

  const TdeeHeroDisplay({
    super.key,
    required this.value,
    this.unit = 'kcal / day',
    this.subtitle,
    this.semanticsId,
  });

  @override
  State<TdeeHeroDisplay> createState() => _TdeeHeroDisplayState();
}

class _TdeeHeroDisplayState extends State<TdeeHeroDisplay> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<int> _count;
  int _last = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _count = IntTween(begin: 0, end: widget.value).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _last = widget.value;
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(TdeeHeroDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _last) {
      _count = IntTween(begin: _last, end: widget.value).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
      _last = widget.value;
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = AnimatedBuilder(
      animation: _count,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${_count.value}', style: ObsidianTypography.monoHero()),
                SizedBox(width: ObsidianTokens.spacingSm),
                Padding(
                  padding: EdgeInsets.only(bottom: ObsidianTokens.spacingSm),
                  child: Text(widget.unit, style: ObsidianTypography.label(size: 12)),
                ),
              ],
            ),
            if (widget.subtitle != null) ...[
              SizedBox(height: ObsidianTokens.spacingXs),
              Text(
                widget.subtitle!,
                textAlign: TextAlign.center,
                style: ObsidianTypography.body(size: 12, color: ObsidianTokens.textMuted),
              ),
            ],
          ],
        );
      },
    );
    return widget.semanticsId == null ? child : Semantics(identifier: widget.semanticsId, child: child);
  }
}
