import 'package:health/health.dart';

class HealthService {
  static final _health = Health();

  static const _types = [HealthDataType.STEPS, HealthDataType.WEIGHT, HealthDataType.ACTIVE_ENERGY_BURNED];

  static Future<bool> hasPermissions() async {
    try {
      return await _health.hasPermissions(_types) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> requestPermissions() async {
    try {
      return await _health.requestAuthorization(_types);
    } catch (_) {
      return false;
    }
  }

  static Future<int> getTodaySteps() async {
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
