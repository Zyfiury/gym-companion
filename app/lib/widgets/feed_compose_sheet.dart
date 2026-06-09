import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

Future<void> showFeedComposeSheet(BuildContext context) {
  var postType = 'pr';
  final captionCtrl = TextEditingController();
  final motivationCtrl = TextEditingController();
  final state = context.read<AppState>();
  final u = state.user!;

  String? prText;
  if (u.personalRecords.isNotEmpty) {
    final pr = u.personalRecords.first;
    prText = '${pr['exercise']} — ${pr['value']}${pr['unit'] ?? 'kg'}';
  }

  String? mealText;
  if (u.weeklyPlan.meals.isNotEmpty) {
    final meal = u.weeklyPlan.meals.first;
    mealText = '${meal.name} — ${meal.macros['calories']} kcal';
  }

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.appTheme.card,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Share with the community', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: ctx.appTheme.textPrimary)),
            const SizedBox(height: 16),
            _typeCard(ctx, setLocal, 'pr', Icons.emoji_events, 'Personal Record', prText ?? 'No PRs yet', postType, () => postType = 'pr'),
            const SizedBox(height: 8),
            _typeCard(ctx, setLocal, 'meal', Icons.restaurant, 'Meal', mealText ?? 'No meals today', postType, () => postType = 'meal'),
            const SizedBox(height: 8),
            Semantics(
              identifier: 'feed-post-type-motivation',
              button: true,
              child: _typeCard(ctx, setLocal, 'motivation', Icons.chat_bubble_outline, 'Motivation tip', 'Share advice (max 280 chars)', postType, () => postType = 'motivation'),
            ),
            const SizedBox(height: 16),
            if (postType == 'motivation')
              Semantics(
                identifier: 'feed-post-input',
                child: TextField(
                  controller: motivationCtrl,
                  maxLength: 280,
                  maxLines: 3,
                  decoration: const InputDecoration(hintText: 'Your motivation tip...'),
                ),
              )
            else
              TextField(controller: captionCtrl, decoration: const InputDecoration(hintText: 'Caption (optional)')),
            const SizedBox(height: 8),
            Text('+10 XP for posting', style: TextStyle(fontSize: 12, color: ctx.appTheme.textSecondary)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: Semantics(
                identifier: 'feed-post-submit',
                button: true,
                child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
                onPressed: () async {
                  String content;
                  Map<String, dynamic>? structured;
                  if (postType == 'pr') {
                    content = prText ?? 'New personal record!';
                    structured = {'exercise': u.personalRecords.isNotEmpty ? u.personalRecords.first['exercise'] : '', 'value': prText};
                  } else if (postType == 'meal') {
                    final meal = u.weeklyPlan.meals.isNotEmpty ? u.weeklyPlan.meals.first : null;
                    content = mealText ?? 'Great meal today!';
                    structured = meal != null ? {'name': meal.name, 'calories': meal.macros['calories'], 'protein': meal.macros['protein']} : null;
                  } else {
                    content = motivationCtrl.text.trim();
                    if (content.isEmpty) return;
                  }
                  await ctx.read<AppState>().addFeedPost(
                        content,
                        postType: postType,
                        structuredContent: structured,
                        caption: captionCtrl.text.trim().isEmpty ? null : captionCtrl.text.trim(),
                      );
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Posted! +10 XP earned')));
                  }
                },
                child: const Text('Post'),
              ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _typeCard(BuildContext ctx, StateSetter setLocal, String id, IconData icon, String title, String subtitle, String selected, VoidCallback onSelect) {
  final active = selected == id;
  final t = ctx.appTheme;
  return InkWell(
    onTap: () => setLocal(onSelect),
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: active ? AppColors.accent : t.borderSubtle),
        color: active ? AppColors.accent.withValues(alpha: 0.08) : t.elevated,
      ),
      child: Row(
        children: [
          Icon(icon, color: active ? AppColors.accent : t.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: t.textPrimary)),
                Text(subtitle, style: TextStyle(fontSize: 12, color: t.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
