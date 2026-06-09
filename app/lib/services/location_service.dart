import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

class UserLocation {
  final double latitude;
  final double longitude;
  final String? label;
  final bool isDemoFallback;

  const UserLocation({
    required this.latitude,
    required this.longitude,
    this.label,
    this.isDemoFallback = false,
  });
}

enum LocationAccessResult {
  granted,
  denied,
  deniedForever,
  serviceDisabled,
  /// Permission OK but no GPS fix (common on emulators without mock location).
  positionUnavailable,
}

class LocationResolveResult {
  final LocationAccessResult status;
  final UserLocation? location;
  final String message;

  const LocationResolveResult({
    required this.status,
    this.location,
    required this.message,
  });

  bool get ok => location != null;
}

class LocationService {
  /// Demo coords (London) when GPS unavailable in debug — UK app defaults.
  static const demoLocation = UserLocation(
    latitude: 51.5074,
    longitude: -0.1278,
    label: 'London (demo)',
    isDemoFallback: true,
  );

  static Future<bool> isServiceEnabled() => Geolocator.isLocationServiceEnabled();

  static Future<LocationPermission> _currentPermission() => Geolocator.checkPermission();

  static Future<bool> hasPermission() async {
    final permission = await _currentPermission();
    return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
  }

  static Future<bool> isPermanentlyDenied() async {
    final permission = await _currentPermission();
    return permission == LocationPermission.deniedForever;
  }

  static Future<LocationAccessResult> requestAccess() async {
    final resolved = await resolveLocation(requestIfNeeded: true);
    return resolved.status;
  }

  static Future<bool> requestPermission() async {
    final resolved = await resolveLocation();
    return resolved.ok;
  }

  /// Request permission (if needed) and obtain coordinates.
  static Future<LocationResolveResult> resolveLocation({bool requestIfNeeded = true}) async {
    if (!await isServiceEnabled()) {
      return const LocationResolveResult(
        status: LocationAccessResult.serviceDisabled,
        message: 'Turn on device location (GPS) in your phone settings.',
      );
    }

    var permission = await _currentPermission();
    if (permission == LocationPermission.denied && requestIfNeeded) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      return const LocationResolveResult(
        status: LocationAccessResult.deniedForever,
        message: 'Location is blocked. Open Settings and allow location for Gym Companion.',
      );
    }
    if (permission == LocationPermission.denied) {
      return const LocationResolveResult(
        status: LocationAccessResult.denied,
        message: 'Location permission is required to find food near you.',
      );
    }

    final location = await _readPosition();
    if (location != null) {
      return LocationResolveResult(
        status: LocationAccessResult.granted,
        location: location,
        message: 'Location ready',
      );
    }

    if (kDebugMode) {
      return LocationResolveResult(
        status: LocationAccessResult.granted,
        location: demoLocation,
        message: 'Using demo location (set mock GPS on emulator for real results).',
      );
    }

    return const LocationResolveResult(
      status: LocationAccessResult.positionUnavailable,
      message: 'Could not get GPS fix. Move outdoors or set a mock location, then try again.',
    );
  }

  static Future<UserLocation?> _readPosition() async {
    try {
      Position? pos = await Geolocator.getLastKnownPosition();
      pos ??= await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 8),
        ),
      );
      return UserLocation(latitude: pos.latitude, longitude: pos.longitude);
    } catch (_) {
      return null;
    }
  }

  static Future<UserLocation?> getCurrentLocation() async {
    final resolved = await resolveLocation();
    return resolved.location;
  }

  static Future<bool> openAppSettings() => ph.openAppSettings();

  static Future<bool> openLocationSettings() => Geolocator.openLocationSettings();
}
