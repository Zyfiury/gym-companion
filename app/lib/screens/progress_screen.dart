import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state_card.dart';
import '../widgets/health_connect_sheet.dart';
import '../widgets/premium_ui.dart';
import '../widgets/pr_log_sheet.dart';
import '../widgets/staggered_entry.dart';
import '../utils/personal_record_helper.dart';
import '../widgets/weight_line_chart.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final _weightCtrl = TextEditingController();
  final _weightFocus = FocusNode();
  DateTime _logDate = DateTime.now();

  @override
  void dispose() {
    _weightCtrl.dispose();
    _weightFocus.dispose();
    super.dispose();
  }

  void _focusWeightField() => _weightFocus.requestFocus();

  bool get _loggingToday {
    final now = DateTime.now();
    return _logDate.year == now.year && _logDate.month == now.month && _logDate.day == now.day;
  }

  String get _logDateLabel => _loggingToday ? 'Today' : DateFormat('d MMM yyyy').format(_logDate);

  Future<void> _pickLogDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _logDate.isAfter(now) ? now : _logDate,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now,
      helpText: 'Weigh-in date',
    );
    if (picked != null) setState(() => _logDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final state = context.watch<AppState>();
    final u = state.user!;

    final macros = u.dailyMacrosLogged;
    final calTarget = u.weeklyPlan.macros['calories'] ?? u.tdee;

    final records = PersonalRecordHelper.merge(u.personalRecords);
    final topRecords = records.take(5).toList();
    final prSuggestions = PersonalRecordHelper.exerciseSuggestions(u);

    return AmbientBackground(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          StaggeredEntry(
            index: 0,
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionLabel('Today'),
                  const SizedBox(height: 16),
                  MacroBar(label: 'Calories', current: macros.calories, target: calTarget, color: AppColors.orange),
                  const SizedBox(height: 12),
                  MacroBar(label: 'Protein', current: macros.protein, target: u.weeklyPlan.macros['protein'] ?? 140, color: AppColors.accent),
                  const SizedBox(height: 12),
                  MacroBar(label: 'Carbs', current: macros.carbs, target: u.weeklyPlan.macros['carbs'] ?? 200, color: AppColors.blue),
                  const SizedBox(height: 12),
                  MacroBar(label: 'Fat', current: macros.fat, target: u.weeklyPlan.macros['fat'] ?? 60, color: AppColors.emerald),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          StaggeredEntry(
            index: 1,
            child: PressableScale(
              onTap: () => showHealthConnectSheet(
                context,
                connected: state.healthConnected,
                steps: u.steps.toInt(),
                onConnect: () => state.refreshHealthData(requestIfNeeded: true),
              ),
              child: AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.directions_walk, color: AppColors.accent, size: 22),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: Text('Steps today', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: t.textPrimary))),
                    Text(
                      state.healthConnected ? '${u.steps.toInt()}' : '—',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: t.textPrimary),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          StaggeredEntry(
            index: 2,
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionLabel('Weight trend'),
                  const SizedBox(height: 20),
                  WeightLineChart(
                    history: u.weightHistory,
                    onLogWeight: _focusWeightField,
                  ),
                  if (u.weightHistory.length > 1) ...[
                    const SizedBox(height: 16),
                    ...(() {
                      final recent = List<Map<String, dynamic>>.from(u.weightHistory)
                        ..sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));
                      return recent.take(5).map((e) {
                        final d = DateTime.tryParse(e['date'] as String? ?? '');
                        final label = d != null ? '${d.day}/${d.month}/${d.year}' : '${e['date']}';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Text(label, style: TextStyle(fontSize: 12, color: t.textMuted)),
                              const Spacer(),
                              Text('${(e['weight'] as num).toStringAsFixed(1)} kg', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.textPrimary)),
                            ],
                          ),
                        );
                      });
                    })(),
                  ],
                  const SizedBox(height: 20),
                  InkWell(
                    onTap: _pickLogDate,
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 16, color: t.textMuted),
                          const SizedBox(width: 8),
                          Text(_logDateLabel, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.textPrimary)),
                          const SizedBox(width: 6),
                          Text(
                            _loggingToday ? '· missed a day? tap to backdate' : '· tap to change date',
                            style: TextStyle(fontSize: 12, color: t.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _weightCtrl,
                          focusNode: _weightFocus,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: t.textPrimary),
                          decoration: InputDecoration(hintText: 'Log weight (kg)', hintStyle: TextStyle(color: t.textMuted)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: AppColors.accent, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
                        onPressed: () async {
                          final v = double.tryParse(_weightCtrl.text);
                          if (v == null) return;
                          final messenger = ScaffoldMessenger.of(context);
                          final chip = await context.read<AppState>().logWeight(v, date: _logDate);
                          _weightCtrl.clear();
                          setState(() => _logDate = DateTime.now());
                          if (chip != null && mounted) {
                            messenger.showSnackBar(SnackBar(content: Text(chip)));
                          }
                        },
                        child: const Text('Log'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          StaggeredEntry(
            index: 3,
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(child: SectionLabel('Personal records')),
                      TextButton.icon(
                        onPressed: () => showPrLogSheet(context, extraExercises: prSuggestions),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Log PR'),
                        style: TextButton.styleFrom(foregroundColor: AppColors.accent),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (topRecords.isEmpty)
                    EmptyStateCard(
                      icon: Icons.emoji_events_outlined,
                      headline: 'No PRs logged yet',
                      subtext: 'Track bench, squat, deadlift, and any lift you improve on.',
                      buttonLabel: 'Log a PR',
                      onAction: () => showPrLogSheet(context, extraExercises: prSuggestions),
                    )
                  else ...[
                    ...topRecords.map((r) {
                      final exercise = r['exercise'] as String? ?? '';
                      final value = PersonalRecordHelper.formatValue(r['value'], r['unit'] as String? ?? '');
                      final date = r['date'] as String? ?? '';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.emoji_events, color: AppColors.accent, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(exercise, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: t.textPrimary)),
                                  if (date.isNotEmpty) Text(date, style: TextStyle(fontSize: 11, color: t.textMuted)),
                                ],
                              ),
                            ),
                            Text(value, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: t.textPrimary)),
                          ],
                        ),
                      );
                    }),
                    if (records.length > 5)
                      Text('${records.length - 5} more in your history', style: TextStyle(fontSize: 12, color: t.textMuted)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
