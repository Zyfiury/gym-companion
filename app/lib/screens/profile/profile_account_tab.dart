import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_config.dart';
import '../../models/user_data.dart';
import '../../providers/app_state.dart';
import '../../services/export_service.dart';
import '../../services/subscription_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/pro_gate.dart';
import '../../widgets/page_transitions.dart';
import '../../widgets/premium_ui.dart';
import '../../widgets/profile/profile_glass_card.dart';
import '../../widgets/profile/profile_settings_row.dart';
import '../../widgets/staggered_entry.dart';
import '../paywall_screen.dart';

class ProfileAccountTab extends StatelessWidget {
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This permanently deletes your profile, logs, and chat history. This cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await context.read<AppState>().deleteAccount();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account deleted')));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
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
                  semanticsId: 'profile-pro-upgrade',
                  icon: Icons.star_rounded,
                  iconColor: AppColors.ember,
                  title: 'Gym Companion Pro',
                  subtitle: AppConfig.proMonthlyPrice,
                  onTap: () => pushPremium(context, const PaywallScreen()),
                ),
                Divider(height: 1, color: t.borderSubtle.withValues(alpha: 0.5)),
                ProfileSettingsRow(
                  icon: Icons.restore_rounded,
                  title: 'Restore purchases',
                  showChevron: false,
                  onTap: () async {
                    final ok = await SubscriptionService.restorePurchases();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(ok ? 'Pro restored ✓' : 'No active subscription found')),
                    );
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
              iconColor: Colors.redAccent,
              title: 'Delete account',
              titleColor: Colors.redAccent,
              showChevron: false,
              onTap: () => _confirmDeleteAccount(context),
            ),
          ),
        ),
      ],
    );
  }
}
