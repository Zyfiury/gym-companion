import 'dart:io';

import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../services/health_service.dart';
import '../theme/app_theme.dart';

Future<void> showHealthConnectSheet(
  BuildContext context, {
  required bool connected,
  required int steps,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.appTheme.card,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: _HealthConnectBody(connected: connected, steps: steps),
      ),
    ),
  );
}

class _HealthConnectBody extends StatefulWidget {
  final bool connected;
  final int steps;

  const _HealthConnectBody({required this.connected, required this.steps});

  @override
  State<_HealthConnectBody> createState() => _HealthConnectBodyState();
}

class _HealthConnectBodyState extends State<_HealthConnectBody> {
  bool _loading = false;
  bool _needsInstall = false;

  @override
  void initState() {
    super.initState();
    _checkAndroidStatus();
  }

  Future<void> _checkAndroidStatus() async {
    if (!Platform.isAndroid) return;
    final status = await HealthService.androidSdkStatus();
    if (!mounted) return;
    setState(() {
      _needsInstall = status == HealthConnectSdkStatus.sdkUnavailable ||
          status == HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired;
    });
  }

  Future<void> _install() async {
    setState(() => _loading = true);
    await HealthService.installHealthConnect();
    if (!mounted) return;
    setState(() => _loading = false);
    await _checkAndroidStatus();
  }

  Future<void> _connect() async {
    setState(() => _loading = true);
    final msg = await context.read<AppState>().connectHealth();
    if (!mounted) return;
    setState(() => _loading = false);
    if (msg.startsWith('✓')) Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final android = Platform.isAndroid;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Connect health app', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: t.textPrimary)),
        const SizedBox(height: 8),
        Text(
          widget.connected
              ? (widget.steps > 0 ? '${widget.steps} steps today — keep moving!' : '0 steps today — open Health Connect if steps look wrong.')
              : android
                  ? 'Sync steps from Health Connect (Samsung Health, Google Fit, and other apps link through it).'
                  : 'Sync your step count automatically from Apple Health.',
          style: TextStyle(color: t.textSecondary, fontSize: 14, height: 1.4),
        ),
        if (_needsInstall && !widget.connected) ...[
          const SizedBox(height: 12),
          Text(
            'Health Connect is required on Android. Install it from the Play Store, then tap Connect.',
            style: TextStyle(color: AppColors.orange, fontSize: 12, height: 1.35),
          ),
        ],
        const SizedBox(height: 20),
        if (!widget.connected) ...[
          if (_needsInstall)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.accent, side: BorderSide(color: t.borderSubtle)),
                onPressed: _loading ? null : _install,
                child: Text(_loading ? 'Opening Play Store…' : 'Install Health Connect'),
              ),
            ),
          if (_needsInstall) const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
              onPressed: _loading ? null : _connect,
              child: Text(_loading ? 'Connecting…' : 'Connect now'),
            ),
          ),
        ] else
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ),
      ],
    );
  }
}
