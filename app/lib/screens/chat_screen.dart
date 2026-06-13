import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../utils/delivery_actions.dart';
import '../models/user_data.dart';
import '../providers/app_state.dart';
import '../services/backend_config.dart';
import '../services/subscription_service.dart';
import '../services/vision_calorie_service.dart';
import '../core/widgets/app_toast.dart';
import '../core/widgets/skeletons.dart';
import '../theme/app_theme.dart';
import '../widgets/action_confirmation_chip.dart';
import '../utils/sheet_padding.dart';
import '../widgets/premium_ui.dart';
import '../widgets/staggered_entry.dart';
import 'paywall_screen.dart';
import '../widgets/page_transitions.dart';
import '../services/coach_personality_service.dart';
import '../features/coach/coach_morning_checkin.dart';

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
  bool _historyReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _historyReady = true);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AppState>().ensureCoachDailyOpener();
    });
  }

  bool _showCoachLanding(AppState state) => !state.chatTyping && !state.hasUserMessageToday();

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
    final showWelcome = state.chatMessages.isEmpty && _showCoachLanding(state);
    final showLanding = _showCoachLanding(state);
    final suggestions = CoachPersonalityService.dynamicSuggestions(state);
    final opener = CoachPersonalityService.dailyOpener(state);
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
            const SizedBox(height: 16),
          ],
          Expanded(
            child: !_historyReady
                ? Padding(
                    padding: EdgeInsets.fromLTRB(widget.embedded ? 0 : 20, 12, widget.embedded ? 0 : 20, 8),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonText(width: 200, height: 14),
                        SizedBox(height: 10),
                        SkeletonText(width: double.infinity, height: 12),
                        SizedBox(height: 10),
                        SkeletonText(width: 260, height: 12),
                        SizedBox(height: 10),
                        SkeletonText(width: 180, height: 12),
                        SizedBox(height: 10),
                        SkeletonText(width: 220, height: 12),
                      ],
                    ),
                  )
                : showWelcome
                ? SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(widget.embedded ? 0 : 20, 4, widget.embedded ? 0 : 20, 8),
                    child: Column(
                      children: [
                        StaggeredEntry(
                          index: 1,
                          child: _WelcomeAndSuggestionsCard(
                            opener: opener,
                            suggestions: suggestions,
                            onTap: (t) => _send(state, t),
                            showVoiceChip: true,
                            onVoiceChip: _startListening,
                          ),
                        ),
                        CoachMorningCheckin(onSorenessMessage: (msg) => _send(state, msg)),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scroll,
                    reverse: true,
                    padding: EdgeInsets.fromLTRB(widget.embedded ? 0 : 20, 4, widget.embedded ? 0 : 20, 8),
                    itemCount: _listItemCount(state),
                    itemBuilder: (_, i) => _buildListItem(context, state, i),
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
          if (showLanding && !showWelcome)
            CoachMorningCheckin(onSorenessMessage: (msg) => _send(state, msg)),
          // Keep quick suggestions one tap away even mid-conversation.
          if (!showWelcome && !state.chatTyping)
            _SuggestionChips(suggestions: suggestions, onTap: (t) => _send(state, t)),
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

  int _listItemCount(AppState state) {
    return state.chatMessages.length + (state.chatTyping ? 1 : 0);
  }

  Widget _buildListItem(BuildContext context, AppState state, int i) {
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

    return const SizedBox.shrink();
  }

  static String _relativeTime(DateTime ts) {
    final diff = DateTime.now().difference(ts);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'yesterday';
    return '${ts.day}/${ts.month}';
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
                child: GestureDetector(
                onLongPress: () {
                  Clipboard.setData(ClipboardData(text: m.content));
                  HapticFeedback.mediumImpact();
                  AppToast.success(context, 'Copied to clipboard');
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                  decoration: BoxDecoration(
                    color: isUser ? context.appColors.primaryGlow : context.appTheme.coachBubble,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isUser ? 20 : 6),
                      bottomRight: Radius.circular(isUser ? 6 : 20),
                    ),
                    border: Border.all(
                      color: isUser ? context.appColors.primaryTintBorder : context.appColors.surface3,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isUser)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            CoachPersonalityService.coachName.toUpperCase(),
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: 0.8, color: context.appColors.primary),
                          ),
                        ),
                      Text(m.content, style: TextStyle(color: context.appTheme.textPrimary, fontSize: 14, height: 1.6)),
                      if (!isUser && m.deliveryOptions != null && m.deliveryOptions!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        ...m.deliveryOptions!.take(3).map(_deliveryCard),
                      ],
                      if (m.actionChip != null) ActionConfirmationChip(text: m.actionChip!),
                      const SizedBox(height: 4),
                      Text(
                        _relativeTime(m.ts),
                        style: TextStyle(fontSize: 9.5, color: context.appTheme.textMuted),
                      ),
                    ],
                  ),
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
              leading: Icon(Icons.camera_alt_outlined, color: context.appColors.primary),
              title: const Text('Take photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: Icon(Icons.photo_library_outlined, color: context.appColors.primary),
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
        AppToast.error(context, 'Add GOOGLE_VISION_API_KEY to scan meals');
      }
      return;
    }
    if (source == ImageSource.camera) {
      final cam = await Permission.camera.request();
      if (!cam.isGranted) {
        if (mounted) {
          AppToast.error(context, 'Camera permission required');
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
      AppToast.error(context, result.error!);
      return;
    }
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.appTheme.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: sheetInsets(ctx, horizontal: 20, top: 20, extra: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Detected foods', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: context.appTheme.textPrimary)),
            if (result.isEstimated)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Some macros AI-estimated - review before logging.', style: TextStyle(color: context.appColors.sand, fontSize: 12)),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Macros from Open Food Facts where matched.', style: TextStyle(color: context.appColors.mint, fontSize: 12)),
              ),
            if (result.overallConfidence < 0.6)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Low confidence - please review before logging.', style: TextStyle(color: context.appColors.sand, fontSize: 12)),
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
                style: FilledButton.styleFrom(backgroundColor: context.appColors.primary),
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
    final isEatOut = opt['isEatOut'] == true;
    final actionUrl = primaryActionUrl(opt);

    return Material(
      color: context.appColors.primary.withValues(alpha: context.isDarkTheme ? 0.12 : 0.06),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: actionUrl != null ? () => launchExternalUrl(context, actionUrl) : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.only(top: 6),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.appColors.primary.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: t.textPrimary)),
                  ),
                  if (actionUrl != null)
                    Icon(
                      isEatOut ? Icons.map_outlined : Icons.open_in_new,
                      size: 14,
                      color: t.textMuted,
                    ),
                ],
              ),
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
                  if (isEatOut && opt['mapsUrl'] != null)
                    _linkChip('Open in Maps', opt['mapsUrl'] as String?)
                  else ...[
                    _linkChip('Uber Eats', opt['uberEatsUrl'] as String?),
                    _linkChip('Deliveroo', opt['deliverooUrl'] as String?),
                    _linkChip('Just Eat', opt['justEatUrl'] as String?),
                  ],
                  _linkChip('Log dish', null, onTap: () => logDeliveryOption(context, opt)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _linkChip(String label, String? url, {VoidCallback? onTap}) {
    if (url == null && onTap == null) return const SizedBox.shrink();
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 10)),
      visualDensity: VisualDensity.compact,
      backgroundColor: context.appColors.primary.withValues(alpha: 0.12),
      labelStyle: TextStyle(color: context.appColors.primary),
      onPressed: () async {
        if (onTap != null) {
          onTap();
          return;
        }
        if (url != null) await launchExternalUrl(context, url);
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
        await pushModal(context, const PaywallScreen(highlightFeature: 'coach_limit'));
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: t.borderSubtle),
        boxShadow: context.isDarkTheme ? null : [BoxShadow(color: t.shadow, blurRadius: 12, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          const CoachAvatar(size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  CoachPersonalityService.coachName,
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, height: 1.1, color: t.textPrimary),
                ),
                Text(
                  'Level $level · Your gym companion',
                  style: TextStyle(fontSize: 12, height: 1.2, color: t.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          FutureBuilder<bool>(
            future: SubscriptionService.isPro(),
            builder: (context, snap) {
              if (snap.data == true || remaining >= 5 || !hasUserMessages) return const SizedBox.shrink();
              final c = context.appColors;
              final warn = remaining <= 3;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: warn ? c.errorDim : c.primaryGlow,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline, size: 12, color: warn ? c.error : c.primary),
                    const SizedBox(width: 4),
                    Text(
                      '$remaining msgs left',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: warn ? c.error : c.primary),
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
        padding: sheetInsets(ctx, horizontal: 20, top: 20, extra: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Coach context', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: t.textPrimary)),
            const SizedBox(height: 10),
            Text(
              'Choose how much of your recent activity the coach sees when replying - today only, the past week, or the past month.',
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
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

class _SuggestionChips extends StatelessWidget {
  final List<({IconData icon, String text})> suggestions;
  final ValueChanged<String> onTap;

  const _SuggestionChips({required this.suggestions, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final s = suggestions[i];
          return PressableScale(
            onTap: () => onTap(s.text),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: t.card,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: t.borderSubtle),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(s.icon, size: 14, color: context.appColors.primary),
                  const SizedBox(width: 6),
                  Text(s.text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: t.textPrimary)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WelcomeAndSuggestionsCard extends StatelessWidget {
  final String opener;
  final List<({IconData icon, String text})> suggestions;
  final ValueChanged<String> onTap;
  final bool showVoiceChip;
  final VoidCallback? onVoiceChip;

  const _WelcomeAndSuggestionsCard({
    required this.opener,
    required this.suggestions,
    required this.onTap,
    this.showVoiceChip = false,
    this.onVoiceChip,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.appColors.primary.withValues(alpha: context.isDarkTheme ? 0.15 : 0.08),
            t.card,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.appColors.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CoachAvatar(size: 36),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      CoachPersonalityService.coachName,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: t.textPrimary),
                    ),
                    Text(
                      'Checked your day',
                      style: TextStyle(fontSize: 11, color: t.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(opener, style: TextStyle(fontSize: 13, color: t.textSecondary, height: 1.45)),
          const SizedBox(height: 16),
          if (showVoiceChip && onVoiceChip != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: PressableScale(
                onTap: onVoiceChip,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: context.appColors.surface2,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: context.appColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.mic_outlined, size: 18, color: context.appColors.primary),
                      const SizedBox(width: 8),
                      Text('Log what I just ate', style: TextStyle(fontSize: 13, color: context.appColors.textMuted)),
                    ],
                  ),
                ),
              ),
            ),
          LayoutBuilder(
            builder: (context, constraints) {
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
                          Icon(s.icon, size: 16, color: context.appColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              s.text,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: t.textPrimary),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
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
      margin: EdgeInsets.fromLTRB(embedded ? 12 : 16, 8, embedded ? 12 : 16, embedded ? 8 : 8 + MediaQuery.of(context).padding.bottom),
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
                  hintText: 'Ask ${CoachPersonalityService.coachName}…',
                  hintStyle: TextStyle(color: t.textMuted, fontSize: 14),
                  filled: true,
                  fillColor: t.inputFill,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: context.appColors.primary.withValues(alpha: 0.4))),
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
                  color: listening ? context.appColors.error : t.iconMuted,
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
                  gradient: typing ? null : LinearGradient(colors: [context.appColors.primary, context.appColors.sand]),
                  color: typing ? t.progressTrack : null,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_upward_rounded, color: typing ? t.textMuted : context.appColors.onPrimary, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
