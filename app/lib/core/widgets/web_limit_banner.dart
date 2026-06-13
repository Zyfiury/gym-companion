import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Shown on web builds where camera, barcode, and Health are unavailable.
class WebLimitBanner extends StatelessWidget {
  const WebLimitBanner({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return const SizedBox.shrink();

    final c = context.appColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: c.duskDim,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.dusk.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Icon(Icons.phone_android_outlined, size: 18, color: c.dusk),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Web preview — photo log, barcode scan, and step sync need the Android app.',
                style: TextStyle(fontSize: 12, color: c.textSecondary, height: 1.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
