import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';

class OnboardingChip extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? semanticsId;

  const OnboardingChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.semanticsId,
  });

  @override
  State<OnboardingChip> createState() => _OnboardingChipState();
}

class _OnboardingChipState extends State<OnboardingChip> with SingleTickerProviderStateMixin {
  late AnimationController _spring;

  @override
  void initState() {
    super.initState();
    _spring = AnimationController(vsync: this, duration: const Duration(milliseconds: ObsidianTokens.springMs));
  }

  @override
  void didUpdateWidget(OnboardingChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected && !oldWidget.selected) {
      _spring.forward(from: 0);
      HapticFeedback.lightImpact();
    }
  }

  @override
  void dispose() {
    _spring.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final obs = context.obsidian;
    final chip = GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _spring,
        builder: (context, child) {
          final scale = widget.selected ? 1.0 + (_spring.value * 0.05) * (1 - _spring.value) : 1.0;
          return Transform.scale(scale: scale, child: child);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: ObsidianTokens.springMs),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: ObsidianTokens.spacingMd,
            vertical: ObsidianTokens.spacingSm,
          ),
          decoration: BoxDecoration(
            color: widget.selected ? obs.heroAccent : obs.surfaceMuted,
            borderRadius: BorderRadius.circular(ObsidianTokens.radiusPill),
            border: Border.all(
              color: widget.selected ? obs.heroAccent : obs.heroAccent.withValues(alpha: 0.25),
            ),
          ),
          child: Text(
            widget.label,
            style: ObsidianTypography.body(
              size: 13,
              weight: FontWeight.w600,
              color: widget.selected ? obs.textOnAccent : obs.textSecondary,
            ),
          ),
        ),
      ),
    );

    final wrapped = widget.semanticsId == null ? chip : Semantics(identifier: widget.semanticsId, button: true, child: chip);
    return wrapped
        .animate()
        .fadeIn(duration: const Duration(milliseconds: ObsidianTokens.staggerMs))
        .moveY(begin: 20, end: 0, duration: const Duration(milliseconds: ObsidianTokens.staggerMs), curve: Curves.easeOutCubic);
  }
}

/// Chips with selected items floated to top.
class OnboardingChipGrid extends StatelessWidget {
  final List<OnboardingChipItem> items;
  final void Function(String id) onToggle;

  const OnboardingChipGrid({super.key, required this.items, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final sorted = [...items]..sort((a, b) {
        if (a.selected == b.selected) return 0;
        return a.selected ? -1 : 1;
      });

    return Wrap(
      spacing: ObsidianTokens.spacingSm,
      runSpacing: ObsidianTokens.spacingSm,
      children: sorted.asMap().entries.map((e) {
        final item = e.value;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: ObsidianTokens.springMs),
          switchInCurve: Curves.easeOutCubic,
          child: OnboardingChip(
            key: ValueKey('${item.id}-${item.selected}'),
            label: item.label,
            selected: item.selected,
            semanticsId: item.semanticsId,
            onTap: () => onToggle(item.id),
          ),
        );
      }).toList(),
    );
  }
}

class OnboardingChipItem {
  final String id;
  final String label;
  final bool selected;
  final String? semanticsId;

  const OnboardingChipItem({
    required this.id,
    required this.label,
    required this.selected,
    this.semanticsId,
  });
}

class OnboardingBottomLineInput extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final VoidCallback onSubmit;

  const OnboardingBottomLineInput({
    super.key,
    required this.controller,
    required this.hint,
    required this.onSubmit,
  });

  @override
  State<OnboardingBottomLineInput> createState() => _OnboardingBottomLineInputState();
}

class _OnboardingBottomLineInputState extends State<OnboardingBottomLineInput> with SingleTickerProviderStateMixin {
  late AnimationController _line;
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _line = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _focus.addListener(() {
      if (_focus.hasFocus) {
        _line.forward();
      } else {
        _line.reverse();
      }
    });
  }

  @override
  void dispose() {
    _line.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: _focus,
                style: ObsidianTypography.body(color: ObsidianTokens.textPrimary),
                decoration: InputDecoration(
                  hintText: widget.hint,
                  hintStyle: ObsidianTypography.body(color: ObsidianTokens.textMuted),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                onSubmitted: (_) => widget.onSubmit(),
              ),
            ),
            IconButton(
              onPressed: widget.onSubmit,
              icon: const Icon(Icons.add_rounded, color: ObsidianTokens.heroAccent),
            ),
          ],
        ),
        SizedBox(height: ObsidianTokens.spacingXs),
        AnimatedBuilder(
          animation: _line,
          builder: (context, _) {
            return Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: _line.value,
                child: Container(
                  height: 1,
                  color: ObsidianTokens.heroAccent,
                ),
              ),
            );
          },
        ),
        Container(height: 1, color: ObsidianTokens.track),
      ],
    );
  }
}
