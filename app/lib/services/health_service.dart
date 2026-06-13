import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

/// Result of a Health Connect / Apple Health connection attempt.
class HealthConnectResult {
  final bool success;
  final String message;
  final bool needsInstall;
  final int steps;

  const HealthConnectResult({
    required this.success,
    required this.message,
    this.needsInstall = false,
    this.steps = 0,
  });

  factory HealthConnectResult.ok({int steps = 0}) {
    final msg = steps > 0
        ? '✓ Connected - $steps steps today'
        : '✓ Connected - steps will sync as you move';
    return HealthConnectResult(success: true, message: msg, steps: steps);
  }

  factory HealthConnectResult.fail(String message, {bool needsInstall = false}) {
    return HealthConnectResult(
      success: false,
      message: message,
      needsInstall: needsInstall,
    );
  }
}

class HealthService {
  static final _health = Health();
  static bool _configured = false;

  /// Steps are required for the home dashboard; request these first on connect.
  static const _stepsTypes = [HealthDataType.STEPS];

  static const _extraTypes = [
    HealthDataType.WEIGHT,
    HealthDataType.ACTIVE_ENERGY_BURNED,
  ];

  static Future<void> ensureConfigured() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  static Future<HealthConnectSdkStatus?> androidSdkStatus() async {
    if (!Platform.isAndroid) return null;
    try {
      await ensureConfigured();
      return await _health.getHealthConnectSdkStatus();
    } catch (e, st) {
      debugPrint('Health Connect SDK status failed: $e\n$st');
      return null;
    }
  }

  static Future<bool> needsHealthConnectInstall() async {
    if (!Platform.isAndroid) return false;
    final status = await androidSdkStatus();
    return status == null ||
        status == HealthConnectSdkStatus.sdkUnavailable ||
        status == HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired;
  }

  static Future<bool> installHealthConnect() async {
    if (!Platform.isAndroid) return false;
    try {
      await ensureConfigured();
      await _health.installHealthConnect();
      return true;
    } catch (e, st) {
      debugPrint('installHealthConnect failed: $e\n$st');
      return false;
    }
  }

  static Future<bool> _ensureActivityRecognition() async {
    if (!Platform.isAndroid) return true;
    if (await Permission.activityRecognition.isGranted) return true;
    final result = await Permission.activityRecognition.request();
    return result.isGranted;
  }

  static Future<bool> hasPermissions() async {
    try {
      await ensureConfigured();
      return await _health.hasPermissions(_stepsTypes) ?? false;
    } catch (e, st) {
      debugPrint('hasPermissions failed: $e\n$st');
      return false;
    }
  }

  static Future<bool> requestPermissions() async {
    final result = await connect();
    return result.success;
  }

  /// Full connect flow with user-facing status message.
  static Future<HealthConnectResult> connect() async {
    try {
      await ensureConfigured();
    } catch (e, st) {
      debugPrint('Health configure failed: $e\n$st');
      return HealthConnectResult.fail(
        Platform.isAndroid
            ? 'Could not start Health Connect. Update Health Connect from the Play Store, then try again.'
            : 'Could not connect to Apple Health. Check Health permissions in Settings.',
        needsInstall: Platform.isAndroid,
      );
    }

    if (Platform.isAndroid) {
      final status = await androidSdkStatus();
      if (status == HealthConnectSdkStatus.sdkUnavailable ||
          status == HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired) {
        await installHealthConnect();
        return HealthConnectResult.fail(
          'Install or update Health Connect from the Play Store, then tap Connect again.',
          needsInstall: true,
        );
      }
      if (status == null || status != HealthConnectSdkStatus.sdkAvailable) {
        return HealthConnectResult.fail(
          'Health Connect is not ready. Open the Health Connect app, then tap Connect again.',
          needsInstall: true,
        );
      }
      if (!await _ensureActivityRecognition()) {
        return HealthConnectResult.fail(
          'Allow physical activity permission so steps can sync.',
        );
      }
    }

    try {
      final granted = await _health.requestAuthorization(
        _stepsTypes,
        permissions: [HealthDataAccess.READ],
      );
      if (!granted) {
        return HealthConnectResult.fail(
          Platform.isIOS
              ? 'Permission denied. Open Settings → Health → Data Access → Gym Companion → allow Steps.'
              : 'Permission denied. Open Health Connect → App permissions → Gym Companion → allow Steps.',
        );
      }
    } catch (e, st) {
      debugPrint('requestAuthorization (steps) failed: $e\n$st');
      return HealthConnectResult.fail(
        Platform.isAndroid
            ? 'Could not open Health Connect permissions. Update Health Connect from the Play Store and try again.'
            : 'Could not request Apple Health permissions. Try again from Settings.',
        needsInstall: Platform.isAndroid,
      );
    }

    // Optional types — do not fail connect if these are declined.
    try {
      await _health.requestAuthorization(
        _extraTypes,
        permissions: List.filled(_extraTypes.length, HealthDataAccess.READ),
      );
    } catch (e, st) {
      debugPrint('requestAuthorization (extra types) failed: $e\n$st');
    }

    final steps = await getTodaySteps();
    return HealthConnectResult.ok(steps: steps);
  }

  static Future<int> getTodaySteps() async {
    await ensureConfigured();
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    try {
      final steps = await _health.getTotalStepsInInterval(midnight, now);
      return steps ?? 0;
    } catch (e, st) {
      debugPrint('getTodaySteps failed: $e\n$st');
      return 0;
    }
  }

  static Future<double> getTodayActiveCalories() async {
    await ensureConfigured();
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    try {
      final data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.ACTIVE_ENERGY_BURNED],
        startTime: midnight,
        endTime: now,
      );
      return data.fold<double>(0, (sum, point) {
        final v = point.value;
        if (v is NumericHealthValue) return sum + v.numericValue.toDouble();
        return sum;
      });
    } catch (e, st) {
      debugPrint('getTodayActiveCalories failed: $e\n$st');
      return 0;
    }
  }
}
