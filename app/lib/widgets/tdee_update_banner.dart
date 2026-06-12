import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../screens/profile/profile_screen.dart';
import '../widgets/page_transitions.dart';

class TdeeUpdateBanner extends StatelessWidget {
  const TdeeUpdateBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final update = state.pendingTdeeUpdate;
    if (update == null) return const SizedBox.shrink();
    final t = context.appTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            state.clearPendingTdeeUpdate();
            pushPremium(context, const ProfileScreen());
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.accent, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Your calorie target updated to ${update.newTarget} kcal based on your new weight. Tap to review.',
                    style: TextStyle(color: t.textPrimary, fontSize: 13),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 18, color: t.textMuted),
                  onPressed: state.clearPendingTdeeUpdate,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
