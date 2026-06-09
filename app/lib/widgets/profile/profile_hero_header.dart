import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../staggered_entry.dart';

class ProfileHeroHeader extends StatelessWidget {
  final String displayName;
  final String goalLabel;
  final String statsLine;
  final bool profileComplete;
  final VoidCallback onEdit;

  const ProfileHeroHeader({
    super.key,
    required this.displayName,
    required this.goalLabel,
    required this.statsLine,
    required this.profileComplete,
    required this.onEdit,
  });

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'A';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Color _goalColor(String goal) => switch (goal.toLowerCase()) {
        'cut' => AppColors.hydro,
        'bulk' => AppColors.ember,
        _ => AppColors.volt,
      };

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final name = displayName.isNotEmpty ? displayName : 'Athlete';
    final goalColor = _goalColor(goalLabel);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 140,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.gradient.colors.first.withValues(alpha: 0.35),
                Colors.transparent,
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Column(
            children: [
              PulseGlow(
                size: 72,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: AppColors.warmGradient,
                    shape: BoxShape.circle,
                    border: Border.all(color: t.borderSubtle.withValues(alpha: 0.5), width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _initials(name),
                    style: GoogleFonts.dmSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                name,
                style: GoogleFonts.gloock(
                  fontSize: 26,
                  color: t.textPrimary,
                  letterSpacing: -0.5,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Text(statsLine, style: TextStyle(fontSize: 13, color: t.textSecondary)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: goalColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: goalColor.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      goalLabel.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                        color: goalColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Semantics(
                    identifier: 'profile-edit-btn',
                    button: true,
                    child: PressableScale(
                      onTap: onEdit,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: t.elevated,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: t.borderSubtle),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit_outlined, size: 14, color: t.textSecondary),
                            const SizedBox(width: 6),
                            Text(
                              profileComplete ? 'Edit profile' : 'Finish setup',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: t.textPrimary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
