import 'package:flutter/material.dart';
import '../screens/paywall_screen.dart';
import '../services/subscription_service.dart';

/// Central Pro feature gate — shows paywall when needed.
class ProGate {
  static Future<bool> check(BuildContext context, {String? feature, String? triggerSource}) async {
    if (await SubscriptionService.isPro()) return true;
    if (!context.mounted) return false;
    final upgraded = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => PaywallScreen(highlightFeature: feature, triggerSource: triggerSource)),
    );
    return upgraded == true || await SubscriptionService.isPro();
  }
}
