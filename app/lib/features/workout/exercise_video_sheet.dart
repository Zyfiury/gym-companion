import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/user_data.dart';
import '../../providers/app_state.dart';
import '../../services/health_safety_service.dart';
import '../../services/youtube_service.dart';
import '../../core/widgets/app_toast.dart';
import '../../theme/app_theme.dart';
import '../../utils/sheet_padding.dart';

/// Shared exercise demo video sheet for Workout tab and detail screen.
Future<void> showExerciseVideoSheet(BuildContext context, String exerciseRaw) async {
  final state = context.read<AppState>();
  final user = state.user!;
  final safety = HealthSafetyService.checkWorkoutSafe(exerciseRaw, user);
  if (!safety.isSafe) {
    AppToast.error(context, safety.warning ?? 'Exercise adapted for your mobility');
    return;
  }

  final query = HealthSafetyService.videoSearchQuery(exerciseRaw, user);
  final cacheKey = HealthSafetyService.videoCacheKey(exerciseRaw, user);
  final video = await YouTubeService.searchExercise(query, cacheKey: cacheKey);
  if (!context.mounted) return;

  if (video == null) {
    final name = exerciseRaw.split(RegExp(r'\s+\d')).first.trim();
    AppToast.error(
      context,
      YouTubeService.hasKey ? 'No video found for $name' : 'Add YOUTUBE_API_KEY for exercise videos',
    );
    return;
  }

  final t = context.appTheme;
  final c = context.appColors;
  showModalBottomSheet(
    context: context,
    backgroundColor: t.card,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => Padding(
      padding: sheetInsets(ctx, horizontal: 20, top: 20, extra: 20),
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
              style: FilledButton.styleFrom(backgroundColor: c.primary, padding: const EdgeInsets.symmetric(vertical: 14)),
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
