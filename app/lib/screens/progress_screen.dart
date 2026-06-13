import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../core/widgets/app_toast.dart';
import '../theme/app_theme.dart';
import '../utils/sheet_padding.dart';
import '../core/widgets/app_empty_state.dart';
import '../core/widgets/skeletons.dart';
import '../core/widgets/tab_load_gate.dart';
import '../widgets/health_connect_sheet.dart';
import '../widgets/premium_ui.dart';
import '../widgets/pr_log_sheet.dart';
import '../widgets/staggered_entry.dart';
import '../utils/personal_record_helper.dart';
import '../widgets/weight_line_chart.dart';
import '../features/progress/calorie_trend_card.dart';
import '../features/progress/weekly_volume_chart.dart';
import '../features/progress/weekly_goals_section.dart';

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

  Future<void> _refresh() async {
    final state = context.read<AppState>();
    await Future.wait([
      state.refreshHealthData(),
      state.refreshDailyLogsHistory(),
    ]);
  }

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

  void _showAllRecords(BuildContext context, List<Map<String, dynamic>> records) {
    final t = context.appTheme;
    final c = context.appColors;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: t.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, scrollCtrl) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                children: [
                  Icon(Icons.emoji_events, color: c.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'All personal records (${records.length})',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: t.textPrimary),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                itemCount: records.length,
                separatorBuilder: (_, i) => Divider(height: 1, color: t.borderSubtle),
                itemBuilder: (_, i) {
                  final r = records[i];
                  final value = PersonalRecordHelper.formatValue(r['value'], r['unit'] as String? ?? '');
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      r['exercise'] as String? ?? '',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: t.textPrimary),
                    ),
                    subtitle: Text(r['date'] as String? ?? '', style: TextStyle(fontSize: 11, color: t.textMuted)),
                    trailing: Text(value, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: t.textPrimary)),
                  );
                },
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
    final c = context.appColors;
    final state = context.watch<AppState>();
    final u = state.user!;

    final records = PersonalRecordHelper.merge(u.personalRecords);
    final topRecords = records.take(5).toList();
    final prSuggestions = PersonalRecordHelper.exerciseSuggestions(u);

    return TabLoadGate(
      skeleton: ListView(
        padding: tabListPadding(context),
        children: const [
          SkeletonCard(height: 200),
          SizedBox(height: 14),
          SkeletonCard(),
          SizedBox(height: 14),
          SkeletonMacroBar(),
        ],
      ),
      child: AmbientBackground(
      child: RefreshIndicator(
      onRefresh: _refresh,
      color: c.primary,
      child: ListView(
        padding: tabListPadding(context),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          StaggeredEntry(
            index: 0,
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
                        final label = d != null ? DateFormat('d MMM yyyy').format(d) : '${e['date']}';
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
                        child: Semantics(
                          identifier: 'progress-weight-field',
                          child: TextField(
                            controller: _weightCtrl,
                            focusNode: _weightFocus,
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: t.textPrimary),
                            decoration: InputDecoration(hintText: 'Log weight (kg)', hintStyle: TextStyle(color: t.textMuted)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Semantics(
                        identifier: 'progress-log-weight',
                        button: true,
                        label: 'Log weight',
                        child: FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: c.primary, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
                          onPressed: () async {
                          final v = double.tryParse(_weightCtrl.text);
                          if (v == null) return;
                          HapticFeedback.lightImpact();
                          await context.read<AppState>().logWeight(v, date: _logDate);
                          _weightCtrl.clear();
                          setState(() => _logDate = DateTime.now());
                          if (mounted) AppToast.success(context, 'Weight saved ✓');
                        },
                        child: const Text('Log weight'),
                      ),
                    ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          const StaggeredEntry(index: 1, child: CalorieTrendCard()),
          const SizedBox(height: 14),
          const StaggeredEntry(index: 1, child: WeeklyGoalsSection()),
          const SizedBox(height: 14),
          const StaggeredEntry(index: 2, child: WeeklyVolumeChart()),
          const SizedBox(height: 14),
          StaggeredEntry(
            index: 3,
            child: PressableScale(
              onTap: () => showHealthConnectSheet(
                context,
                connected: state.healthConnected,
                steps: u.steps.toInt(),
              ),
              child: AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: c.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                      child: Icon(Icons.directions_walk, color: c.primary, size: 22),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: Text('Steps today', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: t.textPrimary))),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          state.healthConnected ? '${u.steps.toInt()}' : '-',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: t.textPrimary),
                        ),
                        if (state.healthConnected && state.stepCaloriesBurned > 0)
                          Text(
                            '${state.stepCaloriesBurned.round()} kcal',
                            style: TextStyle(fontSize: 11, color: t.textSecondary),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          StaggeredEntry(
            index: 4,
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
                        style: TextButton.styleFrom(foregroundColor: c.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (topRecords.isEmpty)
                    AppEmptyState(
                      compact: true,
                      icon: Icons.emoji_events_outlined,
                      heading: 'No personal records yet',
                      body: 'Complete a workout to start tracking PRs',
                      ctaLabel: 'Start workout',
                      onCta: () => context.read<AppState>().setTab(1),
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
                                color: c.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.emoji_events, color: c.primary, size: 18),
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
                      InkWell(
                        onTap: () => _showAllRecords(context, records),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Text(
                                'View all ${records.length} PRs',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.primary),
                              ),
                              Icon(Icons.chevron_right, size: 16, color: c.primary),
                            ],
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    ),
    );
  }
}
