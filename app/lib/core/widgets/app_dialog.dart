import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Themed alert dialog matching app light/dark palette.
Future<bool?> showAppConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool destructive = false,
}) {
  final t = context.appTheme;
  final c = context.appColors;

  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: t.card,
      surfaceTintColor: Colors.transparent,
      title: Text(title, style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w600)),
      content: Text(message, style: TextStyle(color: t.textSecondary, height: 1.45)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(cancelLabel, style: TextStyle(color: t.textMuted)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(
            confirmLabel,
            style: TextStyle(
              color: destructive ? c.error : c.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}
