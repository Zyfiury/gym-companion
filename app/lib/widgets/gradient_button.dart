import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool expanded;

  const GradientButton({super.key, required this.label, this.onPressed, this.expanded = false});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final child = ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: c.primary,
        foregroundColor: c.onPrimary,
        minimumSize: const Size(0, 48),
        elevation: 0,
        shadowColor: c.primary.withValues(alpha: 0.35),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
      ),
      child: Text(label),
    );
    return expanded ? SizedBox(width: double.infinity, child: child) : child;
  }
}
