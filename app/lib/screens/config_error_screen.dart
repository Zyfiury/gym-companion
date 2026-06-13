import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state_card.dart';

/// Shown in release builds when Firebase is not configured.
class ConfigErrorScreen extends StatelessWidget {
  const ConfigErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final c = context.appColors;
    return Scaffold(
      backgroundColor: t.scaffold,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              EmptyStateCard(
                icon: Icons.error_outline,
                headline: '${AppConfig.appName} is not configured',
                subtext:
                    'This release build requires Firebase. Please contact support or reinstall from the official store once the issue is resolved.',
              ),
              const SizedBox(height: 16),
              Text(
                AppConfig.supportEmail,
                style: TextStyle(color: c.primary, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
