import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/user_data.dart';
import '../providers/app_state.dart';
import '../services/backend_config.dart';
import '../services/subscription_service.dart';
import '../services/vision_calorie_service.dart';
import '../theme/app_theme.dart';
import '../widgets/action_confirmation_chip.dart';
import '../widgets/premium_ui.dart';
import '../widgets/staggered_entry.dart';
import 'paywall_screen.dart';

class ChatScreen extends StatefulWidget {
  final bool embedded;
  final void Function(int tabIndex)? onNavigate;

  const ChatScreen({super.key, this.embedded = false, this.onNavigate});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final _speech = SpeechToText();
  bool _listening = false;
  String _voiceText = '';
  int _lastMsgCount = 0;
  bool _lastTyping = false;

  static const _suggestions = [
    (icon: Icons.fitness_center, text: "Give me today's workout"),
    (icon: Icons.delivery_dining, text: 'Suggest delivery near me'),
    (icon: Icons.pie_chart_outline, text: 'How are my macros looking?'),
    (icon: Icons.celebration_outlined, text: 'I just finished my workout!'),
    (icon: Icons.restaurant, text: 'Log 200g chicken breast'),
    (icon: Icons.swap_horiz, text: 'Swap my lunch'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() => _scrollToEnd();

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.jumpTo(0);
    });
  }

  bool _handleVoiceCommand(String text) {
    final lower = text.toLowerCase();
    if (RegExp(r'start.*workout|open workout|go to workout').hasMatch(lower)) {
      widget.onNavigate?.call(1);
      return true;
    }
    if (RegExp(r'^log\s+(?:my\s+)?(?:breakfast|lunch|dinner)\b|open meals|food log|open food').hasMatch(lower)) {
      widget.onNavigate?.call(2);
      return true;
    }
    if (RegExp(r'show.*progress|open progress').hasMatch(lower)) {
      widget.onNavigate?.call(3);
      return true;
    }
    if (RegExp(r'open.*feed|show.*feed').hasMatch(lower)) {
      widget.onNavigate?.call(5);
      return true;
    }
    return false;
  }

  Future<void> _startListening() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) return;
    final available = await _speech.initialize(
      onStatus: (s) {
        if (s == 'done' || s == 'notListening') {
          setState(() => _listening = false);
          if (_voiceText.isNotEmpty) {
            _send(context.read<AppState>(), _voiceText);
            _voiceText = '';
          }
        }
      },
    );
    if (!available) return;
    setState(() => _listening = true);
    await _speech.listen(
      onResult: (r) {
        setState(() => _voiceText = r.recognizedWords);
        if (r.finalResult) _speech.stop();
      },
      localeId: 'en_GB',
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final state = context.watch<AppState>();
    final showWelcome = state.chatMessages.isEmpty && !state.chatTyping;
    final level = state.user?.gamification['level'] ?? 1;
    if (state.chatMessages.length != _lastMsgCount || state.chatTyping != _lastTyping) {
      _lastMsgCount = state.chatMessages.length;
      _lastTyping = state.chatTyping;
      _scrollToEnd();
    }

    final chatBody = AmbientBackground(
      child: Column(
        children: [
          if (widget.embedded) ...[
            _CoachHeader(
              level: level,
              remaining: state.freeMessagesRemaining,
              hasUserMessages: state.chatMessages.any((m) => m.role == 'user'),
            ),
            const SizedBox(height: 12),
          ],
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              reverse: true,
              padding: EdgeInsets.fromLTRB(widget.embedded ? 0 : 20, 4, widget.embedded ? 0 : 20, 8),
              itemCount: _listItemCount(state, showWelcome),
              itemBuilder: (_, i) => _buildListItem(context, state, i, showWelcome),
            ),
          ),
          if (_listening && _voiceText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  const BouncingDots(size: 5),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_voiceText, style: TextStyle(color: t.textSecondary, fontSize: 12, fontStyle: FontStyle.italic)),
                  ),
                ],
              ),
            ),
          _PlanChips(onTap: (t) => _send(state, t)),
          _CoachContextPicker(period: state.coachContextPeriod, onChanged: state.setCoachContextPeriod),
          _InputDock(
            embedded: widget.embedded,
            controller: _ctrl,
            listening: _listening,
            typing: state.chatTyping,
            onSend: () => _send(state),
            onCamera: () => _scanMeal(state),
            onMicToggle: _listening
                ? () {
                    _speech.stop();
                    setState(() => _listening = false);
                  }
                : _startListening,
          ),
        ],
      ),
    );

    if (widget.embedded) return Padding(padding: const EdgeInsets.fromLTRB(20, 4, 20, 8), child: chatBody);
    return Scaffold(backgroundColor: t.scaffold, body: chatBody);
  }

  int _listItemCount(AppState state, bool showWelcome) {
    var count = state.chatMessages.length + (state.chatTyping ? 1 : 0);
    if (showWelcome) count += 2; // welcome card + suggestions grid
    return count;
  }

  Widget _buildListItem(BuildContext context, AppState state, int i, bool showWelcome) {
    var offset = 0;
    if (state.chatTyping) {
      if (i == 0) return _typingBubble();
      offset = 1;
    }

    final msgs = state.chatMessages;
    final fromBottom = i - offset;
    if (fromBottom < msgs.length) {
      final msgIndex = msgs.length - 1 - fromBottom;
      final m = msgs[msgIndex];
      final isUser = m.role == 'user';
      final isLast = msgIndex == msgs.length - 1 && !state.chatTyping;
      return _messageBubble(context, state, m, msgIndex, isUser, isLast);
    }

    if (!showWelcome) return const SizedBox.shrink();
    final welcomeIdx = fromBottom - msgs.length;
    if (welcomeIdx == 0) {
      return StaggeredEntry(index: 2, child: _SuggestionGrid(suggestions: _suggestions, onTap: (t) => _send(state, t)));
    }
    if (welcomeIdx == 1) {
      return StaggeredEntry(index: 1, child: _WelcomeCard());
    }
    return const SizedBox.shrink();
  }

  Widget _messageBubble(BuildContext context, AppState state, ChatMessage m, int i, bool isUser, bool isLast) {
    final isLastAssistant = !isUser && isLast && i > 0;
    final isLastUser = isUser && isLast;

    final bubble = Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isUser) ...[
              const Padding(
                padding: EdgeInsets.only(right: 8, bottom: 4),
                child: CoachAvatar(size: 28),
              ),
            ],
            Flexible(
              child: Semantics(
                identifier: isLastAssistant ? 'chat-last-reply' : isLastUser ? 'chat-last-user' : null,
                label: m.content,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                  decoration: BoxDecoration(
                    color: isUser ? AppColors.userBubbleBg : context.appTheme.coachBubble,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isUser ? 20 : 6),
                      bottomRight: Radius.circular(isUser ? 6 : 20),
                    ),
                    border: Border.all(
                      color: isUser ? AppColors.voltTintBorder : AppColors.slate600,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isUser)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            'COACH',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: 0.8, color: AppColors.volt),
                          ),
                        ),
                      Text(m.content, style: TextStyle(color: context.appTheme.textPrimary, fontSize: 14, height: 1.6)),
                      if (!isUser && m.deliveryOptions != null && m.deliveryOptions!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        ...m.deliveryOptions!.take(3).map(_deliveryCard),
                      ],
                      if (m.actionChip != null) ActionConfirmationChip(text: m.actionChip!),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
    );
    return ChatBubbleEntry(fromRight: isUser, index: i, child: bubble);
  }

  Future<void> _scanMeal(AppState state) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: context.appTheme.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: AppColors.accent),
              title: const Text('Take photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.accent),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    if (!BackendConfig.hasGoogleVision) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Add GOOGLE_VISION_API_KEY to .env and enable Cloud Vision API to scan meals.'),
          ),
        );
      }
      return;
    }
    if (source == ImageSource.camera) {
      final cam = await Permission.camera.request();
      if (!cam.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Camera permission required')));
        }
        return;
      }
    }
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked == null || !mounted || state.user == null) return;
    final result = await VisionCalorieService.analyze(File(picked.path), state.user!);
    if (!mounted) return;
    if (result.error != null && result.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.error!)));
      return;
    }
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.appTheme.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Detected foods', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: context.appTheme.textPrimary)),
            if (result.isEstimated)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Some macros AI-estimated — review before logging.', style: TextStyle(color: AppColors.orange, fontSize: 12)),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Macros from Open Food Facts where matched.', style: TextStyle(color: AppColors.emerald, fontSize: 12)),
              ),
            if (result.overallConfidence < 0.6)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Low confidence — please review before logging.', style: TextStyle(color: AppColors.orange, fontSize: 12)),
              ),
            const SizedBox(height: 12),
            ...result.items.map((item) => ListTile(
                  dense: true,
                  title: Text(item.blocked ? '${item.name} (blocked)' : item.name),
                  subtitle: Text(item.blocked ? item.blockReason ?? '' : '${item.calories} kcal · P ${item.protein}g'),
                )),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
                onPressed: () async {
                  final reply = await state.logVisionMeal(result.items);
                  await state.addLocalExchange('📷 Meal photo', reply);
                  if (ctx.mounted) Navigator.pop(ctx);
                  _scrollToEnd();
                },
                child: const Text('Log meal'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _deliveryCard(Map<String, dynamic> opt) {
    final t = context.appTheme;
    final name = opt['restaurant'] as String? ?? 'Restaurant';
    final dish = opt['dish'] as String? ?? '';
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: context.isDarkTheme ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: t.textPrimary)),
          if (dish.isNotEmpty)
            Text(
              opt['macrosEstimated'] == true
                  ? 'Suggested: $dish (est. macros)'
                  : '${opt['nutritionSource'] != null ? '$dish (${opt['nutritionSource']})' : dish}',
              style: TextStyle(fontSize: 11, color: t.textSecondary),
            ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _linkChip('Uber Eats', opt['uberEatsUrl'] as String?),
              _linkChip('Deliveroo', opt['deliverooUrl'] as String?),
              _linkChip('Just Eat', opt['justEatUrl'] as String?),
            ],
          ),
        ],
      ),
    );
  }

  Widget _linkChip(String label, String? url) {
    if (url == null || url.isEmpty) return const SizedBox.shrink();
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 10)),
      visualDensity: VisualDensity.compact,
      backgroundColor: AppColors.accent.withValues(alpha: 0.12),
      labelStyle: const TextStyle(color: AppColors.accent),
      onPressed: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
      },
    );
  }

  Widget _typingBubble() {
    final t = context.appTheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Padding(
            padding: EdgeInsets.only(right: 8, bottom: 4),
            child: CoachAvatar(size: 28),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: t.coachBubble,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.circular(6),
              ),
              border: Border.all(color: t.borderSubtle),
            ),
            child: const BouncingDots(),
          ),
        ],
      ),
    );
  }

  Future<void> _send(AppState state, [String? overrideText]) async {
    final text = (overrideText ?? _ctrl.text).trim();
    if (text.isEmpty || state.chatTyping) return;

    if (!await SubscriptionService.isPro() && state.freeMessagesRemaining <= 0) {
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PaywallScreen(highlightFeature: 'coach_limit')),
        );
      }
      return;
    }

    _ctrl.clear();

    if (_handleVoiceCommand(text)) {
      await state.addLocalExchange(text, 'Opening that for you!');
      _scrollToEnd();
      return;
    }

    await state.sendChat(text);
    _scrollToEnd();
  }
}

class _CoachHeader extends StatelessWidget {
  final int level;
  final int remaining;
  final bool hasUserMessages;

  const _CoachHeader({required this.level, required this.remaining, required this.hasUserMessages});

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: t.borderSubtle),
        boxShadow: context.isDarkTheme ? null : [BoxShadow(color: t.shadow, blurRadius: 12, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          const CoachAvatar(size: 50, pulse: true),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Coach', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: t.textPrimary)),
                Text('Level $level · Your personal trainer', style: TextStyle(fontSize: 12, color: t.textSecondary)),
              ],
            ),
          ),
          FutureBuilder<bool>(
            future: SubscriptionService.isPro(),
            builder: (context, snap) {
              if (snap.data == true || remaining >= 5 || !hasUserMessages) return const SizedBox.shrink();
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: remaining <= 3 ? Colors.redAccent.withValues(alpha: 0.12) : AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline, size: 12, color: remaining <= 3 ? Colors.redAccent : AppColors.accent),
                    const SizedBox(width: 4),
                    Text(
                      '$remaining msgs left',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: remaining <= 3 ? Colors.redAccent : AppColors.accent),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CoachContextPicker extends StatelessWidget {
  final String period;
  final Future<void> Function(String) onChanged;

  const _CoachContextPicker({required this.period, required this.onChanged});

  static const _periods = {'day': '1 day', 'week': '1 week', 'month': '1 month'};

  void _showHelp(BuildContext context) {
    final t = context.appTheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: t.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Coach context', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: t.textPrimary)),
            const SizedBox(height: 10),
            Text(
              'Choose how much of your recent activity the coach sees when replying — today only, the past week, or the past month.',
              style: TextStyle(fontSize: 14, color: t.textSecondary, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: SegmentedButton<String>(
              segments: _periods.entries
                  .map((e) => ButtonSegment(value: e.key, label: Text(e.value, style: const TextStyle(fontSize: 11))))
                  .toList(),
              selected: {period},
              onSelectionChanged: (s) => onChanged(s.first),
            ),
          ),
          IconButton(
            icon: Icon(Icons.help_outline, size: 20, color: t.textMuted),
            onPressed: () => _showHelp(context),
            tooltip: 'What is coach context?',
          ),
        ],
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accent.withValues(alpha: context.isDarkTheme ? 0.15 : 0.08),
            t.card,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hey! I\'m your coach.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: t.textPrimary)),
          const SizedBox(height: 6),
          Text(
            'I can plan workouts, swap meals, log food, find delivery nearby, and track your progress — just ask.',
            style: TextStyle(fontSize: 13, color: t.textSecondary, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _SuggestionGrid extends StatelessWidget {
  final List<({IconData icon, String text})> suggestions;
  final ValueChanged<String> onTap;

  const _SuggestionGrid({required this.suggestions, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: LayoutBuilder(builder: (context, constraints) {
        final chipW = (constraints.maxWidth - 8) / 2;
        return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: suggestions.map((s) {
          return PressableScale(
            onTap: () => onTap(s.text),
            child: Container(
              width: chipW,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: t.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: t.borderSubtle),
              ),
              child: Row(
                children: [
                  Icon(s.icon, size: 16, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(s.text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: t.textPrimary), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      );
      }),
    );
  }
}

class _PlanChips extends StatelessWidget {
  final ValueChanged<String> onTap;
  const _PlanChips({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    const plans = ['Plan for 1 day', 'Plan for 1 week', 'Plan for 1 month'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: plans.map((p) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Semantics(
                  identifier: 'chat-plan-${p.split(' ').last}',
                  button: true,
                  child: ActionChip(
                    label: Text(p.replaceAll('Plan for ', ''), style: const TextStyle(fontSize: 12)),
                    backgroundColor: t.elevated,
                    side: BorderSide(color: t.borderSubtle),
                    onPressed: () => onTap(p),
                  ),
                ),
              )).toList(),
        ),
      ),
    );
  }
}

class _InputDock extends StatelessWidget {
  final bool embedded;
  final TextEditingController controller;
  final bool listening;
  final bool typing;
  final VoidCallback onSend;
  final VoidCallback onMicToggle;
  final VoidCallback onCamera;

  const _InputDock({
    required this.embedded,
    required this.controller,
    required this.listening,
    required this.typing,
    required this.onSend,
    required this.onMicToggle,
    required this.onCamera,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    return Container(
      margin: EdgeInsets.fromLTRB(embedded ? 0 : 16, 8, embedded ? 0 : 16, embedded ? 0 : 8 + MediaQuery.of(context).padding.bottom),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: t.borderSubtle),
        boxShadow: [BoxShadow(color: t.shadow, blurRadius: 16, offset: const Offset(0, -2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              identifier: 'chat-input',
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Ask your AI coach…',
                  hintStyle: TextStyle(color: t.textMuted, fontSize: 14),
                  filled: true,
                  fillColor: t.inputFill,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: AppColors.accent.withValues(alpha: 0.4))),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
          ),
          Semantics(
            identifier: 'chat-camera-btn',
            button: true,
            child: IconButton(
              onPressed: onCamera,
              icon: Icon(Icons.camera_alt_outlined, color: t.iconMuted, size: 22),
            ),
          ),
          Semantics(
            identifier: 'chat-mic',
            button: true,
            child: IconButton(
              onPressed: onMicToggle,
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  listening ? Icons.mic : Icons.mic_none,
                  key: ValueKey(listening),
                  color: listening ? Colors.redAccent : t.iconMuted,
                  size: 22,
                ),
              ),
            ),
          ),
          Semantics(
            identifier: 'chat-send',
            button: true,
            child: PressableScale(
              onTap: typing ? null : onSend,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: typing ? null : AppColors.warmGradient,
                  color: typing ? t.progressTrack : null,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_upward_rounded, color: typing ? t.textMuted : Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
