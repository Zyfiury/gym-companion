import 'package:flutter/material.dart';
import '../../services/health_safety_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/onboarding/onboarding_chip.dart';
import '../../widgets/premium_ui.dart';
import '../../widgets/profile/profile_glass_card.dart';
import '../../widgets/profile/profile_save_bar.dart';
import '../../widgets/staggered_entry.dart';

class ProfileHealthTab extends StatelessWidget {
  final String genderAtBirth;
  final Set<String> disabilities;
  final bool pregnant;
  final bool tracksPeriod;
  final String? periodPhase;
  final ValueChanged<String> onGenderChanged;
  final ValueChanged<Set<String>> onDisabilitiesChanged;
  final ValueChanged<bool> onPregnantChanged;
  final ValueChanged<bool> onTracksPeriodChanged;
  final ValueChanged<String?> onPeriodPhaseChanged;
  final VoidCallback onSave;

  const ProfileHealthTab({
    super.key,
    required this.genderAtBirth,
    required this.disabilities,
    required this.pregnant,
    required this.tracksPeriod,
    required this.periodPhase,
    required this.onGenderChanged,
    required this.onDisabilitiesChanged,
    required this.onPregnantChanged,
    required this.onTracksPeriodChanged,
    required this.onPeriodPhaseChanged,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final disabilityItems = HealthSafetyService.disabilityOptions
        .map((d) => OnboardingChipItem(
              id: d,
              label: HealthSafetyService.disabilityLabels[d] ?? d,
              selected: disabilities.contains(d),
            ))
        .toList();

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              StaggeredEntry(
                index: 0,
                child: ProfileGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Health profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: t.textPrimary)),
                      const SizedBox(height: 16),
                      SectionLabel('Gender at birth'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: genderAtBirth,
                        decoration: const InputDecoration(labelText: 'Gender at birth'),
                        items: const [
                          DropdownMenuItem(value: 'female', child: Text('Female')),
                          DropdownMenuItem(value: 'male', child: Text('Male')),
                          DropdownMenuItem(value: 'prefer_not_to_say', child: Text('Prefer not to say')),
                        ],
                        onChanged: (v) {
                          if (v != null) onGenderChanged(v);
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
                      SectionLabel('Conditions & mobility'),
                      const SizedBox(height: 10),
                      OnboardingChipGrid(
                        items: disabilityItems,
                        onToggle: (id) {
                          final next = Set<String>.from(disabilities);
                          if (next.contains(id)) {
                            next.remove(id);
                          } else {
                            next.add(id);
                          }
                          onDisabilitiesChanged(next);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              StaggeredEntry(
                index: 2,
                child: ProfileGlassCard(
                  child: Column(
                    children: [
                      _ToggleRow(
                        title: 'Pregnant',
                        value: pregnant,
                        onChanged: onPregnantChanged,
                      ),
                      Divider(height: 24, color: t.borderSubtle.withValues(alpha: 0.5)),
                      _ToggleRow(
                        title: 'Track menstrual cycle',
                        value: tracksPeriod,
                        onChanged: (v) {
                          onTracksPeriodChanged(v);
                          if (!v) onPeriodPhaseChanged(null);
                        },
                      ),
                      if (tracksPeriod) ...[
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: periodPhase ?? 'none',
                          decoration: const InputDecoration(labelText: 'Cycle phase'),
                          items: const [
                            DropdownMenuItem(value: 'none', child: Text('Not tracking phase')),
                            DropdownMenuItem(value: 'menstrual', child: Text('Menstrual')),
                            DropdownMenuItem(value: 'follicular', child: Text('Follicular')),
                            DropdownMenuItem(value: 'ovulation', child: Text('Ovulation')),
                            DropdownMenuItem(value: 'luteal', child: Text('Luteal')),
                          ],
                          onChanged: (v) => onPeriodPhaseChanged(v == 'none' ? null : v),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        ProfileSaveBar(label: 'Save health profile', onSave: onSave, semanticsId: 'profile-save-health'),
      ],
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({required this.title, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    return Row(
      children: [
        Expanded(child: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: t.textPrimary))),
        Switch.adaptive(value: value, onChanged: onChanged),
      ],
    );
  }
}
