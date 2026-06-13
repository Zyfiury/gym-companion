import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// XP progress toward next level with smooth fill and level-up overshoot.
class AnimatedXpBar extends StatefulWidget {
  final int xp;
  final int level;
  final double height;

  const AnimatedXpBar({
    super.key,
    required this.xp,
    required this.level,
    this.height = 6,
  });

  @override
  State<AnimatedXpBar> createState() => _AnimatedXpBarState();
}

class _AnimatedXpBarState extends State<AnimatedXpBar> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  int _lastXp = 0;
  int _lastLevel = 1;

  double get _target => (widget.xp % 100) / 100.0;

  @override
  void initState() {
    super.initState();
    _lastXp = widget.xp;
    _lastLevel = widget.level;
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _anim = Tween<double>(begin: 0, end: _target).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(AnimatedXpBar old) {
    super.didUpdateWidget(old);
    if (widget.level > _lastLevel) {
      _runLevelUp();
    } else if (widget.xp != _lastXp) {
      _anim = Tween<double>(begin: _anim.value, end: _target)
          .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
      _ctrl.forward(from: 0);
    }
    _lastXp = widget.xp;
    _lastLevel = widget.level;
  }

  Future<void> _runLevelUp() async {
    final seq = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: _anim.value, end: 1.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: _target), weight: 40),
    ]);
    _anim = seq.animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    await _ctrl.forward(from: 0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: _anim.value.clamp(0.0, 1.0),
          minHeight: widget.height,
          backgroundColor: context.appTheme.progressTrack,
          color: c.xpBarColors.first,
        ),
      ),
    );
  }
}
