import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'backend_config.dart';

enum ProPlan { monthly, annual }

class PaywallOfferings {
  final String? monthlyPrice;
  final String? annualPrice;
  final String? trialLabel;

  const PaywallOfferings({this.monthlyPrice, this.annualPrice, this.trialLabel});
}

/// RevenueCat Pro subscription - chat message quota lives in [UserData.gamification].
class SubscriptionService {
  static bool _initialized = false;

  // Pro status cache - getCustomerInfo hits the billing API, which is slow
  // and logs errors on devices without Play Store.
  static bool? _cachedPro;
  static DateTime? _cachedProAt;
  static const _proCacheTtl = Duration(minutes: 5);

  static Future<void> init() async {
    if (!BackendConfig.hasRevenueCat || _initialized) return;
    try {
      await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.warn);
      await Purchases.configure(PurchasesConfiguration(BackendConfig.revenueCatKey!));
      _initialized = true;
    } catch (_) {}
  }

  static Future<void> linkUser(String userId) async {
    if (!BackendConfig.hasRevenueCat || !_initialized) return;
    try {
      await Purchases.logIn(userId);
    } catch (_) {}
  }

  static Future<bool> isPro() async {
    if (BackendConfig.devProOverride) return true;
    if (!BackendConfig.hasRevenueCat || !_initialized) return false;

    final now = DateTime.now();
    if (_cachedPro != null && _cachedProAt != null && now.difference(_cachedProAt!) < _proCacheTtl) {
      return _cachedPro!;
    }

    try {
      final info = await Purchases.getCustomerInfo();
      _cachedPro = info.entitlements.active.containsKey('pro');
    } catch (_) {
      _cachedPro ??= false;
    }
    _cachedProAt = now;
    return _cachedPro!;
  }

  static Future<bool> purchasePro({ProPlan plan = ProPlan.monthly}) async {
    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;
      if (current == null) return false;
      final package = plan == ProPlan.annual ? current.annual : current.monthly;
      if (package == null) return false;
      await Purchases.purchasePackage(package);
      _cachedPro = true;
      _cachedProAt = DateTime.now();
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<PaywallOfferings> loadOfferings() async {
    if (!BackendConfig.hasRevenueCat || !_initialized) {
      return const PaywallOfferings();
    }
    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;
      if (current == null) return const PaywallOfferings();
      final monthly = current.monthly?.storeProduct.priceString;
      final annual = current.annual?.storeProduct.priceString;
      String? trial;
      final intro = current.monthly?.storeProduct.introductoryPrice;
      if (intro != null) trial = '${intro.periodNumberOfUnits}-day free trial';
      return PaywallOfferings(monthlyPrice: monthly, annualPrice: annual, trialLabel: trial);
    } catch (_) {
      return const PaywallOfferings();
    }
  }

  static Future<bool> restorePurchases() async {
    try {
      final info = await Purchases.restorePurchases();
      _cachedPro = info.entitlements.active.containsKey('pro');
      _cachedProAt = DateTime.now();
      return _cachedPro!;
    } catch (_) {
      return false;
    }
  }
}
