import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
              child: Text('Back', style: ObsidianTypography.body(size: 14, color: ObsidianTokens.textMuted, weight: FontWeight.w600)),
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
                            ? ObsidianTokens.heroAccent.withValues(alpha: 0.6)
                            : ObsidianTokens.heroAccent,
                        borderRadius: BorderRadius.circular(ObsidianTokens.radiusMd),
                        boxShadow: ObsidianTokens.glassShadow(tint: ObsidianTokens.heroAccent),
                      ),
                      child: widget.loading
                          ? SizedBox(
                              width: ObsidianTokens.spacingMd + ObsidianTokens.spacingXs,
                              height: ObsidianTokens.spacingMd + ObsidianTokens.spacingXs,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: ObsidianTokens.textOnAccent,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(widget.primaryLabel, style: ObsidianTypography.button()),
                                SizedBox(width: ObsidianTokens.spacingSm),
                                const Icon(Icons.arrow_forward_rounded, color: ObsidianTokens.textOnAccent, size: ObsidianTokens.spacingMd),
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
