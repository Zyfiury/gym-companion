import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/obsidian_palette.dart';
import '../../theme/app_theme.dart';
import 'obsidian_shell.dart';

class OnboardingNavBar extends StatefulWidget {
  final bool showBack;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback? onBack;
  final String? primarySemanticsId;
  final bool loading;

  const OnboardingNavBar({
    super.key,
    required this.showBack,
    required this.primaryLabel,
    required this.onPrimary,
    this.onBack,
    this.primarySemanticsId,
    this.loading = false,
  });

  @override
  State<OnboardingNavBar> createState() => _OnboardingNavBarState();
}

class _OnboardingNavBarState extends State<OnboardingNavBar> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final o = context.obsidian;
    return ObsidianGlass(
      radius: ObsidianTokens.radiusLg,
      padding: EdgeInsets.fromLTRB(
        ObsidianTokens.spacingMd,
        ObsidianTokens.spacingSm,
        ObsidianTokens.spacingMd,
        ObsidianTokens.spacingMd,
      ),
      child: Row(
        children: [
          if (widget.showBack)
            TextButton(
              onPressed: widget.loading ? null : widget.onBack,
              child: Text(
                'Back',
                style: ObsidianTypography.body(size: 14, color: o.textMuted, weight: FontWeight.w600),
              ),
            ),
          Expanded(
            child: Semantics(
              identifier: widget.primarySemanticsId,
              button: true,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(ObsidianTokens.radiusMd),
                  onTap: widget.loading
                      ? null
                      : () {
                          HapticFeedback.lightImpact();
                          widget.onPrimary();
                        },
                  onTapDown: widget.loading ? null : (_) => setState(() => _pressed = true),
                  onTapUp: widget.loading ? null : (_) => setState(() => _pressed = false),
                  onTapCancel: widget.loading ? null : () => setState(() => _pressed = false),
                  child: AnimatedScale(
                    scale: _pressed && !widget.loading ? 0.97 : 1.0,
                    duration: const Duration(milliseconds: ObsidianTokens.springMs),
                    curve: Curves.easeOutCubic,
                    child: Container(
                      height: ObsidianTokens.navButtonHeight,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: widget.loading
                            ? o.heroAccent.withValues(alpha: 0.6)
                            : o.heroAccent,
                        borderRadius: BorderRadius.circular(ObsidianTokens.radiusMd),
                        boxShadow: o.glassShadow(tint: o.heroAccent),
                      ),
                      child: widget.loading
                          ? SizedBox(
                              width: ObsidianTokens.spacingMd + ObsidianTokens.spacingXs,
                              height: ObsidianTokens.spacingMd + ObsidianTokens.spacingXs,
                              child: Center(
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CustomPaint(
                                    painter: _ButtonSpinnerPainter(color: o.textOnAccent),
                                  ),
                                ),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(widget.primaryLabel, style: ObsidianTypography.button(color: o.textOnAccent)),
                                SizedBox(width: ObsidianTokens.spacingSm),
                                Icon(Icons.arrow_forward_rounded, color: o.textOnAccent, size: ObsidianTokens.spacingMd),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ButtonSpinnerPainter extends CustomPainter {
  final Color color;
  _ButtonSpinnerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromLTWH(0, 0, size.width, size.height),
      0,
      4.5,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
