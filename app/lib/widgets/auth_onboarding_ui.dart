import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'premium_ui.dart';
import 'staggered_entry.dart';

/// Brand mark — fitness-focused, not generic AI sparkle.
class BrandMark extends StatelessWidget {
  final double size;

  const BrandMark({super.key, this.size = 72});

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final isDark = context.isDarkTheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceElevated : Colors.white,
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: isDark ? t.borderSubtle : Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: isDark ? 0.2 : 0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
          if (!isDark) BoxShadow(color: t.shadow, blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.fitness_center_rounded, size: size * 0.42, color: AppColors.accent),
          Positioned(
            top: size * 0.14,
            right: size * 0.14,
            child: Container(
              width: size * 0.14,
              height: size * 0.14,
              decoration: const BoxDecoration(color: AppColors.orange, shape: BoxShape.circle),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthPillTabs extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  final List<String> labels;

  const AuthPillTabs({
    super.key,
    required this.index,
    required this.onChanged,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: t.inputFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.borderSubtle.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final active = index == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: active ? (context.isDarkTheme ? AppColors.surfaceCard : Colors.white) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: active && !context.isDarkTheme
                      ? [BoxShadow(color: t.shadow, blurRadius: 8, offset: const Offset(0, 2))]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active ? t.textPrimary : t.textMuted,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class AuthField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData icon;
  final bool obscure;
  final bool showPasswordToggle;
  final TextInputType keyboard;
  final List<String>? autofillHints;
  final String? semanticsId;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;

  const AuthField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    required this.icon,
    this.obscure = false,
    this.showPasswordToggle = false,
    this.keyboard = TextInputType.text,
    this.autofillHints,
    this.semanticsId,
    this.errorText,
    this.onChanged,
    this.textInputAction,
  });

  @override
  State<AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<AuthField> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;
    final hideText = widget.obscure && !_visible;

    final field = TextField(
      controller: widget.controller,
      obscureText: hideText,
      keyboardType: widget.keyboard,
      autofillHints: widget.autofillHints,
      textInputAction: widget.textInputAction,
      onChanged: widget.onChanged,
      style: TextStyle(color: t.textPrimary, fontSize: 15, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        prefixIcon: Icon(widget.icon, size: 20, color: hasError ? Colors.redAccent : t.textMuted),
        suffixIcon: widget.showPasswordToggle
            ? IconButton(
                icon: Icon(
                  _visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 20,
                  color: t.textMuted,
                ),
                onPressed: () => setState(() => _visible = !_visible),
              )
            : null,
        filled: true,
        fillColor: t.inputFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: hasError ? Colors.redAccent.withValues(alpha: 0.6) : t.borderSubtle.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: hasError ? Colors.redAccent : AppColors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.redAccent.withValues(alpha: 0.8)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        errorText: hasError ? widget.errorText : null,
        errorStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        labelStyle: TextStyle(color: t.textMuted, fontSize: 13),
        floatingLabelStyle: TextStyle(
          color: hasError ? Colors.redAccent : AppColors.accent,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
    if (widget.semanticsId == null) return field;
    return Semantics(identifier: widget.semanticsId, child: field);
  }
}

class OnboardingProgressHeader extends StatelessWidget {
  final int step;
  final int total;
  final String title;
  final String? semanticsTitleId;

  const OnboardingProgressHeader({
    super.key,
    required this.step,
    required this.total,
    required this.title,
    this.semanticsTitleId,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final progress = (step + 1) / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              (step + 1).toString().padLeft(2, '0'),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.accent,
                letterSpacing: 1.2,
              ),
            ),
            Text(' / ${total.toString().padLeft(2, '0')}', style: TextStyle(fontSize: 13, color: t.textMuted)),
            const Spacer(),
            Text('${(progress * 100).round()}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: t.textMuted)),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            builder: (context, v, child) => LinearProgressIndicator(
              value: v,
              backgroundColor: t.progressTrack,
              color: AppColors.accent,
              minHeight: 5,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Semantics(
          identifier: semanticsTitleId,
          child: Text(
            title,
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: t.textPrimary, letterSpacing: -0.8, height: 1.1),
          ),
        ),
      ],
    );
  }
}

class OnboardingStepIntro extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String headline;
  final String subtitle;

  const OnboardingStepIntro({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.headline,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: context.isDarkTheme ? 0.15 : 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(height: 16),
        Text(headline, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: t.textPrimary, letterSpacing: -0.3)),
        const SizedBox(height: 6),
        Text(subtitle, style: TextStyle(fontSize: 14, height: 1.45, color: t.textSecondary)),
      ],
    );
  }
}

class OnboardingWheelPicker extends StatelessWidget {
  final int itemCount;
  final int initialIndex;
  final ValueChanged<int> onChanged;
  final String Function(int index) labelFor;
  final String? semanticsId;

  const OnboardingWheelPicker({
    super.key,
    required this.itemCount,
    required this.initialIndex,
    required this.onChanged,
    required this.labelFor,
    this.semanticsId,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final picker = CupertinoPicker(
      scrollController: FixedExtentScrollController(initialItem: initialIndex),
      itemExtent: 48,
      magnification: 1.08,
      squeeze: 1.05,
      useMagnifier: true,
      onSelectedItemChanged: onChanged,
      children: List.generate(
        itemCount,
        (i) => Center(
          child: Text(
            labelFor(i),
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: t.textPrimary),
          ),
        ),
      ),
    );
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        height: 220,
        child: semanticsId == null ? picker : Semantics(identifier: semanticsId, child: picker),
      ),
    );
  }
}

class OnboardingBigValue extends StatelessWidget {
  final String value;
  final String unit;
  final String? semanticsId;

  const OnboardingBigValue({super.key, required this.value, required this.unit, this.semanticsId});

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final child = Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 64,
            fontWeight: FontWeight.w800,
            color: t.textPrimary,
            letterSpacing: -2.5,
            height: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(unit, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: t.textMuted, letterSpacing: 0.3)),
      ],
    );
    return semanticsId == null ? child : Semantics(identifier: semanticsId, child: child);
  }
}

class MetricAdjuster extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final double sliderValue;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onSliderChanged;

  const MetricAdjuster({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.onDecrease,
    required this.onIncrease,
    required this.sliderValue,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onSliderChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: t.textMuted, letterSpacing: 0.4)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _RoundIconBtn(icon: Icons.remove, onTap: onDecrease),
              Column(
                children: [
                  Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: t.textPrimary, letterSpacing: -0.5)),
                  Text(unit, style: TextStyle(fontSize: 11, color: t.textMuted)),
                ],
              ),
              _RoundIconBtn(icon: Icons.add, onTap: onIncrease),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            ),
            child: Slider(
              value: sliderValue,
              min: min,
              max: max,
              divisions: divisions,
              activeColor: AppColors.accent,
              inactiveColor: t.progressTrack,
              onChanged: onSliderChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    return Material(
      color: t.inputFill,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 18, color: t.textPrimary),
        ),
      ),
    );
  }
}

class OnboardingOptionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;
  final String? semanticsId;

  const OnboardingOptionCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.accent,
    required this.selected,
    required this.onTap,
    this.semanticsId,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final card = PressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: context.isDarkTheme ? 0.14 : 0.08) : t.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? accent : t.borderSubtle, width: selected ? 1.5 : 1),
          boxShadow: selected && !context.isDarkTheme
              ? [BoxShadow(color: accent.withValues(alpha: 0.12), blurRadius: 16, offset: const Offset(0, 4))]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: context.isDarkTheme ? 0.2 : 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: accent, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: t.textPrimary)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(subtitle!, style: TextStyle(fontSize: 13, color: t.textSecondary)),
                  ],
                ],
              ),
            ),
            if (selected) Icon(Icons.check_circle_rounded, color: accent, size: 22),
          ],
        ),
      ),
    );
    return semanticsId == null ? card : Semantics(identifier: semanticsId, button: true, child: card);
  }
}

class OnboardingChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? semanticsId;

  const OnboardingChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.semanticsId,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final chip = GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent.withValues(alpha: context.isDarkTheme ? 0.22 : 0.12) : t.inputFill,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: selected ? AppColors.accent : t.borderSubtle),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.accent : t.textSecondary,
          ),
        ),
      ),
    );
    return semanticsId == null ? chip : Semantics(identifier: semanticsId, button: true, child: chip);
  }
}

class WelcomeFeatureRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const WelcomeFeatureRow({super.key, required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: context.isDarkTheme ? 0.18 : 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: t.textPrimary))),
        ],
      ),
    );
  }
}
