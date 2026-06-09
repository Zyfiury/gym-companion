import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';

class DeliveryOptionTile extends StatelessWidget {
  final Map<String, dynamic> option;

  const DeliveryOptionTile({super.key, required this.option});

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final dish = option['dish'] as String? ?? '';
    final macros = option['macros'] as String? ?? '';
    final estimated = option['macrosEstimated'] == true;
    final source = option['nutritionSource'] as String?;
    final dist = option['distanceKm'];
    final distLabel = dist is num ? ' · ${dist.toStringAsFixed(1)} km' : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: t.elevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            option['restaurant'] as String? ?? 'Restaurant',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: t.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            estimated
                ? 'Suggested: $dish — $macros (est.)$distLabel'
                : source != null
                    ? '$dish — $macros ($source)$distLabel'
                    : '$dish — $macros$distLabel',
            style: TextStyle(fontSize: 12, color: t.textSecondary, height: 1.35),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (option['uberEatsUrl'] != null) _OrderChip(label: 'Uber Eats', url: option['uberEatsUrl'] as String),
              if (option['deliverooUrl'] != null) _OrderChip(label: 'Deliveroo', url: option['deliverooUrl'] as String),
              if (option['justEatUrl'] != null) _OrderChip(label: 'Just Eat', url: option['justEatUrl'] as String),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrderChip extends StatelessWidget {
  final String label;
  final String url;

  const _OrderChip({required this.label, required this.url});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      visualDensity: VisualDensity.compact,
      backgroundColor: AppColors.accent.withValues(alpha: 0.12),
      labelStyle: const TextStyle(color: AppColors.accent),
      onPressed: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
    );
  }
}
