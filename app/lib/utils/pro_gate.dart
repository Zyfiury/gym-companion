import 'package:flutter/material.dart';
import '../screens/paywall_screen.dart';
import '../services/subscription_service.dart';
import '../widgets/page_transitions.dart';

/// Central Pro feature gate - shows paywall when needed.
class ProGate {
  static Future<bool> check(BuildContext context, {String? feature, String? triggerSource}) async {
    if (await SubscriptionService.isPro()) return true;
    if (!context.mounted) return false;
    final upgraded = await pushModal<bool>(
      context,
      PaywallScreen(highlightFeature: feature, triggerSource: triggerSource),
    );
    return upgraded == true || await SubscriptionService.isPro();
  }
}
