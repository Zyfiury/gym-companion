import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../theme/app_theme.dart';

/// Shown in release builds when Firebase is not configured.
class ConfigErrorScreen extends StatelessWidget {
  const ConfigErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.orange),
              const SizedBox(height: 24),
              Text(
                '${AppConfig.appName} is not configured',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 12),
              const Text(
                'This release build requires Firebase. Please contact support or reinstall from the official store once the issue is resolved.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.white70, height: 1.5),
              ),
              const SizedBox(height: 24),
              Text(
                AppConfig.supportEmail,
                style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
