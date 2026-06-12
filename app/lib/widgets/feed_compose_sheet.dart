import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/xp_rewards.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/sheet_padding.dart';

Future<void> showFeedComposeSheet(
  BuildContext context, {
  String? initialPostType,
  String? initialActivityId,
  String? initialContent,
}) {
  var postType = initialPostType ?? 'general';
  String? activityId = initialActivityId;
  String? activityCollection;
  final captionCtrl = TextEditingController();
  final contentCtrl = TextEditingController(text: initialContent ?? '');
  final state = context.read<AppState>();
  final u = state.user!;

  String workoutLabel = 'No workout logged today';
  if (state.todayWorkoutSessionId != null) {
    workoutLabel = '${state.todayWorkoutName ?? 'Workout'} — ${state.todayWorkoutStatus.name}';
  }

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.appTheme.card,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) {
        String xpHint() {
          if (postType == 'general' || postType == 'progress') return '+${XpRewards.feedGeneral} XP';
          if (activityId == null) return 'Link an activity for +${XpRewards.feedLinked} XP';
          return postType == 'pr' ? '+${XpRewards.feedPrShare} XP (linked PR)' : '+${XpRewards.feedLinked} XP (linked)';
        }

        return Padding(
          padding: sheetInsets(ctx),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  identifier: 'feed-compose-title',
                  child: Text('Share with the community', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: ctx.appTheme.textPrimary)),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    _chip(ctx, setLocal, 'workout', postType, () => postType = 'workout'),
                    _chip(ctx, setLocal, 'meal', postType, () => postType = 'meal'),
                    _chip(ctx, setLocal, 'pr', postType, () => postType = 'pr'),
                    _chip(ctx, setLocal, 'progress', postType, () => postType = 'progress'),
                    _chip(ctx, setLocal, 'general', postType, () => postType = 'general'),
                  ],
                ),
                const SizedBox(height: 12),
                if (postType == 'workout' || postType == 'meal' || postType == 'pr') ...[
                  Text('Quick link', style: TextStyle(fontSize: 12, color: ctx.appTheme.textSecondary)),
                  const SizedBox(height: 8),
                  if (postType == 'workout')
                    _linkBtn(ctx, setLocal, "Link today's workout", workoutLabel, 'feed-link-workout', () {
                      activityId = state.todayWorkoutSessionId;
                      activityCollection = 'workout_sessions';
                      if (activityId != null) contentCtrl.text = 'Completed ${state.todayWorkoutName ?? 'workout'} today 💪';
                    }),
                  if (postType == 'meal' && state.todayFoodEntries.isNotEmpty)
                    ...state.todayFoodEntries.map((entry) => _linkBtn(
                          ctx,
                          setLocal,
                          entry['food'] as String? ?? 'Meal',
                          '${entry['calories']} kcal',
                          'feed-link-meal-${entry['id']}',
                          () {
                            activityId = entry['id'] as String?;
                            activityCollection = 'food_entries';
                            contentCtrl.text = 'Logged ${entry['food']} — ${entry['calories']} kcal';
                          },
                        )),
                  if (postType == 'pr' && u.personalRecords.isNotEmpty)
                    ...u.personalRecords.take(3).map((pr) => _linkBtn(
                          ctx,
                          setLocal,
                          pr['exercise'] as String? ?? 'PR',
                          '${pr['value']}${pr['unit'] ?? 'kg'}',
                          'feed-link-pr-${pr['id']}',
                          () {
                            activityId = pr['id'] as String?;
                            activityCollection = 'personal_records';
                            contentCtrl.text = 'New PR 🏋️ ${pr['exercise']} — ${pr['value']}${pr['unit'] ?? 'kg'}';
                          },
                        )),
                  const SizedBox(height: 8),
                ],
                Semantics(
                  identifier: 'feed-post-input',
                  textField: true,
                  child: TextField(
                    controller: contentCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(hintText: 'What do you want to share?'),
                  ),
                ),
                TextField(controller: captionCtrl, decoration: const InputDecoration(hintText: 'Caption (optional)')),
                Semantics(
                  identifier: 'feed-xp-hint',
                  child: Text(xpHint(), style: TextStyle(fontSize: 12, color: ctx.appTheme.textSecondary)),
                ),
                const SizedBox(height: 12),
                Semantics(
                  identifier: 'feed-post-submit',
                  button: true,
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
                      onPressed: () async {
                        final content = contentCtrl.text.trim();
                        if (content.isEmpty) return;
                        final needsLink = postType == 'workout' || postType == 'meal' || postType == 'pr';
                        if (needsLink && (activityId == null || activityId!.isEmpty)) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('Link an activity to earn linked post XP')),
                          );
                          return;
                        }
                        await ctx.read<AppState>().addFeedPost(
                              content,
                              postType: postType,
                              caption: captionCtrl.text.trim().isEmpty ? null : captionCtrl.text.trim(),
                              activityId: activityId,
                              activityCollection: activityCollection,
                            );
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Posted!')));
                        }
                      },
                      child: const Text('Post'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

Widget _chip(BuildContext ctx, StateSetter setLocal, String id, String selected, VoidCallback onSelect) {
  final active = selected == id;
  return Semantics(
    identifier: 'feed-post-type-$id',
    button: true,
    child: ChoiceChip(
      label: Text(id[0].toUpperCase() + id.substring(1)),
      selected: active,
      onSelected: (_) => setLocal(onSelect),
    ),
  );
}

Widget _linkBtn(
  BuildContext ctx,
  StateSetter setLocal,
  String title,
  String subtitle,
  String semanticsId,
  VoidCallback onTap,
) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Semantics(
      identifier: semanticsId,
      button: true,
      child: OutlinedButton(
        onPressed: () => setLocal(onTap),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(subtitle, style: TextStyle(fontSize: 12, color: ctx.appTheme.textSecondary)),
            ],
          ),
        ),
      ),
    ),
  );
}
