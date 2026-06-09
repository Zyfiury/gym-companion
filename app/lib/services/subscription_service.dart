import 'package:flutter/foundation.dart';

import 'package:purchases_flutter/purchases_flutter.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'backend_config.dart';



enum ProPlan { monthly, annual }



class SubscriptionService {

  static const _freeLimit = 10;

  static const _quotaKey = 'gym_free_chat_count';

  static const _quotaDateKey = 'gym_free_chat_date';



  static bool _initialized = false;

  static int _freeMessagesToday = 0;

  static String _lastMessageDate = '';



  static Future<void> init() async {

    await _loadQuota();

    if (!BackendConfig.hasRevenueCat || _initialized) return;

    try {

      await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.warn);

      await Purchases.configure(PurchasesConfiguration(BackendConfig.revenueCatKey!));

      _initialized = true;

    } catch (_) {}

  }



  static Future<void> _loadQuota() async {

    final prefs = await SharedPreferences.getInstance();

    _lastMessageDate = prefs.getString(_quotaDateKey) ?? '';

    _freeMessagesToday = prefs.getInt(_quotaKey) ?? 0;

    final today = DateTime.now().toIso8601String().substring(0, 10);

    if (_lastMessageDate != today) {

      _lastMessageDate = today;

      _freeMessagesToday = 0;

      await prefs.setString(_quotaDateKey, today);

      await prefs.setInt(_quotaKey, 0);

    }

  }



  static Future<void> _saveQuota() async {

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_quotaDateKey, _lastMessageDate);

    await prefs.setInt(_quotaKey, _freeMessagesToday);

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

    try {
      final info = await Purchases.getCustomerInfo();
      return info.entitlements.active.containsKey('pro');
    } catch (_) {
      return false;
    }
  }



  static Future<int> freeMessagesRemaining() async {

    if (await isPro()) return -1;

    final today = DateTime.now().toIso8601String().substring(0, 10);

    if (_lastMessageDate != today) return _freeLimit;

    return (_freeLimit - _freeMessagesToday).clamp(0, _freeLimit);

  }



  static Future<bool> purchasePro({ProPlan plan = ProPlan.monthly}) async {

    try {

      final offerings = await Purchases.getOfferings();

      final current = offerings.current;

      if (current == null) return false;

      final package = plan == ProPlan.annual ? current.annual : current.monthly;

      if (package == null) return false;

      await Purchases.purchasePackage(package);

      return true;

    } catch (_) {

      return false;

    }

  }



  static Future<bool> restorePurchases() async {

    try {

      final info = await Purchases.restorePurchases();

      return info.entitlements.active.containsKey('pro');

    } catch (_) {

      return false;

    }

  }



  static Future<bool> canSendChatMessage() async {

    if (await isPro()) return true;

    final today = DateTime.now().toIso8601String().substring(0, 10);

    if (_lastMessageDate != today) {

      _lastMessageDate = today;

      _freeMessagesToday = 0;

      await _saveQuota();

    }

    return _freeMessagesToday < _freeLimit;

  }



  static void recordChatMessage() {

    final today = DateTime.now().toIso8601String().substring(0, 10);

    if (_lastMessageDate != today) {

      _lastMessageDate = today;

      _freeMessagesToday = 0;

    }

    _freeMessagesToday++;

    _saveQuota();

  }

}


