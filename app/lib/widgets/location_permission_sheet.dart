import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import 'gradient_button.dart';

class LocationPermissionSheet extends StatefulWidget {
  const LocationPermissionSheet({super.key});

  static Future<void> show(BuildContext context) {
    final appState = context.read<AppState>();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => ChangeNotifierProvider<AppState>.value(
        value: appState,
        child: const LocationPermissionSheet(),
      ),
    );
  }

  @override
  State<LocationPermissionSheet> createState() => _LocationPermissionSheetState();
}

class _LocationPermissionSheetState extends State<LocationPermissionSheet> {
  bool _loading = false;
  String? _message;

  Future<void> _enableLocation() async {
    setState(() {
      _loading = true;
      _message = null;
    });

    final result = await LocationService.resolveLocation();

    if (!mounted) return;

    if (result.ok) {
      await context.read<AppState>().dismissLocationPrompt(granted: true);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.location!.isDemoFallback
                ? 'Using demo location for nearby search'
                : 'Location enabled',
          ),
        ),
      );
      return;
    }

    setState(() {
      _loading = false;
      _message = result.message;
    });

    if (result.status == LocationAccessResult.deniedForever) {
      await LocationService.openAppSettings();
    } else if (result.status == LocationAccessResult.serviceDisabled) {
      await LocationService.openLocationSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    return Container(
      margin: EdgeInsets.fromLTRB(16, 0, 16, 24 + MediaQuery.paddingOf(context).bottom),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: t.borderSubtle),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.location_on_outlined, color: AppColors.accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Enable location',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: t.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Gym Companion uses your location to find nearby delivery, restaurants, and supermarket prices tailored to where you are.',
            style: TextStyle(fontSize: 14, height: 1.5, color: t.textSecondary),
          ),
          if (_message != null) ...[
            const SizedBox(height: 12),
            Text(_message!, style: TextStyle(fontSize: 13, color: AppColors.ember, height: 1.4)),
          ],
          const SizedBox(height: 20),
          GradientButton(
            label: _loading ? 'Requesting…' : 'Enable location',
            expanded: true,
            onPressed: _loading ? null : _enableLocation,
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _loading
                  ? null
                  : () async {
                      await context.read<AppState>().dismissLocationPrompt();
                      if (context.mounted) Navigator.pop(context);
                    },
              child: Text('Not now', style: TextStyle(color: t.textMuted)),
            ),
          ),
        ],
      ),
    );
  }
}
