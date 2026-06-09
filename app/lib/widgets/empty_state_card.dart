import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class EmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String headline;
  final String subtext;
  final String? buttonLabel;
  final VoidCallback? onAction;

  const EmptyStateCard({
    super.key,
    required this.icon,
    required this.headline,
    required this.subtext,
    this.buttonLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent.withValues(alpha: 0.1),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: AppColors.accent, size: 32),
          ),
          const SizedBox(height: 16),
          Text(headline, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: t.textPrimary), textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(subtext, style: TextStyle(fontSize: 13, color: t.textSecondary), textAlign: TextAlign.center),
          if (buttonLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onAction,
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.accent, side: BorderSide(color: AppColors.accent.withValues(alpha: 0.4))),
              child: Text(buttonLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
