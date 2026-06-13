import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Verified (database) vs estimated nutrition label.
class NutritionSourceBadge extends StatelessWidget {
  final bool verified;
  final bool compact;

  const NutritionSourceBadge({super.key, required this.verified, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final (bg, fg, label) = verified
        ? (c.mintDim, c.mint, compact ? 'Verified' : 'Verified nutrition')
        : (c.sandDim, c.sand, compact ? 'Est.' : 'Estimated');

    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 8, vertical: compact ? 2 : 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(verified ? Icons.verified_outlined : Icons.auto_awesome_outlined, size: compact ? 11 : 12, color: fg),
          if (!compact) const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: compact ? 10 : 11, fontWeight: FontWeight.w600, color: fg)),
        ],
      ),
    );
  }
}
