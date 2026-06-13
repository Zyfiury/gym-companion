import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ProBadge extends StatelessWidget {
  final bool compact;

  const ProBadge({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 3 : 4),
      decoration: BoxDecoration(
        color: c.primaryTintBg,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: c.primaryTintBorder),
      ),
      child: Text(
        'PRO',
        style: TextStyle(
          fontSize: compact ? 9 : 11,
          fontWeight: FontWeight.w500,
          color: c.primaryDim,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
