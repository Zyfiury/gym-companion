import 'dart:io';

import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

class HealthService {
  static final _health = Health();
  static bool _configured = false;

  static const _types = [
    HealthDataType.STEPS,
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
    await ensureConfigured();
    try {
      return _health.getHealthConnectSdkStatus();
    } catch (_) {
      return null;
    }
  }

  static Future<bool> installHealthConnect() async {
    if (!Platform.isAndroid) return false;
    await ensureConfigured();
    try {
      await _health.installHealthConnect();
      return true;
    } catch (_) {
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
    await ensureConfigured();
    try {
      return await _health.hasPermissions(_types) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> requestPermissions() async {
    await ensureConfigured();

    if (Platform.isAndroid) {
      final status = await androidSdkStatus();
      if (status == HealthConnectSdkStatus.sdkUnavailable ||
          status == HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired) {
        await installHealthConnect();
        return false;
      }
      if (status != HealthConnectSdkStatus.sdkAvailable) {
        return false;
      }
      await _ensureActivityRecognition();
    }

    try {
      return await _health.requestAuthorization(
        _types,
        permissions: List.filled(_types.length, HealthDataAccess.READ),
      );
    } catch (_) {
      return false;
    }
  }

  static Future<int> getTodaySteps() async {
    await ensureConfigured();
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    try {
      final steps = await _health.getTotalStepsInInterval(midnight, now);
      return steps ?? 0;
    } catch (_) {
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
    } catch (_) {
      return 0;
    }
  }
}
