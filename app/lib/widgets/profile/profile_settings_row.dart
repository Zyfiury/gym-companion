import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../staggered_entry.dart';

class ProfileSettingsRow extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final String? semanticsId;
  final bool showChevron;
  final Color? titleColor;

  const ProfileSettingsRow({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.iconColor,
    this.semanticsId,
    this.showChevron = true,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final color = iconColor ?? context.appColors.primary;

    final row = PressableScale(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: context.isDarkTheme ? 0.14 : 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: titleColor ?? t.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: TextStyle(fontSize: 12, color: t.textSecondary)),
                  ],
                ],
              ),
            ),
            if (showChevron) Icon(Icons.chevron_right_rounded, size: 22, color: t.textMuted),
          ],
        ),
      ),
    );

    if (semanticsId == null) return row;
    return Semantics(identifier: semanticsId, button: true, child: row);
  }
}
