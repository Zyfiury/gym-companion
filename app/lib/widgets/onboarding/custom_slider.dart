import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import 'obsidian_shell.dart';

class ObsidianSlider extends StatefulWidget {
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final String Function(double value) labelFor;
  final ValueChanged<double> onChanged;
  final String label;

  const ObsidianSlider({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.labelFor,
    required this.onChanged,
    required this.label,
    this.divisions,
  });

  @override
  State<ObsidianSlider> createState() => _ObsidianSliderState();
}

class _ObsidianSliderState extends State<ObsidianSlider> {
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final pct = (widget.value - widget.min) / (widget.max - widget.min);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(widget.label, style: ObsidianTypography.label()),
            const Spacer(),
            Text(
              widget.labelFor(widget.value),
              style: ObsidianTypography.mono(size: 14, color: ObsidianTokens.heroAccent),
            ),
          ],
        ),
        SizedBox(height: ObsidianTokens.spacingSm),
        ObsidianGlass(
          padding: EdgeInsets.fromLTRB(
            ObsidianTokens.spacingMd,
            ObsidianTokens.spacingLg,
            ObsidianTokens.spacingMd,
            ObsidianTokens.spacingMd,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (_dragging)
                Positioned(
                  top: -ObsidianTokens.spacingXl,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: ObsidianTokens.spacingSm,
                        vertical: ObsidianTokens.spacingXs,
                      ),
                      decoration: BoxDecoration(
                        color: ObsidianTokens.heroAccent,
                        borderRadius: BorderRadius.circular(ObsidianTokens.radiusSm),
                      ),
                      child: Text(
                        widget.labelFor(widget.value),
                        style: ObsidianTypography.mono(size: 12, color: ObsidianTokens.textOnAccent),
                      ),
                    ),
                  ),
                ),
              LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      Container(
                        height: ObsidianTokens.spacingXs,
                        decoration: BoxDecoration(
                          color: ObsidianTokens.track,
                          borderRadius: BorderRadius.circular(ObsidianTokens.radiusPill),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: pct.clamp(0.0, 1.0),
                        child: Container(
                          height: ObsidianTokens.spacingXs,
                          decoration: BoxDecoration(
                            color: ObsidianTokens.heroAccent,
                            borderRadius: BorderRadius.circular(ObsidianTokens.radiusPill),
                            boxShadow: [
                              BoxShadow(
                                color: ObsidianTokens.heroAccent.withValues(alpha: 0.5),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 0,
                          activeTrackColor: Colors.transparent,
                          inactiveTrackColor: Colors.transparent,
                          thumbShape: _GlowThumbShape(dragging: _dragging),
                          overlayShape: SliderComponentShape.noOverlay,
                        ),
                        child: Slider(
                          value: widget.value,
                          min: widget.min,
                          max: widget.max,
                          divisions: widget.divisions,
                          onChangeStart: (_) {
                            HapticFeedback.selectionClick();
                            setState(() => _dragging = true);
                          },
                          onChangeEnd: (_) => setState(() => _dragging = false),
                          onChanged: widget.onChanged,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GlowThumbShape extends SliderComponentShape {
  final bool dragging;

  const _GlowThumbShape({required this.dragging});

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    final s = dragging ? ObsidianTokens.sliderThumbActive : ObsidianTokens.sliderThumb;
    return Size(s, s);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final r = dragging ? ObsidianTokens.sliderThumbActive / 2 : ObsidianTokens.sliderThumb / 2;
    final canvas = context.canvas;
    canvas.drawCircle(
      center + const Offset(0, 1),
      r,
      Paint()
        ..color = ObsidianTokens.textPrimary.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(center, r, Paint()..color = ObsidianTokens.textPrimary);
    canvas.drawCircle(
      center,
      r - 2,
      Paint()
        ..color = ObsidianTokens.heroAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }
}

class ObsidianHeroStat extends StatelessWidget {
  final String value;
  final String unit;
  final String? semanticsId;

  const ObsidianHeroStat({super.key, required this.value, required this.unit, this.semanticsId});

  @override
  Widget build(BuildContext context) {
    final child = Column(
      children: [
        Text(value, style: ObsidianTypography.mono(size: ObsidianTokens.heroStatSize, weight: FontWeight.w500)),
        SizedBox(height: ObsidianTokens.spacingXs),
        Text(unit, style: ObsidianTypography.label(size: 12)),
      ],
    );
    return semanticsId == null ? child : Semantics(identifier: semanticsId, child: child);
  }
}
