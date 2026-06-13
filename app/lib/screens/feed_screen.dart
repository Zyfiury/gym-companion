import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/subscription_service.dart';
import '../theme/app_theme.dart';
import '../utils/pro_gate.dart';
import '../utils/sheet_padding.dart';
import '../core/widgets/app_empty_state.dart';
import '../core/widgets/skeletons.dart';
import '../core/widgets/tab_load_gate.dart';
import '../widgets/user_avatar.dart';
import '../widgets/feed_compose_sheet.dart';
import '../widgets/premium_ui.dart';
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
  'Post to the community feed - +10 XP',
  'Log food - +5 XP',
  'Log weight - +5 XP',
  'Log a personal record - +15 XP',
  'Complete an exercise - +5 XP',
  'Finish a full workout - +15 XP',
];

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  String filter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().refreshLeaderboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return TabLoadGate(
      skeleton: ListView(
        padding: tabListPadding(context),
        children: const [
          SkeletonCard(),
          SizedBox(height: AppSpacing.listGap),
          SkeletonFeedPost(),
          SkeletonFeedPost(),
          SkeletonFeedPost(),
        ],
      ),
      child: _FeedBody(filter: filter, onFilterChanged: (f) => setState(() => filter = f)),
    );
  }
}

class _FeedBody extends StatelessWidget {
  final String filter;
  final ValueChanged<String> onFilterChanged;

  const _FeedBody({required this.filter, required this.onFilterChanged});

  Future<void> _refresh(BuildContext context) async {
    final state = context.read<AppState>();
    await Future.wait([
      state.refreshFeed(),
      state.refreshLeaderboard(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final c = context.appColors;
    final state = context.watch<AppState>();
    final uid = state.userId!;
    var posts = List<Map<String, dynamic>>.from(state.feedPosts);
    posts.sort((a, b) => '${b['ts']}'.compareTo('${a['ts']}'));
    if (filter == 'mine') posts = posts.where((p) => p['authorId'] == uid).toList();

    final leaderboard = state.leaderboard.take(10).toList();

    return AmbientBackground(
      child: RefreshIndicator(
        onRefresh: () => _refresh(context),
        color: c.primary,
        child: ListView(
          padding: tabListPadding(context),
          physics: const AlwaysScrollableScrollPhysics(),
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
                          Semantics(
                            identifier: 'feed-create-btn',
                            button: true,
                            child: IconButton(
                              onPressed: () => showFeedComposeSheet(context),
                              icon: Icon(Icons.edit_outlined, color: c.primary, size: 22),
                              tooltip: 'Create post',
                            ),
                          ),
                          const SizedBox(width: 4),
                          SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(value: 'all', label: Text('Public', style: TextStyle(fontSize: 11))),
                              ButtonSegment(value: 'mine', label: Text('My Posts', style: TextStyle(fontSize: 11))),
                            ],
                            selected: {filter},
                            onSelectionChanged: (s) => onFilterChanged(s.first),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.listGap),
                      if (posts.isEmpty)
                        AppEmptyState(
                          compact: true,
                          icon: Icons.forum_outlined,
                          heading: 'Nothing here yet',
                          body: filter == 'mine'
                              ? 'Share a PR, meal, or motivation tip to earn XP'
                              : 'Be the first to post today',
                          ctaLabel: 'Share something',
                          onCta: () => showFeedComposeSheet(context),
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
                          final likeLabel = liked ? 'Unlike, ${likes.length} likes' : 'Like, ${likes.length} likes';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: t.elevated,
                                borderRadius: BorderRadius.circular(AppRadius.card),
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
                                      Icon(_postIcon(postType), size: 16, color: c.primary),
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
                                    label: likeLabel,
                                    child: InkWell(
                                      onTap: () => state.toggleFeedLike('${p['id']}'),
                                      child: Text('${liked ? '❤️' : '🤍'} ${likes.length}', style: TextStyle(fontSize: 12, color: t.textMuted)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.listGap),
            StaggeredEntry(
              index: 1,
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.emoji_events, color: c.sand, size: 20),
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
                                      Text('• ', style: TextStyle(color: c.primary, fontWeight: FontWeight.w700)),
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
    final c = context.appColors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: highlight ? c.primaryTintBg : t.elevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: highlight ? c.primaryTintBorder : t.borderSubtle),
        ),
        child: Row(
          children: [
            Text(
              '#$rank',
              style: TextStyle(
                color: rank == 1 ? c.primary : t.textMuted,
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
              Icon(Icons.lock_outline, size: 14, color: c.sand)
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: c.primaryTintBg,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: c.primaryTintBorder),
                ),
                child: Text(
                  '$xp XP',
                  style: TextStyle(color: c.primaryDim, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
