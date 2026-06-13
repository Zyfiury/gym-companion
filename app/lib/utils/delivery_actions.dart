import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/app_state.dart';
import '../core/widgets/app_toast.dart';
import '../theme/app_theme.dart';
import 'sheet_padding.dart';

Future<bool> launchExternalUrl(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) {
    if (context.mounted) {
      AppToast.error(context, 'Invalid link');
    }
    return false;
  }

  try {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      AppToast.error(context, 'Could not open link - check your browser or delivery app');
    }
    return launched;
  } catch (_) {
    if (context.mounted) {
      AppToast.error(context, 'Could not open link');
    }
    return false;
  }
}

String? primaryActionUrl(Map<String, dynamic> option) {
  final isEatOut = option['isEatOut'] == true;
  if (isEatOut) {
    return option['mapsUrl'] as String?;
  }
  return option['uberEatsUrl'] as String? ??
      option['deliverooUrl'] as String? ??
      option['justEatUrl'] as String?;
}

Future<void> logDeliveryOption(BuildContext context, Map<String, dynamic> option) async {
  final restaurant = option['restaurant'] as String? ?? 'Restaurant';
  final dish = option['dish'] as String? ?? 'Meal';
  final calories = _asInt(option['calories']);
  final protein = _asInt(option['protein']);
  final carbs = _asInt(option['carbs']);
  final fat = _asInt(option['fat']);
  final isEatOut = option['isEatOut'] == true;
  var fiber = _asInt(option['fiber']);
  var sugar = _asInt(option['sugar']);
  var sodiumMg = _asInt(option['sodiumMg'] ?? option['sodium_mg']);
  if (fiber == 0 && carbs > 0) fiber = (carbs * 0.12).round();
  if (sugar == 0 && carbs > 0) sugar = (carbs * 0.25).round();
  if (sodiumMg == 0) sodiumMg = isEatOut ? 800 : 600;
  final estimated = option['macrosEstimated'] == true;
  final name = '$restaurant - $dish';

  final t = context.appTheme;
  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: t.card,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => Padding(
      padding: sheetInsets(ctx, horizontal: 20, top: 20, extra: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Log $dish?', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: t.textPrimary)),
          const SizedBox(height: 4),
          Text(restaurant, style: TextStyle(fontSize: 13, color: t.textSecondary)),
          const SizedBox(height: 8),
          Text(
            '$calories kcal · P ${protein}g · C ${carbs}g · F ${fat}g${estimated ? ' (estimated)' : ''}',
            style: TextStyle(fontSize: 13, color: t.textSecondary),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: context.appColors.primary),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Log food'),
            ),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        ],
      ),
    ),
  );

  if (confirmed != true || !context.mounted) return;

  final state = context.read<AppState>();
  final chip = await state.logFood(
        name: name,
        calories: calories,
        protein: protein,
        carbs: carbs,
        fat: fat,
        fiber: fiber,
        sugar: sugar,
        sodiumMg: sodiumMg,
        source: isEatOut ? 'eat_out' : 'delivery',
      );

  if (chip != null && context.mounted) {
    AppToast.success(context, chip, actionLabel: 'Undo', onAction: () => state.undoLastFoodLog());
  }
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return 0;
}
