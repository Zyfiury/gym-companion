import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import '../utils/sheet_padding.dart';

Future<void> showLevelUpSheet(BuildContext context, int level) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _LevelUpSheet(level: level),
  );
}

class _LevelUpSheet extends StatelessWidget {
  final int level;
  const _LevelUpSheet({required this.level});

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final c = context.appColors;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: sheetInsets(context, horizontal: 24, top: 28, extra: 28),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: c.primary.withValues(alpha: 0.35)),
        boxShadow: [BoxShadow(color: c.primary.withValues(alpha: 0.15), blurRadius: 32, spreadRadius: 4)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('LEVEL UP', style: TextStyle(fontSize: 11, letterSpacing: 1.2, color: c.primary, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Text('Level $level', style: GoogleFonts.gloock(fontSize: 42, color: t.textPrimary)),
          const SizedBox(height: 8),
          Text('You\'re building real momentum - keep showing up.', style: TextStyle(fontSize: 14, color: t.textSecondary)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: c.primary, padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: () => Navigator.pop(context),
              child: const Text('Let\'s go'),
            ),
          ),
        ],
      ),
    );
  }
}
