import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_data.dart';
import '../../providers/app_state.dart';
import '../../services/subscription_service.dart';
import '../../services/workout_adaptation_service.dart';
import '../../services/youtube_service.dart';
import '../../theme/app_theme.dart';
import '../../services/tdee_service.dart';
import '../../widgets/pro_badge.dart';
import '../../widgets/profile/profile_pill_tabs.dart';
import '../../widgets/staggered_entry.dart';
import 'profile_account_tab.dart';
import 'profile_edit_sheet.dart';
import 'profile_health_tab.dart';
import 'profile_nutrition_tab.dart';
import 'profile_you_tab.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _tabIndex = 0;
  late String goal;
  late double weight, height, weeklyBudget;
  late int age, tdee;
  late String nutritionMode, dietaryRestrictions, dietType, mealVariety, genderAtBirth;
  late Set<String> allergies, disabilities;
  late bool pregnant, tracksPeriod;
  late String? periodPhase;
  late final TextEditingController _favCtrl;
  late List<String> _initialDisabilities;
  late bool _initialPregnant;
  late String _initialGender;

  @override
  void initState() {
    super.initState();
    _favCtrl = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _favCtrl.dispose();
    super.dispose();
  }

  void _load() {
    final u = context.read<AppState>().user!;
    goal = u.goal;
    weight = u.weight;
    height = u.height;
    age = u.age;
    tdee = u.tdee;
    weeklyBudget = u.weeklyBudget;
    nutritionMode = u.nutritionMode;
    dietaryRestrictions = u.dietaryRestrictions;
    dietType = u.dietType;
    mealVariety = u.mealVariety;
    allergies = Set<String>.from(u.allergies);
    genderAtBirth = u.genderAtBirth;
    disabilities = Set<String>.from(u.disabilities);
    pregnant = u.pregnant;
    tracksPeriod = u.tracksPeriod;
    periodPhase = u.periodPhase;
    _initialDisabilities = List<String>.from(u.disabilities);
    _initialPregnant = u.pregnant;
    _initialGender = u.genderAtBirth;
  }

  bool _healthProfileChanged() {
    if (_initialPregnant != pregnant) return true;
    if (_initialGender != genderAtBirth) return true;
    if (_initialDisabilities.length != disabilities.length) return true;
    return !_initialDisabilities.every(disabilities.contains);
  }

  void _rebuildWorkoutPlan(UserData u) {
    final plan = WorkoutAdaptationService.buildWeeklyPlan(u);
    u.weeklyPlan = WeeklyPlan(
      macros: u.weeklyPlan.macros,
      workouts: plan.workouts,
      meals: u.weeklyPlan.meals,
      shoppingList: u.weeklyPlan.shoppingList,
      deliveryOptions: u.weeklyPlan.deliveryOptions,
    );
  }

  Future<void> _save() async {
    final base = TdeeService.calculateTdee(
      weightKg: weight,
      heightCm: height,
      age: age,
      genderAtBirth: genderAtBirth,
    );
    tdee = TdeeService.applyGoalOffset(base, goal);
    final healthChanged = _healthProfileChanged();
    await context.read<AppState>().patchUser((u) {
      u.goal = goal;
      u.weight = weight;
      u.height = height;
      u.age = age;
      u.tdee = tdee;
      u.weeklyPlan = WeeklyPlan(
        macros: TdeeService.deriveMacros(calories: tdee, weightKg: weight),
        workouts: u.weeklyPlan.workouts,
        meals: u.weeklyPlan.meals,
        shoppingList: u.weeklyPlan.shoppingList,
        deliveryOptions: u.weeklyPlan.deliveryOptions,
      );
      u.weeklyBudget = weeklyBudget;
      u.nutritionMode = nutritionMode;
      u.dietaryRestrictions = dietaryRestrictions;
      u.dietType = dietType;
      u.mealVariety = mealVariety;
      u.allergies = allergies.toList();
      u.genderAtBirth = genderAtBirth;
      u.disabilities = disabilities.toList();
      u.pregnant = pregnant;
      u.tracksPeriod = tracksPeriod;
      u.periodPhase = periodPhase;
      if (healthChanged) _rebuildWorkoutPlan(u);
    });
    if (healthChanged) {
      await YouTubeService.clearExerciseCache();
      _initialDisabilities = disabilities.toList();
      _initialPregnant = pregnant;
      _initialGender = genderAtBirth;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile saved ✓')));
    }
  }

  Future<void> _openEditSheet() async {
    await ProfileEditSheet.show(
      context,
      goal: goal,
      weight: weight,
      height: height,
      age: age,
      tdee: tdee,
      weeklyBudget: weeklyBudget,
      nutritionMode: nutritionMode,
      dietaryRestrictions: dietaryRestrictions,
      genderAtBirth: genderAtBirth,
      onSave: ({
        required String goal,
        required double weight,
        required double height,
        required int age,
        required int tdee,
        required double weeklyBudget,
        required String nutritionMode,
        required String dietaryRestrictions,
      }) async {
        setState(() {
          this.goal = goal;
          this.weight = weight;
          this.height = height;
          this.age = age;
          this.tdee = tdee;
          this.weeklyBudget = weeklyBudget;
          this.nutritionMode = nutritionMode;
          this.dietaryRestrictions = dietaryRestrictions;
        });
        await _save();
        if (!mounted) return;
        if (nutritionMode == 'home_delivery' || nutritionMode == 'eat_out') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Open the Food tab to find options near you')),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final state = context.watch<AppState>();
    final u = state.user!;

    return Scaffold(
      backgroundColor: t.scaffold,
      appBar: AppBar(
        backgroundColor: t.scaffold,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: t.textPrimary),
        title: Text('Profile', style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w600, fontSize: 17)),
        actions: [
          FutureBuilder<bool>(
            future: SubscriptionService.isPro(),
            builder: (context, snap) {
              if (snap.data == true) return const SizedBox.shrink();
              return const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Center(child: ProBadge(compact: true)),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: ProfilePillTabs(index: _tabIndex, onChanged: (i) => setState(() => _tabIndex = i)),
        ),
      ),
      body: AmbientBackground(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0.03, 0), end: Offset.zero).animate(animation),
                child: child,
              ),
            );
          },
          child: KeyedSubtree(
            key: ValueKey(_tabIndex),
            child: _buildTab(u, state.displayName ?? 'Athlete'),
          ),
        ),
      ),
    );
  }

  Widget _buildTab(UserData u, String displayName) {
    switch (_tabIndex) {
      case 0:
        return ProfileYouTab(
          user: u,
          displayName: displayName,
          onEdit: _openEditSheet,
          onAvatarTap: () async {
            final updated = await context.read<AppState>().updateAvatar(context);
            if (updated && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile photo updated ✓')));
            }
          },
        );
      case 1:
        return ProfileNutritionTab(
          allergies: allergies,
          dietType: dietType,
          mealVariety: mealVariety,
          favouriteMeals: u.favouriteMeals,
          favCtrl: _favCtrl,
          onAllergiesChanged: (v) => setState(() => allergies = v),
          onDietTypeChanged: (v) => setState(() => dietType = v),
          onMealVarietyChanged: (v) => setState(() => mealVariety = v),
          onAddFavourite: () {
            if (_favCtrl.text.isEmpty) return;
            context.read<AppState>().patchUser((user) {
              user.favouriteMeals.add({'name': _favCtrl.text, 'savedAt': DateTime.now().millisecondsSinceEpoch});
            });
            _favCtrl.clear();
          },
          onRemoveFavourite: (m) => context.read<AppState>().patchUser((user) => user.favouriteMeals.remove(m)),
          onSave: _save,
        );
      case 2:
        return ProfileHealthTab(
          genderAtBirth: genderAtBirth,
          disabilities: disabilities,
          pregnant: pregnant,
          tracksPeriod: tracksPeriod,
          periodPhase: periodPhase,
          onGenderChanged: (v) => setState(() {
            genderAtBirth = v;
          }),
          onDisabilitiesChanged: (v) => setState(() => disabilities = v),
          onPregnantChanged: (v) => setState(() => pregnant = v),
          onTracksPeriodChanged: (v) => setState(() => tracksPeriod = v),
          onPeriodPhaseChanged: (v) => setState(() => periodPhase = v),
          onSave: _save,
        );
      default:
        return ProfileAccountTab(user: u, displayName: displayName);
    }
  }
}
