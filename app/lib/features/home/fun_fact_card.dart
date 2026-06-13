import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../providers/app_state.dart';
import '../../services/fun_facts_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/premium_ui.dart';

/// One personal insight per day - or a fresh fact after a workout/log.
class FunFactCard extends StatelessWidget {
  const FunFactCard({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final c = context.appColors;
    final state = context.watch<AppState>();
    final u = state.user!;

    final fresh = state.freshFunFact;
    final fact = fresh ??
        FunFactsService.dailyFact(
          user: u,
          dailyLogsHistory: state.dailyLogsHistory,
          displayName: state.displayName,
        );
    if (fact == null) return const SizedBox.shrink();

    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(fact.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          fresh != null ? 'Fresh insight' : 'Did you know?',
                          style: TextStyle(fontSize: 11, letterSpacing: 0.6, color: c.primary, fontWeight: FontWeight.w700),
                        ),
                        if (fresh != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: c.mintDim,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text('New', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: c.mint)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      fact.text,
                      style: TextStyle(fontSize: 13.5, height: 1.45, color: t.textPrimary, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_horiz, color: t.textMuted, size: 20),
                onSelected: (v) {
                  if (v == 'share') {
                    Share.share('${fact.emoji} ${fact.text}');
                  } else if (v == 'dismiss' && fresh != null) {
                    state.clearFreshFunFact();
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'share', child: Text('Share')),
                  if (fresh != null) const PopupMenuItem(value: 'dismiss', child: Text('Dismiss')),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
