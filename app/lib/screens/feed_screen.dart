import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/subscription_service.dart';
import '../theme/app_theme.dart';
import '../utils/pro_gate.dart';
import '../utils/sheet_padding.dart';
import '../widgets/empty_state_card.dart';
import '../widgets/user_avatar.dart';
import '../widgets/feed_compose_sheet.dart';
import '../widgets/premium_ui.dart';
import '../widgets/shimmer_skeleton.dart';
import '../widgets/staggered_entry.dart';

String _relativeTime(String iso) {
  final dt = DateTime.tryParse(iso);
  if (dt == null) return '';
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return DateFormat('d MMM').format(dt);
}

IconData _postIcon(String? type) {
  switch (type) {
    case 'pr':
      return Icons.emoji_events;
    case 'meal':
      return Icons.restaurant;
    default:
      return Icons.chat_bubble_outline;
  }
}

const _xpRules = [
  'Post to the community feed — +10 XP',
  'Log food — +5 XP',
  'Log weight — +5 XP',
  'Log a personal record — +15 XP',
  'Complete an exercise — +5 XP',
  'Finish a full workout — +15 XP',
];

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  String filter = 'all';
  bool _initialLoad = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().refreshLeaderboard();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _initialLoad = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final state = context.watch<AppState>();
    final uid = state.userId!;
    var posts = List<Map<String, dynamic>>.from(state.feedPosts);
    posts.sort((a, b) => '${b['ts']}'.compareTo('${a['ts']}'));
    if (filter == 'mine') posts = posts.where((p) => p['authorId'] == uid).toList();

    final leaderboard = state.leaderboard.take(10).toList();

    return Stack(
      children: [
        AmbientBackground(
          child: ListView(
            padding: EdgeInsets.fromLTRB(20, 4, 20, scrollBottomInset(context, extra: 96)),
            children: [
              StaggeredEntry(
                index: 0,
                child: AppCard(
                  child: Semantics(
                    container: true,
                    explicitChildNodes: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Semantics(
                              identifier: 'feed-title',
                              label: 'Feed',
                              child: Text('Community', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: t.textSecondary)),
                            ),
                            const Spacer(),
                            SegmentedButton<String>(
                              segments: const [
                                ButtonSegment(value: 'all', label: Text('Public', style: TextStyle(fontSize: 11))),
                                ButtonSegment(value: 'mine', label: Text('My Posts', style: TextStyle(fontSize: 11))),
                              ],
                              selected: {filter},
                              onSelectionChanged: (s) => setState(() => filter = s.first),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (_initialLoad)
                          const FeedPostSkeleton()
                        else if (posts.isEmpty)
                          filter == 'mine'
                              ? EmptyStateCard(
                                  icon: Icons.edit_outlined,
                                  headline: 'Share your first post',
                                  subtext: 'Post a PR, meal, or motivation tip to earn XP',
                                  buttonLabel: 'Create post',
                                  onAction: () => showFeedComposeSheet(context),
                                )
                              : EmptyStateCard(
                                  icon: Icons.forum_outlined,
                                  headline: 'Be the first to post',
                                  subtext: 'Share a PR, meal, or motivation tip',
                                  buttonLabel: 'Create post',
                                  onAction: () => showFeedComposeSheet(context),
                                )
                        else
                          ...posts.asMap().entries.map((entry) {
                            final i = entry.key;
                            final p = entry.value;
                            final likes = List<String>.from(p['likes'] as List? ?? []);
                            final liked = likes.contains(uid);
                            final isMe = p['authorId'] == uid;
                            final postType = p['postType'] as String? ?? 'motivation';
                            final caption = p['caption'] as String?;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: t.elevated,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: t.borderSubtle),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      UserAvatar(
                                        imagePath: isMe ? state.user?.avatarPath : p['authorAvatarPath'] as String?,
                                        name: isMe ? (state.displayName ?? 'You') : '${p['authorName']}',
                                        radius: 16,
                                        showGradientFallback: false,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(isMe ? 'You' : '${p['authorName']}', style: TextStyle(fontWeight: FontWeight.w600, color: t.textPrimary, fontSize: 13)),
                                            Text(_relativeTime('${p['ts']}'), style: TextStyle(fontSize: 11, color: t.textMuted)),
                                          ],
                                        ),
                                      ),
                                      Icon(_postIcon(postType), size: 16, color: AppColors.accent),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Semantics(
                                    identifier: i == 0 ? 'feed-post-latest' : 'feed-post-${p['id']}',
                                    label: '${p['content']}',
                                    child: Text('${p['content']}', style: TextStyle(fontSize: 13, color: t.textSecondary)),
                                  ),
                                  if (caption != null && caption.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(caption, style: TextStyle(fontSize: 12, color: t.textMuted, fontStyle: FontStyle.italic)),
                                  ],
                                  const SizedBox(height: 8),
                                  Semantics(
                                    identifier: 'like-${p['id']}',
                                    button: true,
                                    child: InkWell(
                                      onTap: () => state.toggleFeedLike('${p['id']}'),
                                      child: Text('${liked ? '❤️' : '🤍'} ${likes.length}', style: TextStyle(fontSize: 12, color: t.textMuted)),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              StaggeredEntry(
                index: 1,
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.emoji_events, color: Colors.amber, size: 20),
                          const SizedBox(width: 8),
                          Text('Leaderboard', style: TextStyle(fontWeight: FontWeight.w700, color: t.textPrimary)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      FutureBuilder<bool>(
                        future: SubscriptionService.isPro(),
                        builder: (ctx, snap) {
                          final isPro = snap.data ?? false;
                          if (leaderboard.isEmpty) {
                            return _LeaderRow(
                              rank: 1,
                              name: state.displayName ?? 'You',
                              xp: state.user?.gamification['xp'] ?? 0,
                              highlight: true,
                            );
                          }
                          return Column(
                            children: [
                              for (var i = 0; i < leaderboard.length; i++)
                                _LeaderRow(
                                  rank: i + 1,
                                  name: '${leaderboard[i]['displayName']}',
                                  xp: leaderboard[i]['xp'] as int? ?? 0,
                                  highlight: leaderboard[i]['userId'] == uid,
                                  locked: i >= 1 && !isPro,
                                  onTap: i >= 1 && !isPro
                                      ? () => ProGate.check(context, feature: 'leaderboard', triggerSource: 'leaderboard')
                                      : null,
                                ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          childrenPadding: const EdgeInsets.only(bottom: 4),
                          title: Text('How do I earn XP?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.textSecondary)),
                          children: _xpRules
                              .map((rule) => Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('• ', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700)),
                                        Expanded(child: Text(rule, style: TextStyle(fontSize: 12, color: t.textSecondary))),
                                      ],
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          right: 20,
          bottom: scrollBottomInset(context, extra: 12),
          child: Semantics(
            identifier: 'feed-create-btn',
            button: true,
            child: FloatingActionButton(
              onPressed: () => showFeedComposeSheet(context),
              backgroundColor: AppColors.accent,
              elevation: 2,
              child: const Icon(Icons.add),
            ),
          ),
        ),
      ],
    );
  }
}

class _LeaderRow extends StatelessWidget {
  final int rank;
  final String name;
  final int xp;
  final bool highlight;
  final bool locked;
  final VoidCallback? onTap;

  const _LeaderRow({
    required this.rank,
    required this.name,
    required this.xp,
    this.highlight = false,
    this.locked = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: highlight ? AppColors.voltTintBg : t.elevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: highlight ? AppColors.voltTintBorder : t.borderSubtle),
        ),
        child: Row(
          children: [
            Text(
              '#$rank',
              style: TextStyle(
                color: rank == 1 ? AppColors.volt : t.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                locked ? 'Unlock with Pro' : name,
                style: TextStyle(fontWeight: FontWeight.w500, color: locked ? t.textMuted : t.textPrimary),
              ),
            ),
            if (locked)
              const Icon(Icons.lock_outline, size: 14, color: AppColors.ember)
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.voltTintBg,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: AppColors.voltTintBorder),
                ),
                child: Text(
                  '$xp XP',
                  style: const TextStyle(color: AppColors.voltDark, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
