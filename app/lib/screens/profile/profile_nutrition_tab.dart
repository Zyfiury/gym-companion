import 'package:flutter/material.dart';
import '../../services/allergy_guard.dart';
import '../../theme/app_theme.dart';
import '../../utils/sheet_padding.dart';
import '../../widgets/onboarding/onboarding_chip.dart';
import '../../widgets/premium_ui.dart';
import '../../widgets/profile/profile_glass_card.dart';
import '../../widgets/profile/profile_save_bar.dart';
import '../../widgets/staggered_entry.dart';

class ProfileNutritionTab extends StatelessWidget {
  final Set<String> allergies;
  final String dietType;
  final String mealVariety;
  final bool splitCaloriesEnabled;
  final int trainingDayCalories;
  final int restDayCalories;
  final List<Map<String, dynamic>> favouriteMeals;
  final TextEditingController favCtrl;
  final ValueChanged<Set<String>> onAllergiesChanged;
  final ValueChanged<String> onDietTypeChanged;
  final ValueChanged<String> onMealVarietyChanged;
  final ValueChanged<bool> onSplitCaloriesChanged;
  final VoidCallback onAddFavourite;
  final void Function(Map<String, dynamic> meal) onRemoveFavourite;
  final VoidCallback onSave;

  const ProfileNutritionTab({
    super.key,
    required this.allergies,
    required this.dietType,
    required this.mealVariety,
    required this.splitCaloriesEnabled,
    required this.trainingDayCalories,
    required this.restDayCalories,
    required this.favouriteMeals,
    required this.favCtrl,
    required this.onAllergiesChanged,
    required this.onDietTypeChanged,
    required this.onMealVarietyChanged,
    required this.onSplitCaloriesChanged,
    required this.onAddFavourite,
    required this.onRemoveFavourite,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final allergyItems = AllergyGuard.allAllergenOptions
        .map((a) => OnboardingChipItem(
              id: a,
              label: a.replaceAll('_', ' '),
              selected: allergies.contains(a),
              semanticsId: 'prefs-allergy-$a',
            ))
        .toList();

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, 8, 16, scrollBottomInset(context, extra: 80)),
            children: [
              StaggeredEntry(
                index: 0,
                child: ProfileGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        identifier: 'prefs-title',
                        child: Text('Food preferences', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: t.textPrimary)),
                      ),
                      const SizedBox(height: 16),
                      SectionLabel('Allergies'),
                      const SizedBox(height: 10),
                      OnboardingChipGrid(
                        items: allergyItems,
                        onToggle: (id) {
                          final next = Set<String>.from(allergies);
                          if (next.contains(id)) {
                            next.remove(id);
                          } else {
                            next.add(id);
                          }
                          onAllergiesChanged(next);
                        },
                      ),
                      const SizedBox(height: 20),
                      SectionLabel('Diet type'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: dietType,
                        decoration: const InputDecoration(labelText: 'Diet type'),
                        items: const [
                          DropdownMenuItem(value: 'omnivore', child: Text('Omnivore')),
                          DropdownMenuItem(value: 'vegetarian', child: Text('Vegetarian')),
                          DropdownMenuItem(value: 'vegan', child: Text('Vegan')),
                        ],
                        onChanged: (v) {
                          if (v != null) onDietTypeChanged(v);
                        },
                      ),
                      const SizedBox(height: 20),
                      SectionLabel('Calorie targets'),
                      const SizedBox(height: 8),
                      Text(
                        'Training day: $trainingDayCalories kcal · Rest day: $restDayCalories kcal',
                        style: TextStyle(fontSize: 13, color: t.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Split rest/training calories', style: TextStyle(fontSize: 14, color: t.textPrimary)),
                        value: splitCaloriesEnabled,
                        onChanged: onSplitCaloriesChanged,
                      ),
                      const SizedBox(height: 12),
                      SectionLabel('Meal variety'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: mealVariety,
                        decoration: const InputDecoration(labelText: 'Meal variety'),
                        items: const [
                          DropdownMenuItem(value: 'rotate', child: Text('Rotate')),
                          DropdownMenuItem(value: 'favourites_first', child: Text('Favourites first')),
                          DropdownMenuItem(value: 'adventurous', child: Text('Adventurous')),
                        ],
                        onChanged: (v) {
                          if (v != null) onMealVarietyChanged(v);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              StaggeredEntry(
                index: 1,
                child: ProfileGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Favourite meals', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: t.textPrimary)),
                      const SizedBox(height: 12),
                      OnboardingBottomLineInput(
                        controller: favCtrl,
                        hint: 'Meal name',
                        onSubmit: onAddFavourite,
                      ),
                      if (favouriteMeals.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: favouriteMeals.map((m) {
                            return InputChip(
                              label: Text('${m['name']}'),
                              deleteIcon: const Icon(Icons.close_rounded, size: 16),
                              onDeleted: () => onRemoveFavourite(m),
                              backgroundColor: t.chipBg,
                              side: BorderSide(color: t.borderSubtle),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        ProfileSaveBar(label: 'Save preferences', onSave: onSave, semanticsId: 'profile-save-nutrition'),
      ],
    );
  }
}
