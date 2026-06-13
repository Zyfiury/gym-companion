import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';

class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String heading;
  final String body;
  final String? ctaLabel;
  final VoidCallback? onCta;
  /// Less padding when nested inside an [AppCard].
  final bool compact;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.heading,
    required this.body,
    this.ctaLabel,
    this.onCta,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final vertical = compact ? 20.0 : 48.0;
    final iconSize = compact ? 36.0 : 48.0;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: vertical),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: iconSize, color: c.textMuted),
          SizedBox(height: compact ? 12 : 16),
          Text(
            heading,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: compact ? 15 : 16,
              fontWeight: FontWeight.w500,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: compact ? 280 : 260),
            child: Text(
              body,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w300,
                height: 1.5,
                color: c.textMuted,
              ),
            ),
          ),
          if (ctaLabel != null && onCta != null) ...[
            SizedBox(height: compact ? 14 : 20),
            OutlinedButton(
              onPressed: onCta,
              style: OutlinedButton.styleFrom(
                foregroundColor: c.primary,
                side: BorderSide(color: c.primary),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(ctaLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
