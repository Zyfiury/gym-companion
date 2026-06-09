import 'package:flutter/material.dart';

import '../config/app_config.dart';

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

  bool _annual = false;

  String? _error;

  @override
  void initState() {
    super.initState();
    AnalyticsService.paywallView(widget.triggerSource ?? widget.highlightFeature ?? 'general');
  }

  static const _features = [

    ('Unlimited AI coach', 'Chat anytime — workouts, meals, macros', Icons.chat_bubble_outline),

    ('Smart meal & workout plans', 'Personalised weekly splits', Icons.auto_awesome),

    ('Progress analytics', 'Trends, PRs, and macro insights', Icons.insights),

    ('Export CSV & PDF', 'Share reports with your trainer', Icons.file_download_outlined),

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

      Navigator.pop(context, true);

      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(content: Text('Welcome to Gym Companion Pro!')),

      );

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

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pro restored')));

    } else {

      setState(() => _error = 'No active subscription found.');

    }

  }



  @override

  Widget build(BuildContext context) {

    final price = _annual ? AppConfig.proAnnualPrice : AppConfig.proMonthlyPrice;



    final t = context.appTheme;

    return Scaffold(

      backgroundColor: t.scaffold,

      body: AmbientBackground(
        child: SafeArea(

        child: Column(

          children: [

            Align(

              alignment: Alignment.topRight,

              child: IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close, color: t.textPrimary)),

            ),

            Expanded(

              child: SingleChildScrollView(

                padding: const EdgeInsets.symmetric(horizontal: 24),

                child: Column(

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    Container(

                      width: double.infinity,

                      padding: const EdgeInsets.all(24),

                      decoration: BoxDecoration(

                        gradient: AppColors.gradient,

                        borderRadius: BorderRadius.circular(20),

                      ),

                      child: Column(

                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [

                          const Text('Gym Companion', style: TextStyle(color: Colors.white70, fontSize: 14)),

                          const Text('Pro', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),

                          const SizedBox(height: 8),

                          Text(

                            widget.highlightFeature != null

                                ? 'Unlock ${widget.highlightFeature} and everything below'

                                : 'Everything you need to hit your goals',

                            style: const TextStyle(color: Colors.white70, fontSize: 14),

                          ),

                        ],

                      ),

                    ),

                    const SizedBox(height: 24),

                    ..._features.map((f) {

                      final highlighted = widget.highlightFeature != null &&

                          f.$1.toLowerCase().contains(widget.highlightFeature!.toLowerCase().split(' ').first);

                      return Container(

                        margin: const EdgeInsets.only(bottom: 10),

                        padding: const EdgeInsets.all(14),

                        decoration: BoxDecoration(

                          color: highlighted ? AppColors.violet.withValues(alpha: 0.12) : t.card,

                          borderRadius: BorderRadius.circular(14),

                          border: Border.all(

                            color: highlighted ? AppColors.violet.withValues(alpha: 0.4) : t.borderSubtle,

                          ),
                          boxShadow: context.isDarkTheme ? null : [BoxShadow(color: t.shadow, blurRadius: 8, offset: const Offset(0, 2))],

                        ),

                        child: Row(

                          children: [

                            Icon(f.$3, color: AppColors.violet, size: 22),

                            const SizedBox(width: 14),

                            Expanded(

                              child: Column(

                                crossAxisAlignment: CrossAxisAlignment.start,

                                children: [

                                  Text(f.$1, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: t.textPrimary)),

                                  Text(f.$2, style: TextStyle(color: t.textSecondary, fontSize: 12)),

                                ],

                              ),

                            ),

                            const Icon(Icons.check_circle, color: AppColors.violet, size: 18),

                          ],

                        ),

                      );

                    }),

                    const SizedBox(height: 20),

                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: t.elevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: t.borderSubtle),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _annual = false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: !_annual ? AppColors.violet.withValues(alpha: context.isDarkTheme ? 0.25 : 0.15) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'Monthly',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: !_annual ? FontWeight.bold : FontWeight.normal,
                                    color: !_annual ? AppColors.violet : t.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _annual = true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _annual ? AppColors.violet.withValues(alpha: context.isDarkTheme ? 0.25 : 0.15) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'Annual',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: _annual ? AppColors.violet : t.textPrimary,
                                      ),
                                    ),
                                    Text('Save 37%', style: TextStyle(fontSize: 10, color: AppColors.violet.withValues(alpha: 0.9))),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (_error != null) ...[

                      const SizedBox(height: 12),

                      Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),

                    ],

                  ],

                ),

              ),

            ),

            Padding(

              padding: const EdgeInsets.all(24),

              child: Column(

                children: [

                  GradientButton(

                    label: _loading ? 'Processing…' : 'Start Pro — $price',

                    expanded: true,

                    onPressed: _loading ? null : _purchase,

                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Cancel anytime. Subscriptions renew automatically.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: t.textMuted),
                  ),
                  TextButton(
                    onPressed: _loading ? null : _restore,
                    child: Text('Restore purchases', style: TextStyle(color: AppColors.violet)),
                  ),

                ],

              ),

            ),

          ],

        ),

      ),
      ),

    );

  }

}


