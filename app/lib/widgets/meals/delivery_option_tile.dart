import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../utils/delivery_actions.dart';

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
    final isEatOut = option['isEatOut'] == true;
    final actionUrl = primaryActionUrl(option);

    return Material(
      color: t.elevated,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: actionUrl != null ? () => launchExternalUrl(context, actionUrl) : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: t.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      option['restaurant'] as String? ?? 'Restaurant',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: t.textPrimary),
                    ),
                  ),
                  if (actionUrl != null)
                    Icon(
                      isEatOut ? Icons.map_outlined : Icons.open_in_new,
                      size: 16,
                      color: t.textMuted,
                    ),
                ],
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
                  if (isEatOut && option['mapsUrl'] != null)
                    _ActionChip(
                      label: 'Open in Maps',
                      icon: Icons.map_outlined,
                      onTap: () => launchExternalUrl(context, option['mapsUrl'] as String),
                    )
                  else ...[
                    if (option['uberEatsUrl'] != null)
                      _ActionChip(
                        label: 'Uber Eats',
                        onTap: () => launchExternalUrl(context, option['uberEatsUrl'] as String),
                      ),
                    if (option['deliverooUrl'] != null)
                      _ActionChip(
                        label: 'Deliveroo',
                        onTap: () => launchExternalUrl(context, option['deliverooUrl'] as String),
                      ),
                    if (option['justEatUrl'] != null)
                      _ActionChip(
                        label: 'Just Eat',
                        onTap: () => launchExternalUrl(context, option['justEatUrl'] as String),
                      ),
                  ],
                  _ActionChip(
                    label: 'Log dish',
                    icon: Icons.add_circle_outline,
                    onTap: () => logDeliveryOption(context, option),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;

  const _ActionChip({required this.label, required this.onTap, this.icon});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: icon != null ? Icon(icon, size: 14, color: AppColors.accent) : null,
      label: Text(label, style: const TextStyle(fontSize: 11)),
      visualDensity: VisualDensity.compact,
      backgroundColor: AppColors.accent.withValues(alpha: 0.12),
      labelStyle: const TextStyle(color: AppColors.accent),
      onPressed: onTap,
    );
  }
}
