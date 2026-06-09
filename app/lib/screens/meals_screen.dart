import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/user_data.dart';
import '../providers/app_state.dart';
import '../services/grocery_service.dart';
import '../services/meal_variety_service.dart';
import '../services/youtube_service.dart';
import '../theme/app_theme.dart';
import '../utils/pro_gate.dart';
import '../widgets/meal_month_chart.dart';
import '../widgets/meal_week_view.dart';
import '../widgets/meals/nutrition_mode_panel.dart';
import '../widgets/premium_ui.dart';
import '../widgets/shimmer_skeleton.dart';
import '../widgets/staggered_entry.dart';

enum _PlanView { day, week, month }

class MealsScreen extends StatefulWidget {
  const MealsScreen({super.key});

  @override
  State<MealsScreen> createState() => _MealsScreenState();
}

class _MealsScreenState extends State<MealsScreen> {
  int openMeal = 0;
  _PlanView planView = _PlanView.day;
  bool deliveryOpen = false;
  bool shopOpen = false;
  String? _videoId;
  String? _videoThumb;
  bool _loadingVideo = false;

  List<Meal> _mealsForView(AppState state) {
    final u = state.user!;
    switch (planView) {
      case _PlanView.month:
        if (u.monthlyPlan != null && u.monthlyPlan!.meals.isNotEmpty) {
          return u.monthlyPlan!.meals;
        }
        return u.weeklyPlan.meals;
      case _PlanView.week:
        if (u.monthlyPlan != null && u.monthlyPlan!.meals.length >= 21) {
          return u.monthlyPlan!.meals.take(21).toList();
        }
        return u.weeklyPlan.meals.length > 3 ? u.weeklyPlan.meals : u.weeklyPlan.meals;
      case _PlanView.day:
        return u.weeklyPlan.meals.take(3).toList();
    }
  }

  Map<String, dynamic>? _shoppingForView(AppState state) {
    final u = state.user!;
    if (planView == _PlanView.month && u.monthlyPlan?.shoppingList != null) {
      return u.monthlyPlan!.shoppingList;
    }
    return state.user!.weeklyPlan.shoppingList;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadVideo());
  }

  Future<void> _onPlanViewChanged(_PlanView v) async {
    if (v == _PlanView.week) {
      if (!await ProGate.check(context, feature: 'food_week')) return;
    } else if (v == _PlanView.month) {
      if (!await ProGate.check(context, feature: 'food_month')) return;
    }
    setState(() {
      planView = v;
      openMeal = 0;
      _videoId = null;
      _videoThumb = null;
    });
    _loadVideo();
  }

  String _periodKey() {
    switch (planView) {
      case _PlanView.day:
        return 'day';
      case _PlanView.week:
        return 'week';
      case _PlanView.month:
        return 'month';
    }
  }

  String _nutritionLabel() {
    switch (planView) {
      case _PlanView.day:
        return 'Daily nutrition';
      case _PlanView.week:
        return 'Weekly average';
      case _PlanView.month:
        return 'Monthly average';
    }
  }

  Future<void> _confirmLogMeal(AppState state, Meal meal) async {
    final t = context.appTheme;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: t.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Log ${meal.name}?', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: t.textPrimary)),
            const SizedBox(height: 8),
            Text(
              '${meal.macros['calories']} kcal · P ${meal.macros['protein']}g · C ${meal.macros['carbs']}g · F ${meal.macros['fat']}g',
              style: TextStyle(fontSize: 13, color: t.textSecondary),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Log meal'),
              ),
            ),
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    final chip = await state.logMealFromPlan(meal);
    if (chip != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(chip)));
    }
  }

  Future<void> _loadVideo() async {
    final state = context.read<AppState>();
    final meals = _mealsForView(state);
    if (meals.isEmpty || openMeal >= meals.length) return;
    final meal = meals[openMeal];
    if (meal.youtubeVideoId != null) {
      setState(() {
        _videoId = meal.youtubeVideoId;
        _videoThumb = 'https://img.youtube.com/vi/${meal.youtubeVideoId}/mqdefault.jpg';
      });
      return;
    }
    setState(() => _loadingVideo = true);
    final enriched = await MealVarietyService.enrichWithVideo(meal);
    if (!mounted) return;
    if (enriched.youtubeVideoId != null) {
      final mealsList = List.from(state.user!.weeklyPlan.meals);
      mealsList[openMeal] = enriched;
      await state.patchUser((u) {
        u.weeklyPlan = WeeklyPlan(
          macros: u.weeklyPlan.macros,
          workouts: u.weeklyPlan.workouts,
          meals: mealsList.cast(),
          shoppingList: u.weeklyPlan.shoppingList,
          deliveryOptions: u.weeklyPlan.deliveryOptions,
        );
      });
    }
    setState(() {
      _loadingVideo = false;
      _videoId = enriched.youtubeVideoId;
      _videoThumb = enriched.youtubeVideoId != null ? 'https://img.youtube.com/vi/${enriched.youtubeVideoId}/mqdefault.jpg' : null;
    });
  }

  void _onMealChanged(int i) {
    setState(() {
      openMeal = i;
      _videoId = null;
      _videoThumb = null;
    });
    _loadVideo();
  }

  Future<void> _playRecipeVideo(String mealName) async {
    final video = _videoId != null
        ? ExerciseVideo(videoId: _videoId!, title: mealName, thumbnail: _videoThumb ?? '')
        : await YouTubeService.getRecipeVideo(mealName);
    if (!mounted) return;
    if (video == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(YouTubeService.hasKey ? 'No recipe video found' : 'Add YOUTUBE_API_KEY for cooking videos')),
      );
      return;
    }
    final t = context.appTheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: t.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(video.title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: t.textPrimary)),
            const SizedBox(height: 14),
            if (video.thumbnail.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(video.thumbnail, height: 160, width: double.infinity, fit: BoxFit.cover),
              ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: AppColors.accent, padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () => launchUrl(Uri.parse('https://youtube.com/watch?v=${video.videoId}'), mode: LaunchMode.externalApplication),
                icon: const Icon(Icons.play_circle_outline),
                label: const Text('Watch on YouTube'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final state = context.watch<AppState>();
    final plan = state.user!.weeklyPlan;
    final viewMeals = _mealsForView(state);
    final shoppingList = _shoppingForView(state);
    final macros = plan.macros;
    final logged = state.macrosForPeriod(_periodKey());
    final nutritionLabel = _nutritionLabel();
    final current = viewMeals.isNotEmpty && openMeal < viewMeals.length ? viewMeals[openMeal] : null;
    final calTarget = macros['calories'] ?? state.user!.tdee;
    final score = current != null ? MealVarietyService.nutritionScore(current.macros) : 0;

    return AmbientBackground(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          StaggeredEntry(
            index: 0,
            child: AppCard(
              child: Row(
                children: [
                  MacroRing(
                    progress: calTarget > 0 ? logged.calories / calTarget : 0,
                    value: '${logged.calories}',
                    label: 'kcal',
                    sublabel: '/ $calTarget',
                    color: AppColors.orange,
                    size: 100,
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(nutritionLabel, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: t.textPrimary)),
                        const SizedBox(height: 10),
                        MacroBar(label: 'Protein', current: logged.protein, target: macros['protein'] ?? 140, color: AppColors.accent),
                        const SizedBox(height: 8),
                        MacroBar(label: 'Carbs', current: logged.carbs, target: macros['carbs'] ?? 200, color: AppColors.blue),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (state.user!.nutritionMode != 'cook_myself') ...[
            const SizedBox(height: 14),
            StaggeredEntry(
              index: 1,
              child: NutritionModePanel(user: state.user!),
            ),
          ],
          const SizedBox(height: 14),
          if (planView == _PlanView.day)
            StaggeredEntry(
              index: 2,
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      identifier: 'meal-swap-btn',
                      button: true,
                      child: _ActionButton(icon: Icons.swap_horiz, label: 'Swap', onTap: current == null ? null : () async {
                        await state.swapMeal(current.mealType);
                        _onMealChanged(openMeal);
                      }),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Semantics(
                      identifier: 'meal-shuffle-btn',
                      button: true,
                      child: _ActionButton(
                        icon: Icons.shuffle,
                        label: 'Shuffle',
                        onTap: () async {
                          if (!await ProGate.check(context, feature: 'meal plans')) return;
                          await state.shuffleMeals();
                          _onMealChanged(0);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (planView == _PlanView.day) const SizedBox(height: 12),
          StaggeredEntry(
            index: 2,
            child: Semantics(
              identifier: 'food-plan-toggle',
              child: _PlanPeriodToggle(
                selected: planView,
                onChanged: _onPlanViewChanged,
              ),
            ),
          ),
          if (shoppingList != null && shoppingList['supermarket'] != null) ...[
            const SizedBox(height: 10),
            StaggeredEntry(
              index: 2,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${shoppingList['supermarket']} · ${shoppingList['totalEstimatedCost'] ?? ''}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accent),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (planView == _PlanView.week) ...[
            StaggeredEntry(
              index: 3,
              child: AppCard(child: MealWeekView(meals: viewMeals)),
            ),
          ] else if (planView == _PlanView.month) ...[
            StaggeredEntry(
              index: 3,
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Monthly trend', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: t.textPrimary)),
                    const SizedBox(height: 12),
                    MealMonthChart(
                      dailyLogs: state.dailyLogsHistory,
                      onDayTap: (date) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Logged on $date')));
                      },
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
          StaggeredEntry(
            index: 3,
            child: SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: viewMeals.length,
                separatorBuilder: (_, index) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final m = viewMeals[i];
                  final selected = openMeal == i;
                  return GestureDetector(
                    onTap: () => _onMealChanged(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.accent : t.elevated,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: selected ? AppColors.accent : t.borderSubtle),
                      ),
                      child: Text(m.mealType, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: selected ? Colors.white : t.textSecondary)),
                    ),
                  );
                },
              ),
            ),
          ),
          if (current != null) ...[
            const SizedBox(height: 16),
            StaggeredEntry(
              index: 3,
              child: AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      identifier: 'meal-video-btn',
                      button: true,
                      child: GestureDetector(
                        onTap: () => _playRecipeVideo(current.name),
                        child: Container(
                          height: (MediaQuery.sizeOf(context).width * 0.4).clamp(120.0, 180.0),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: t.elevated,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          child: _loadingVideo
                              ? const Padding(padding: EdgeInsets.all(16), child: MealCardSkeleton())
                              : _videoThumb != null
                                  ? Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        ClipRRect(
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                          child: Image.network(_videoThumb!, fit: BoxFit.cover),
                                        ),
                                        Center(
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), shape: BoxShape.circle),
                                            child: const Icon(Icons.play_arrow, color: Colors.white, size: 32),
                                          ),
                                        ),
                                      ],
                                    )
                                  : Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.restaurant_menu, size: 40, color: t.textMuted),
                                          const SizedBox(height: 8),
                                          Text('Tap to find cooking video', style: TextStyle(color: t.textSecondary, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Semantics(
                                  identifier: 'meal-detail-name',
                                  container: true,
                                  child: Text(current.name, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20, color: t.textPrimary)),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppColors.emerald.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text('Score $score', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.emerald)),
                              ),
                              if (state.user!.isMealLogged(current.mealType)) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: AppColors.emerald.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: AppColors.emerald.withValues(alpha: 0.3)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check_circle, size: 12, color: AppColors.emerald),
                                      SizedBox(width: 4),
                                      Text('Logged', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.emerald)),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(current.description, style: TextStyle(fontSize: 14, color: t.textSecondary)),
                          const SizedBox(height: 6),
                          Text('Portion: 1 serving (~${current.macros['calories']} kcal)', style: TextStyle(fontSize: 12, color: t.textMuted, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _MacroChip('Cal', '${current.macros['calories']}', compact: true),
                              _MacroChip('P', '${current.macros['protein']}g', compact: true),
                              _MacroChip('C', '${current.macros['carbs']}g', compact: true),
                              _MacroChip('F', '${current.macros['fat']}g', compact: true),
                            ],
                          ),
                          if (current.ingredients.isNotEmpty) ...[
                            const SizedBox(height: 18),
                            Text('Ingredients', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: t.textMuted)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: current.ingredients.map((ing) => Chip(
                                    label: Text(ing, style: TextStyle(fontSize: 11, color: t.textPrimary)),
                                    backgroundColor: t.elevated,
                                    side: BorderSide(color: t.borderSubtle),
                                    visualDensity: VisualDensity.compact,
                                  )).toList(),
                            ),
                          ],
                          if (current.steps.isNotEmpty) ...[
                            const SizedBox(height: 18),
                            Text('How to cook', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: t.textMuted)),
                            const SizedBox(height: 8),
                            ...current.steps.asMap().entries.map((e) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 22,
                                        height: 22,
                                        decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                                        child: Center(child: Text('${e.key + 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.accent))),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(child: Text(e.value, style: TextStyle(fontSize: 14, color: t.textPrimary))),
                                    ],
                                  ),
                                )),
                          ],
                          const SizedBox(height: 12),
                          if (!state.user!.isMealLogged(current.mealType))
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                style: FilledButton.styleFrom(backgroundColor: AppColors.accent, padding: const EdgeInsets.symmetric(vertical: 14)),
                                onPressed: () => _confirmLogMeal(state, current),
                                icon: const Icon(Icons.restaurant, size: 18),
                                label: const Text('Log meal'),
                              ),
                            ),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(foregroundColor: AppColors.accent, side: BorderSide(color: t.borderSubtle)),
                              onPressed: () => _playRecipeVideo(current.name),
                              icon: const Icon(Icons.play_circle_outline, size: 18),
                              label: const Text('Watch full recipe'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          ],
          if (plan.deliveryOptions != null && plan.deliveryOptions!.isNotEmpty) ...[
            const SizedBox(height: 20),
            StaggeredEntry(
              index: 4,
              child: _ExpandSection(
                icon: Icons.delivery_dining_outlined,
                title: 'Delivery nearby',
                subtitle: '${plan.deliveryOptions!.length} options · suggested dishes, est. macros',
                open: deliveryOpen,
                onToggle: (v) => setState(() => deliveryOpen = v),
                children: plan.deliveryOptions!.map((opt) => _DeliveryRow(opt: opt)).toList(),
              ),
            ),
          ],
          if (shoppingList != null) ...[
            const SizedBox(height: 12),
            StaggeredEntry(
              index: 5,
              child: _ExpandSection(
                icon: Icons.shopping_bag_outlined,
                title: shoppingList['supermarket'] as String? ?? 'Shopping',
                subtitle: shoppingList['estimated'] == true
                    ? '${shoppingList['totalEstimatedCost'] ?? ''} · estimated prices'
                    : shoppingList['totalEstimatedCost'] as String? ?? '',
                open: shopOpen,
                onToggle: (v) => setState(() => shopOpen = v),
                children: [
                  ...((shoppingList['items'] as List?) ?? []).map((item) {
                    final m = item as Map;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(child: Text('${m['item']} × ${m['quantity']}', style: TextStyle(fontSize: 14, color: t.textPrimary))),
                          Text('${m['price']}', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.accent)),
                        ],
                      ),
                    );
                  }),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.accent, side: BorderSide(color: t.borderSubtle)),
                      onPressed: () {
                        final items = ((shoppingList['items'] as List?) ?? []).map((e) => '${(e as Map)['item']}').cast<String>().toList();
                        final store = shoppingList['supermarket'] as String? ?? 'Tesco';
                        GroceryService.orderShoppingList(items, store: store);
                      },
                      icon: const Icon(Icons.shopping_cart_outlined, size: 18),
                      label: Text('Shop at ${shoppingList['supermarket'] ?? 'store'}'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String label, value;
  final bool highlight;
  final bool compact;

  const _MacroChip(this.label, this.value, {this.highlight = false, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    return Expanded(
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: compact ? 9 : 10, color: t.textMuted)),
          Text(value, style: TextStyle(fontWeight: FontWeight.w700, fontSize: compact ? 13 : 16, color: highlight ? AppColors.accent : t.textPrimary)),
        ],
      ),
    );
  }
}

class _PlanPeriodToggle extends StatelessWidget {
  final _PlanView selected;
  final ValueChanged<_PlanView> onChanged;

  const _PlanPeriodToggle({required this.selected, required this.onChanged});

  static const _tabs = [
    (_PlanView.day, 'Today'),
    (_PlanView.week, 'Week'),
    (_PlanView.month, 'Month'),
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: t.navBar,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.borderSubtle),
      ),
      child: Row(
        children: _tabs.map((tab) {
          final active = selected == tab.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(tab.$1),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? AppColors.accent.withValues(alpha: context.isDarkTheme ? 0.22 : 0.12) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  tab.$2,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active ? AppColors.accent : t.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ActionButton({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: t.borderSubtle)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: onTap == null ? t.textMuted : AppColors.accent),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: onTap == null ? t.textMuted : t.textPrimary)),
          ],
        ),
      ),
    );
  }
}

class _ExpandSection extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final bool open;
  final ValueChanged<bool> onToggle;
  final List<Widget> children;

  const _ExpandSection({required this.icon, required this.title, required this.subtitle, required this.open, required this.onToggle, required this.children});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: open,
          onExpansionChanged: onToggle,
          leading: Icon(icon, color: AppColors.accent, size: 22),
          title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: context.appTheme.textPrimary)),
          subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: context.appTheme.textSecondary)),
          children: children,
        ),
      ),
    );
  }
}

class _DeliveryRow extends StatelessWidget {
  final Map<String, dynamic> opt;
  const _DeliveryRow({required this.opt});

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    return ListTile(
      dense: true,
      title: Text(opt['restaurant'] as String? ?? '', style: TextStyle(fontWeight: FontWeight.w600, color: t.textPrimary)),
      subtitle: Text(
        opt['macrosEstimated'] == true
            ? 'Suggested: ${opt['dish']} — ${opt['macros']} (est.)'
            : opt['nutritionSource'] != null
                ? '${opt['dish']} — ${opt['macros']} (${opt['nutritionSource']})'
            : '${opt['dish']} — ${opt['macros']}',
        style: TextStyle(fontSize: 12, color: t.textSecondary),
      ),
      trailing: PopupMenuButton<String>(
        icon: Icon(Icons.open_in_new, size: 18, color: AppColors.accent),
        onSelected: (url) async {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
        },
        itemBuilder: (_) => [
          if (opt['uberEatsUrl'] != null) PopupMenuItem(value: opt['uberEatsUrl'] as String, child: const Text('Uber Eats')),
          if (opt['deliverooUrl'] != null) PopupMenuItem(value: opt['deliverooUrl'] as String, child: const Text('Deliveroo')),
          if (opt['justEatUrl'] != null) PopupMenuItem(value: opt['justEatUrl'] as String, child: const Text('Just Eat')),
        ],
      ),
    );
  }
}
