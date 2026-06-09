import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class ProfilePillTabs extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;

  static const _labels = ['You', 'Nutrition', 'Health', 'Account'];
  static const _semanticsIds = [
    'profile-tab-you',
    'profile-tab-nutrition',
    'profile-tab-health',
    'profile-tab-account',
  ];

  const ProfilePillTabs({
    super.key,
    required this.index,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: t.inputFill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: t.borderSubtle.withValues(alpha: 0.6)),
        ),
        child: Row(
          children: List.generate(_labels.length, (i) {
            final active = index == i;
            return Expanded(
              child: Semantics(
                identifier: _semanticsIds[i],
                button: true,
                selected: active,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onChanged(i),
                    borderRadius: BorderRadius.circular(10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: active
                            ? (context.isDarkTheme ? AppColors.surfaceElevated : Colors.white)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: active && !context.isDarkTheme
                            ? [BoxShadow(color: t.shadow, blurRadius: 8, offset: const Offset(0, 2))]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _labels[i],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                          color: active ? t.textPrimary : t.textMuted,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
