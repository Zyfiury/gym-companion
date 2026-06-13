import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../premium_ui.dart';

/// Theme-aware elevated surface for profile sections.
class ProfileGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool bordered;

  const ProfileGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.bordered = true,
  });

  @override
  Widget build(BuildContext context) {
    // ObsidianGlass uses the onboarding light palette (white fill) — never use it
    // in dark mode or text becomes unreadable on white cards.
    return AppCard(padding: padding, bordered: bordered, child: child);
  }
}
