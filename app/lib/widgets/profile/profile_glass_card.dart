import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../onboarding/obsidian_shell.dart';
import '../premium_ui.dart';

/// Theme-aware elevated surface: glass blur in dark, shadowed card in light.
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
    if (context.isDarkTheme) {
      return ObsidianGlass(padding: padding, radius: AppRadius.card, child: child);
    }
    return AppCard(padding: padding, bordered: bordered, child: child);
  }
}
