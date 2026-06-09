import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/allergy_guard.dart';
import '../services/analytics_service.dart';
import '../services/health_safety_service.dart';
import '../services/tdee_service.dart';
import '../theme/app_theme.dart';
import '../widgets/onboarding/nav_bar.dart';
import '../widgets/onboarding/obsidian_shell.dart';
import '../widgets/onboarding/progress_bar.dart';
import 'onboarding/age_step.dart';
import 'onboarding/allergies_step.dart';
import 'onboarding/budget_step.dart';
import 'onboarding/dietary_step.dart';
import 'onboarding/goal_step.dart';
import 'onboarding/mobility_step.dart';
import 'onboarding/nutrition_step.dart';
import 'onboarding/onboarding_welcome.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _showWelcome = true;
  bool _finishing = false;
  final _pageCtrl = PageController();
  int step = 0;
  static const totalSteps = 7;

  int age = 30;
  String goal = '';
  String genderAtBirth = 'male';
  double weight = 70;
  double height = 175;
  int tdee = TdeeService.calculateTdee(weightKg: 70, heightCm: 175, age: 30, genderAtBirth: 'male');
  double weeklyBudget = 50;
  String nutritionMode = 'cook_myself';
  final Set<String> allergies = {};
  final Set<String> dietaryPreferences = {};
  final Set<String> disabilities = {};
  final _disabilityCtrl = TextEditingController();
  final _customAllergyCtrl = TextEditingController();

  static const _dietaryOptions = [
    (id: 'halal', label: 'Halal', icon: Icons.mosque_outlined),
    (id: 'vegetarian', label: 'Vegetarian', icon: Icons.eco_outlined),
    (id: 'vegan', label: 'Vegan', icon: Icons.spa_outlined),
    (id: 'kosher', label: 'Kosher', icon: Icons.star_outline_rounded),
    (id: 'pescatarian', label: 'Pescatarian', icon: Icons.set_meal_outlined),
  ];

  static const _nutritionModes = [
    (id: 'cook_myself', title: 'Cook myself', subtitle: 'Recipes & shopping lists at home', icon: Icons.restaurant_rounded),
    (id: 'home_delivery', title: 'Home delivery', subtitle: 'Takeaways that fit your macros', icon: Icons.delivery_dining_rounded),
    (id: 'eat_out', title: 'Eat out', subtitle: 'Restaurant picks near you', icon: Icons.storefront_rounded),
  ];

  @override
  void dispose() {
    _pageCtrl.dispose();
    _disabilityCtrl.dispose();
    _customAllergyCtrl.dispose();
    super.dispose();
  }

  void _recalcTdee() {
    tdee = TdeeService.calculateTdee(
      weightKg: weight,
      heightCm: height,
      age: age,
      genderAtBirth: genderAtBirth,
    );
  }

  Future<void> _finish() async {
    final plan = TdeeService.plan(
      weightKg: weight,
      heightCm: height,
      age: age,
      goal: goal.isEmpty ? 'maintain' : goal,
      genderAtBirth: genderAtBirth,
    );
    tdee = plan.maintenance;
    final cal = plan.target;
    var dietType = 'omnivore';
    if (dietaryPreferences.contains('vegan')) {
      dietType = 'vegan';
    } else if (dietaryPreferences.contains('vegetarian')) {
      dietType = 'vegetarian';
    } else if (dietaryPreferences.contains('pescatarian')) {
      dietType = 'pescatarian';
    }
    await AnalyticsService.onboardingComplete();
    if (!mounted) return;
    await context.read<AppState>().completeOnboarding(
      goal: goal,
      weight: weight,
      height: height,
      age: age,
      tdee: cal,
      weeklyBudget: weeklyBudget,
      allergies: allergies.toList(),
      dietType: dietType,
      disabilities: disabilities.toList(),
      dietaryPreferences: dietaryPreferences.toList(),
      nutritionMode: nutritionMode,
    );
  }

  void _next() {
    if (step < totalSteps - 1) {
      setState(() => step++);
      _pageCtrl.nextPage(duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
    } else {
      _finish();
    }
  }

  void _back() {
    setState(() => step--);
    _pageCtrl.previousPage(duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
  }

  void _tryNext() {
    if (step == 4 && goal.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a goal', style: ObsidianTypography.body(color: ObsidianTokens.textPrimary)),
          backgroundColor: ObsidianTokens.surfaceMuted,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ObsidianTokens.radiusSm)),
        ),
      );
      return;
    }
    _next();
  }

  @override
  Widget build(BuildContext context) {
    if (_showWelcome) {
      return Scaffold(
        backgroundColor: ObsidianTokens.base,
        body: OnboardingWelcome(onStart: () => setState(() => _showWelcome = false)),
      );
    }

    return Scaffold(
      backgroundColor: ObsidianTokens.base,
      body: ObsidianShell(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(ObsidianTokens.spacingLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  identifier: 'onboard-title',
                  child: Text('SET UP YOUR PROFILE', style: ObsidianTypography.category()),
                ),
                SizedBox(height: ObsidianTokens.spacingSm),
                OnboardingProgressBar(step: step, total: totalSteps),
                SizedBox(height: ObsidianTokens.spacingLg),
                Expanded(
                  child: PageView(
                    controller: _pageCtrl,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (i) => setState(() => step = i),
                    children: [
                      AgeStep(
                        age: age,
                        onAgeChanged: (v) => setState(() {
                          age = v;
                          _recalcTdee();
                        }),
                      ),
                      MobilityStep(
                        options: HealthSafetyService.disabilityLabels,
                        selected: disabilities,
                        customController: _disabilityCtrl,
                        onToggle: (key) => setState(() {
                          if (disabilities.contains(key)) {
                            disabilities.remove(key);
                          } else {
                            disabilities.add(key);
                          }
                        }),
                        onCustomSubmit: (v) {
                          if (v.trim().isNotEmpty) setState(() => disabilities.add(v.trim()));
                        },
                      ),
                      AllergiesStep(
                        options: AllergyGuard.allAllergenOptions,
                        selected: allergies,
                        customController: _customAllergyCtrl,
                        onToggle: (key) => setState(() {
                          if (allergies.contains(key)) {
                            allergies.remove(key);
                          } else {
                            allergies.add(key);
                          }
                        }),
                        onCustomAdd: () {
                          final v = _customAllergyCtrl.text.trim();
                          if (v.isNotEmpty) {
                            setState(() {
                              allergies.add(v);
                              _customAllergyCtrl.clear();
                            });
                          }
                        },
                      ),
                      DietaryStep(
                        options: _dietaryOptions,
                        selected: dietaryPreferences,
                        onToggle: (id) => setState(() {
                          if (dietaryPreferences.contains(id)) {
                            dietaryPreferences.remove(id);
                          } else {
                            dietaryPreferences.add(id);
                          }
                        }),
                      ),
                      GoalStep(
                        age: age,
                        weight: weight,
                        height: height,
                        goal: goal,
                        genderAtBirth: genderAtBirth,
                        onWeightChanged: (v) => setState(() {
                          weight = v.roundToDouble();
                          _recalcTdee();
                        }),
                        onHeightChanged: (v) => setState(() {
                          height = v.roundToDouble();
                          _recalcTdee();
                        }),
                        onGoalChanged: (g) => setState(() => goal = g),
                        onGenderChanged: (g) => setState(() {
                          genderAtBirth = g;
                          _recalcTdee();
                        }),
                      ),
                      BudgetStep(
                        weeklyBudget: weeklyBudget,
                        onChanged: (v) => setState(() => weeklyBudget = v),
                      ),
                      NutritionStep(
                        modes: _nutritionModes,
                        selected: nutritionMode,
                        onSelect: (id) => setState(() => nutritionMode = id),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: ObsidianTokens.spacingMd),
                OnboardingNavBar(
                  showBack: step > 0,
                  loading: _finishing,
                  primaryLabel: step == totalSteps - 1 ? 'Finish' : 'Next',
                  primarySemanticsId: step == totalSteps - 1 ? 'onboard-finish' : 'onboard-next',
                  onBack: _back,
                  onPrimary: () => _tryNext(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
