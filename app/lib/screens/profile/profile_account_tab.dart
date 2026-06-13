import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/app_toast.dart';
import '../../models/user_data.dart';
import '../../providers/app_state.dart';
import '../../services/export_service.dart';
import '../../services/subscription_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/sheet_padding.dart';
import '../../utils/pro_gate.dart';
import '../../widgets/page_transitions.dart';
import '../../widgets/premium_ui.dart';
import '../../widgets/profile/profile_glass_card.dart';
import '../../widgets/profile/profile_settings_row.dart';
import '../../widgets/staggered_entry.dart';
import '../paywall_screen.dart';

class ProfileAccountTab extends ConsumerWidget {
  final UserData user;
  final String displayName;

  const ProfileAccountTab({
    super.key,
    required this.user,
    required this.displayName,
  });

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: 'Delete account?',
      message: 'This permanently deletes your profile, logs, and chat history. This cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (confirmed != true || !context.mounted) return;
    await context.read<AppState>().deleteAccount();
    if (!context.mounted) return;
    AppToast.success(context, 'Account deleted');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.appTheme;
    final themeMode = ref.watch(themeModeProvider);
    final platformBrightness = MediaQuery.platformBrightnessOf(context);
    final isDark = resolveIsDark(themeMode, platformBrightness);
    final themeLabel = switch (themeMode) {
      ThemeMode.dark => 'Dark',
      ThemeMode.light => 'Light',
      ThemeMode.system => 'System',
    };

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 8, 16, scrollBottomInset(context, extra: 24)),
      children: [
        StaggeredEntry(
          index: 0,
          child: ProfileGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Export data', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: t.textPrimary)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ActionTile(
                      id: 'export-csv-btn',
                      icon: Icons.table_chart_outlined,
                      label: 'CSV',
                      onTap: () async {
                        if (!await ProGate.check(context, feature: 'export')) return;
                        await ExportService.exportWeightCSV(user);
                      },
                    ),
                    const SizedBox(width: 12),
                    ActionTile(
                      id: 'export-pdf-btn',
                      icon: Icons.picture_as_pdf_outlined,
                      label: 'PDF',
                      onTap: () async {
                        if (!await ProGate.check(context, feature: 'export')) return;
                        await ExportService.exportProgressPDF(user, displayName: displayName);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        StaggeredEntry(
          index: 1,
          child: ProfileGlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 4),
                  child: Text('Account & legal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: t.textPrimary)),
                ),
                ProfileSettingsRow(
                  semanticsId: 'profile-theme-toggle',
                  icon: isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                  iconColor: context.appColors.primary,
                  title: 'Appearance',
                  subtitle: themeLabel,
                  onTap: () => ref.read(themeModeProvider.notifier).toggle(),
                ),
                Divider(height: 1, color: t.borderSubtle.withValues(alpha: 0.5)),
                ProfileSettingsRow(
                  semanticsId: 'profile-pro-upgrade',
                  icon: Icons.star_rounded,
                  iconColor: context.appColors.sand,
                  title: 'Gym Companion Pro',
                  subtitle: AppConfig.proMonthlyPrice,
                  onTap: () => pushModal(context, const PaywallScreen()),
                ),
                Divider(height: 1, color: t.borderSubtle.withValues(alpha: 0.5)),
                ProfileSettingsRow(
                  icon: Icons.restore_rounded,
                  title: 'Restore purchases',
                  showChevron: false,
                  onTap: () async {
                    final ok = await SubscriptionService.restorePurchases();
                    if (!context.mounted) return;
                    if (ok) {
                      AppToast.success(context, 'Pro restored ✓');
                    } else {
                      AppToast.error(context, 'No active subscription found');
                    }
                  },
                ),
                Divider(height: 1, color: t.borderSubtle.withValues(alpha: 0.5)),
                ProfileSettingsRow(
                  icon: Icons.subscriptions_outlined,
                  title: 'Manage subscription',
                  subtitle: 'Cancel or change plan',
                  showChevron: false,
                  onTap: () async {
                    final ok = await SubscriptionService.openManageSubscriptions();
                    if (!context.mounted) return;
                    if (!ok) AppToast.error(context, 'Could not open subscription settings');
                  },
                ),
                Divider(height: 1, color: t.borderSubtle.withValues(alpha: 0.5)),
                ProfileSettingsRow(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  showChevron: false,
                  onTap: () => _openUrl(AppConfig.privacyPolicyUrl),
                ),
                Divider(height: 1, color: t.borderSubtle.withValues(alpha: 0.5)),
                ProfileSettingsRow(
                  icon: Icons.description_outlined,
                  title: 'Terms of Service',
                  showChevron: false,
                  onTap: () => _openUrl(AppConfig.termsOfServiceUrl),
                ),
                Divider(height: 1, color: t.borderSubtle.withValues(alpha: 0.5)),
                ProfileSettingsRow(
                  icon: Icons.mail_outline_rounded,
                  title: 'Contact ${AppConfig.supportEmail}',
                  showChevron: false,
                  onTap: () => _openUrl('mailto:${AppConfig.supportEmail}'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        StaggeredEntry(
          index: 2,
          child: ProfileGlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ProfileSettingsRow(
              semanticsId: 'delete-account-btn',
              icon: Icons.delete_forever_outlined,
              iconColor: context.appColors.error,
              title: 'Delete account',
              titleColor: context.appColors.error,
              showChevron: false,
              onTap: () => _confirmDeleteAccount(context),
            ),
          ),
        ),
      ],
    );
  }
}
