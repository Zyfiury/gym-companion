import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../providers/app_state.dart';
import '../core/widgets/app_toast.dart';
import '../services/analytics_service.dart';
import '../services/subscription_service.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';
import '../widgets/staggered_entry.dart';

class PaywallScreen extends StatefulWidget {
  final String? highlightFeature;
  final String? triggerSource;

  const PaywallScreen({super.key, this.highlightFeature, this.triggerSource});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool _loading = false;
  bool _annual = true;
  String? _error;
  String? _monthlyPrice;
  String? _annualPrice;
  String? _trialLabel;

  @override
  void initState() {
    super.initState();
    AnalyticsService.paywallView(widget.triggerSource ?? widget.highlightFeature ?? 'general');
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    try {
      final offerings = await SubscriptionService.loadOfferings();
      if (!mounted) return;
      setState(() {
        _monthlyPrice = offerings.monthlyPrice;
        _annualPrice = offerings.annualPrice;
        _trialLabel = offerings.trialLabel;
      });
    } catch (_) {}
  }

  static const _features = [
    'Unlimited AI coach',
    'Smart meal & workout plans',
    'Progress analytics & trends',
    'Export CSV & PDF',
    'Full leaderboard access',
    'Week & month meal views',
  ];

  Future<void> _purchase() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final plan = _annual ? 'annual' : 'monthly';
    AnalyticsService.purchaseStart(plan);
    final ok = await SubscriptionService.purchasePro(plan: _annual ? ProPlan.annual : ProPlan.monthly);
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      AnalyticsService.purchaseSuccess(plan);
      if (context.mounted) {
        await context.read<AppState>().refreshProStatus();
      }
      Navigator.pop(context, true);
      AppToast.success(context, _trialLabel != null ? 'Welcome to Pro - ${_trialLabel!}' : 'Welcome to Gym Companion Pro!');
    } else {
      setState(() => _error = 'Purchase could not be completed. Try again or restore purchases.');
    }
  }

  Future<void> _restore() async {
    setState(() => _loading = true);
    final ok = await SubscriptionService.restorePurchases();
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      Navigator.pop(context, true);
      AppToast.success(context, 'Pro restored ✓');
    } else {
      setState(() => _error = 'No active subscription found.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    // Strip "/month" etc - the price card renders its own suffix.
    final monthly = (_monthlyPrice ?? AppConfig.proMonthlyPrice).split('/').first;
    final annual = (_annualPrice ?? AppConfig.proAnnualPrice).split('/').first;
    final annualPerMonth = _annualPrice != null ? null : '£${(59.99 / 12).toStringAsFixed(2)}';
    final headline = switch (widget.triggerSource) {
      'coach_limit' => 'Unlimited AI coaching',
      'leaderboard' => 'Climb the leaderboard',
      'food_week' => 'Full meal planning',
      _ => 'Unlock everything',
    };

    return Scaffold(
      backgroundColor: c.bgBase,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close, color: c.textMuted),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StaggeredEntry(
                      index: 0,
                      child: Text(
                        headline,
                        style: GoogleFonts.gloock(fontSize: 36, color: c.textPrimary, height: 1.1),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.highlightFeature != null
                          ? 'Includes ${widget.highlightFeature} and all Pro features'
                          : 'Training, nutrition, and progress - without limits',
                      style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w300, color: c.textMuted, height: 1.5),
                    ),
                    const SizedBox(height: 28),
                    ..._features.map((f) {
                      final highlighted = widget.highlightFeature != null &&
                          f.toLowerCase().contains(widget.highlightFeature!.toLowerCase().split(' ').first);
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: c.border)),
                          color: highlighted ? c.primaryGlow : null,
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check, color: c.primary, size: 20),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                f,
                                style: GoogleFonts.dmSans(fontSize: 14, color: c.textPrimary),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(child: _PriceCard(
                          label: 'Monthly',
                          price: monthly,
                          suffix: '/mo',
                          selected: !_annual,
                          onTap: () => setState(() => _annual = false),
                          semanticsId: 'paywall-monthly-tab',
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: _PriceCard(
                          label: 'Annual',
                          price: annual,
                          suffix: '/yr',
                          perMonth: annualPerMonth,
                          selected: _annual,
                          bestValue: true,
                          onTap: () => setState(() => _annual = true),
                          semanticsId: 'paywall-annual-tab',
                        )),
                      ],
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: TextStyle(color: c.error, fontSize: 13)),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Column(
                children: [
                  Semantics(
                    identifier: 'paywall-purchase-btn',
                    button: true,
                    child: GradientButton(
                      label: _loading ? 'Processing…' : (_trialLabel ?? 'Start Pro'),
                      expanded: true,
                      onPressed: _loading ? null : _purchase,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Semantics(
                    identifier: 'paywall-restore-btn',
                    button: true,
                    child: TextButton(
                      onPressed: _loading ? null : _restore,
                      child: Text('Restore purchase', style: TextStyle(color: c.textMuted)),
                    ),
                  ),
                  Text(
                    'Cancel anytime. Subscriptions renew automatically.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(fontSize: 10, color: c.textMuted, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceCard extends StatelessWidget {
  final String label;
  final String price;
  final String suffix;
  final String? perMonth;
  final bool selected;
  final bool bestValue;
  final VoidCallback onTap;
  final String semanticsId;

  const _PriceCard({
    required this.label,
    required this.price,
    required this.suffix,
    this.perMonth,
    required this.selected,
    this.bestValue = false,
    required this.onTap,
    required this.semanticsId,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Semantics(
      identifier: semanticsId,
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: selected ? c.primary : c.border, width: selected ? 2 : 1),
                boxShadow: selected ? c.primaryGlowShadow : c.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.dmSans(fontSize: 13, color: c.textMuted)),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(price, style: GoogleFonts.gloock(fontSize: 28, color: c.textPrimary)),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4, left: 2),
                        child: Text(suffix, style: GoogleFonts.dmSans(fontSize: 13, color: c.textMuted)),
                      ),
                    ],
                  ),
                  if (perMonth != null)
                    Text('$perMonth/mo', style: GoogleFonts.dmSans(fontSize: 11, color: c.olive)),
                ],
              ),
            ),
            if (bestValue)
              Positioned(
                top: -8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: c.olive,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    'Best value',
                    style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w600, color: c.onPrimary),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
