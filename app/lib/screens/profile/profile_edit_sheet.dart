import 'package:flutter/material.dart';
import '../../services/tdee_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/onboarding/custom_slider.dart';
import '../../widgets/onboarding/goal_card.dart';
import '../../widgets/onboarding/obsidian_shell.dart';
import '../../widgets/onboarding/progress_bar.dart';

class ProfileEditSheet extends StatefulWidget {
  final String goal;
  final double weight;
  final double height;
  final int age;
  final int tdee;
  final double weeklyBudget;
  final String nutritionMode;
  final String dietaryRestrictions;
  final String genderAtBirth;
  final Future<void> Function({
    required String goal,
    required double weight,
    required double height,
    required int age,
    required int tdee,
    required double weeklyBudget,
    required String nutritionMode,
    required String dietaryRestrictions,
  }) onSave;

  const ProfileEditSheet({
    super.key,
    required this.goal,
    required this.weight,
    required this.height,
    required this.age,
    required this.tdee,
    required this.weeklyBudget,
    required this.nutritionMode,
    required this.dietaryRestrictions,
    required this.genderAtBirth,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    required String goal,
    required double weight,
    required double height,
    required int age,
    required int tdee,
    required double weeklyBudget,
    required String nutritionMode,
    required String dietaryRestrictions,
    required String genderAtBirth,
    required Future<void> Function({
      required String goal,
      required double weight,
      required double height,
      required int age,
      required int tdee,
      required double weeklyBudget,
      required String nutritionMode,
      required String dietaryRestrictions,
    }) onSave,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ProfileEditSheet(
          goal: goal,
          weight: weight,
          height: height,
          age: age,
          tdee: tdee,
          weeklyBudget: weeklyBudget,
          nutritionMode: nutritionMode,
          dietaryRestrictions: dietaryRestrictions,
          genderAtBirth: genderAtBirth,
          onSave: onSave,
        ),
      ),
    );
  }

  @override
  State<ProfileEditSheet> createState() => _ProfileEditSheetState();
}

class _ProfileEditSheetState extends State<ProfileEditSheet> {
  int _step = 0;
  late String _goal;
  late double _weight;
  late double _height;
  late int _age;
  late int _tdee;
  late double _weeklyBudget;
  late String _nutritionMode;
  late String _dietaryRestrictions;
  late final TextEditingController _ageCtrl;
  late final TextEditingController _budgetCtrl;
  late final TextEditingController _dietaryCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _goal = widget.goal;
    _weight = widget.weight;
    _height = widget.height;
    _age = widget.age;
    _tdee = widget.tdee;
    _weeklyBudget = widget.weeklyBudget;
    _nutritionMode = widget.nutritionMode;
    _dietaryRestrictions = widget.dietaryRestrictions;
    _ageCtrl = TextEditingController(text: _age.toString());
    _budgetCtrl = TextEditingController(text: _weeklyBudget.toString());
    _dietaryCtrl = TextEditingController(text: _dietaryRestrictions);
  }

  @override
  void dispose() {
    _ageCtrl.dispose();
    _budgetCtrl.dispose();
    _dietaryCtrl.dispose();
    super.dispose();
  }

  void _recalcTdee() {
    _age = int.tryParse(_ageCtrl.text) ?? _age;
    final base = TdeeService.calculateTdee(
      weightKg: _weight,
      heightCm: _height,
      age: _age,
      genderAtBirth: widget.genderAtBirth,
    );
    _tdee = TdeeService.applyGoalOffset(base, _goal);
    setState(() {});
  }

  CaloriePlan get _plan => TdeeService.plan(
        weightKg: _weight,
        heightCm: _height,
        age: _age,
        goal: _goal,
        genderAtBirth: widget.genderAtBirth,
      );

  Future<void> _handleSave() async {
    setState(() => _saving = true);
    _recalcTdee();
    _weeklyBudget = double.tryParse(_budgetCtrl.text) ?? _weeklyBudget;
    _dietaryRestrictions = _dietaryCtrl.text;
    await widget.onSave(
      goal: _goal,
      weight: _weight,
      height: _height,
      age: _age,
      tdee: _tdee,
      weeklyBudget: _weeklyBudget,
      nutritionMode: _nutritionMode,
      dietaryRestrictions: _dietaryRestrictions,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return ObsidianShell(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, color: ObsidianTokens.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Edit profile',
            style: ObsidianTypography.display(size: 18, weight: FontWeight.w700),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: ObsidianTokens.spacingLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OnboardingProgressBar(step: _step, total: 3),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(ObsidianTokens.spacingLg),
                  children: [
                    if (_step == 0) ...[
                      ObsidianStepHeader(
                        category: 'Goals',
                        title: 'Your goal',
                        subtitle: 'Choose what you are working toward.',
                        index: 0,
                      ),
                      const SizedBox(height: ObsidianTokens.spacingLg),
                      GoalCard(
                        title: 'Cut',
                        descriptor: 'lose fat',
                        icon: Icons.trending_down_rounded,
                        selected: _goal == 'cut',
                        semanticsId: 'profile-goal-cut',
                        animIndex: 0,
                        onTap: () => setState(() {
                          _goal = 'cut';
                          _recalcTdee();
                        }),
                      ),
                      const SizedBox(height: ObsidianTokens.spacingSm),
                      GoalCard(
                        title: 'Bulk',
                        descriptor: 'build muscle',
                        icon: Icons.fitness_center_rounded,
                        selected: _goal == 'bulk',
                        semanticsId: 'profile-goal-bulk',
                        animIndex: 1,
                        onTap: () => setState(() {
                          _goal = 'bulk';
                          _recalcTdee();
                        }),
                      ),
                      const SizedBox(height: ObsidianTokens.spacingSm),
                      GoalCard(
                        title: 'Maintain',
                        descriptor: 'stay steady',
                        icon: Icons.balance_rounded,
                        selected: _goal == 'maintain',
                        semanticsId: 'profile-goal-maintain',
                        animIndex: 2,
                        onTap: () => setState(() {
                          _goal = 'maintain';
                          _recalcTdee();
                        }),
                      ),
                    ],
                    if (_step == 1) ...[
                      ObsidianStepHeader(
                        category: 'Body',
                        title: 'Your measurements',
                        subtitle: 'Used to calculate your daily calorie target.',
                        index: 1,
                      ),
                      const SizedBox(height: ObsidianTokens.spacingLg),
                      ObsidianSlider(
                        label: 'WEIGHT',
                        value: _weight,
                        min: 45,
                        max: 130,
                        divisions: 85,
                        labelFor: (v) => '${v.round()} kg',
                        onChanged: (v) => setState(() {
                          _weight = v;
                          _recalcTdee();
                        }),
                      ),
                      const SizedBox(height: ObsidianTokens.spacingMd),
                      ObsidianSlider(
                        label: 'HEIGHT',
                        value: _height,
                        min: 140,
                        max: 210,
                        divisions: 70,
                        labelFor: (v) => '${v.round()} cm',
                        onChanged: (v) => setState(() {
                          _height = v;
                          _recalcTdee();
                        }),
                      ),
                      const SizedBox(height: ObsidianTokens.spacingLg),
                      TextField(
                        controller: _ageCtrl,
                        keyboardType: TextInputType.number,
                        style: ObsidianTypography.body(color: ObsidianTokens.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Age',
                          labelStyle: ObsidianTypography.label(),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: ObsidianTokens.glassBorder),
                          ),
                        ),
                        onChanged: (_) => _recalcTdee(),
                      ),
                    ],
                    if (_step == 2) ...[
                      ObsidianStepHeader(
                        category: 'Nutrition',
                        title: 'Your targets',
                        subtitle: 'Calories and budget for meal planning.',
                        index: 2,
                      ),
                      const SizedBox(height: ObsidianTokens.spacingLg),
                      Center(
                        child: TdeeHeroDisplay(
                          value: _tdee,
                          unit: 'kcal / day',
                          subtitle: TdeeService.planSubtitle(_plan),
                          semanticsId: 'profile-tdee-preview',
                        ),
                      ),
                      const SizedBox(height: ObsidianTokens.spacingLg),
                      TextField(
                        controller: _budgetCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: ObsidianTypography.body(color: ObsidianTokens.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Weekly budget (£)',
                          labelStyle: ObsidianTypography.label(),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: ObsidianTokens.glassBorder),
                          ),
                        ),
                      ),
                      const SizedBox(height: ObsidianTokens.spacingMd),
                      DropdownButtonFormField<String>(
                        value: _nutritionMode,
                        dropdownColor: ObsidianTokens.surfaceDark,
                        style: ObsidianTypography.body(color: ObsidianTokens.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Nutrition mode',
                          labelStyle: ObsidianTypography.label(),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: ObsidianTokens.glassBorder),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'cook_myself', child: Text('Cook myself')),
                          DropdownMenuItem(value: 'home_delivery', child: Text('Home delivery')),
                          DropdownMenuItem(value: 'eat_out', child: Text('Eat out')),
                        ],
                        onChanged: (v) => setState(() => _nutritionMode = v ?? _nutritionMode),
                      ),
                      const SizedBox(height: ObsidianTokens.spacingMd),
                      TextField(
                        controller: _dietaryCtrl,
                        style: ObsidianTypography.body(color: ObsidianTokens.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Dietary restrictions',
                          labelStyle: ObsidianTypography.label(),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: ObsidianTokens.glassBorder),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(ObsidianTokens.spacingLg),
                child: Row(
                  children: [
                    if (_step > 0)
                      TextButton(
                        onPressed: _saving ? null : () => setState(() => _step--),
                        child: Text('Back', style: ObsidianTypography.body(color: ObsidianTokens.textMuted)),
                      ),
                    const Spacer(),
                    if (_step < 2)
                      GradientButton(
                        label: 'Next',
                        onPressed: _saving ? null : () => setState(() => _step++),
                      )
                    else
                      GradientButton(
                        label: _saving ? 'Saving…' : 'Save profile',
                        onPressed: _saving ? null : _handleSave,
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
