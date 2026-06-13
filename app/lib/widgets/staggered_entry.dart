import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// Fade + slide-up entrance with optional stagger delay.
class StaggeredEntry extends StatefulWidget {
  final Widget child;
  final int index;
  final int baseDelayMs;

  const StaggeredEntry({
    super.key,
    required this.child,
    this.index = 0,
    this.baseDelayMs = 70,
  });

  @override
  State<StaggeredEntry> createState() => _StaggeredEntryState();
}

class _StaggeredEntryState extends State<StaggeredEntry> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: widget.index * widget.baseDelayMs), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

/// Chat messages slide in from their side.
class ChatBubbleEntry extends StatefulWidget {
  final Widget child;
  final bool fromRight;
  final int index;

  const ChatBubbleEntry({super.key, required this.child, this.fromRight = false, this.index = 0});

  @override
  State<ChatBubbleEntry> createState() => _ChatBubbleEntryState();
}

class _ChatBubbleEntryState extends State<ChatBubbleEntry> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: Offset(widget.fromRight ? 0.12 : -0.12, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _scale = Tween<double>(begin: 0.92, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    Future.delayed(Duration(milliseconds: widget.index * 40), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: ScaleTransition(scale: _scale, child: widget.child),
      ),
    );
  }
}

/// Soft glow ring - plays once on appear, does not loop.
class PulseGlow extends StatefulWidget {
  final Widget child;
  final Color? color;
  final double size;

  const PulseGlow({super.key, required this.child, this.color, this.size = 56});

  @override
  State<PulseGlow> createState() => _PulseGlowState();
}

class _PulseGlowState extends State<PulseGlow> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final glowColor = widget.color ?? context.appColors.primary;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        final t = _ctrl.value;
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: widget.size + 16 + t * 12,
              height: widget.size + 16 + t * 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: glowColor.withValues(alpha: 0.12 * (1 - t)),
              ),
            ),
            Container(
              width: widget.size + 8,
              height: widget.size + 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: glowColor.withValues(alpha: 0.08),
              ),
            ),
            child!,
          ],
        );
      },
      child: widget.child,
    );
  }
}

/// Three bouncing dots for typing indicator.
class BouncingDots extends StatefulWidget {
  final Color? color;
  final double size;

  const BouncingDots({super.key, this.color, this.size = 7});

  @override
  State<BouncingDots> createState() => _BouncingDotsState();
}

class _BouncingDotsState extends State<BouncingDots> with TickerProviderStateMixin {
  late final List<AnimationController> _ctrls;

  @override
  void initState() {
    super.initState();
    _ctrls = List.generate(3, (i) {
      final c = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
      Future.delayed(Duration(milliseconds: i * 120), () {
        if (mounted) c.repeat(reverse: true);
      });
      return c;
    });
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dotColor = widget.color ?? context.appColors.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _ctrls[i],
          builder: (_, child) => Transform.translate(
            offset: Offset(0, -6 * _ctrls[i].value),
            child: child,
          ),
          child: Container(
            margin: EdgeInsets.only(right: i < 2 ? 5 : 0),
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(color: dotColor.withValues(alpha: 0.5 + i * 0.15), shape: BoxShape.circle),
          ),
        );
      }),
    );
  }
}

/// Macro ring that animates fill on first build.
class AnimatedMacroRing extends StatefulWidget {
  final double progress;
  final String value;
  final String label;
  final Color color;
  final double size;
  final int pulseTrigger;

  const AnimatedMacroRing({
    super.key,
    required this.progress,
    required this.value,
    required this.label,
    required this.color,
    this.size = 120,
    this.pulseTrigger = 0,
  });

  @override
  State<AnimatedMacroRing> createState() => _AnimatedMacroRingState();
}

class _AnimatedMacroRingState extends State<AnimatedMacroRing> with TickerProviderStateMixin {
  late AnimationController _ctrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _anim;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _pulseAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.03), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.03, end: 1.0), weight: 50),
    ]).animate(_pulseCtrl);
    _anim = Tween<double>(begin: 0, end: widget.progress.clamp(0.0, 1.0))
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void didUpdateWidget(AnimatedMacroRing old) {
    super.didUpdateWidget(old);
    if (old.progress != widget.progress) {
      _anim = Tween<double>(begin: _anim.value, end: widget.progress.clamp(0.0, 1.0))
          .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
      _ctrl.forward(from: 0);
    }
    if (old.pulseTrigger != widget.pulseTrigger && widget.pulseTrigger > 0) {
      _pulseCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    return ScaleTransition(
      scale: _pulseAnim,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _anim,
          builder: (_, child) => Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _MacroRingPainter(
                  progress: _anim.value,
                  color: widget.color,
                  trackColor: context.appColors.surface3,
                  strokeWidth: 9,
                ),
              ),
              child!,
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _AnimatedRingValue(
                value: widget.value,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: t.textPrimary, height: 1),
              ),
              Text(widget.label.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.88, color: t.textMuted)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Soft screen backdrop - no hard shapes, just a whisper of colour at the top.
class AmbientBackground extends StatelessWidget {
  final Widget child;

  const AmbientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final isDark = context.isDarkTheme;

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.55],
                  colors: [
                    Color.alphaBlend(
                      c.primary.withValues(alpha: isDark ? 0.05 : 0.035),
                      c.bgBase,
                    ),
                    c.bgBase,
                  ],
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// Animated progress bar that fills on first build.
class AnimatedProgressBar extends StatefulWidget {
  final double value;
  final Color color;
  final Color trackColor;
  final double height;

  const AnimatedProgressBar({
    super.key,
    required this.value,
    required this.color,
    required this.trackColor,
    this.height = 6,
  });

  @override
  State<AnimatedProgressBar> createState() => _AnimatedProgressBarState();
}

class _AnimatedProgressBarState extends State<AnimatedProgressBar> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _anim = Tween<double>(begin: 0, end: widget.value.clamp(0.0, 1.0))
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void didUpdateWidget(AnimatedProgressBar old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _anim = Tween<double>(begin: _anim.value, end: widget.value.clamp(0.0, 1.0))
          .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) => ClipRRect(
        borderRadius: BorderRadius.circular(widget.height),
        child: LinearProgressIndicator(
          value: _anim.value,
          minHeight: widget.height,
          backgroundColor: widget.trackColor,
          color: widget.color,
        ),
      ),
    );
  }
}

/// Scale-down tap feedback.
class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const PressableScale({super.key, required this.child, this.onTap});

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100), reverseDuration: const Duration(milliseconds: 150));
    _scale = Tween<double>(begin: 1, end: 0.96).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null ? (_) => _ctrl.forward() : null,
      onTapUp: widget.onTap != null
          ? (_) {
              _ctrl.reverse();
              HapticFeedback.lightImpact();
              widget.onTap!();
            }
          : null,
      onTapCancel: widget.onTap != null ? () => _ctrl.reverse() : null,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

class _AnimatedRingValue extends StatefulWidget {
  final String value;
  final TextStyle style;

  const _AnimatedRingValue({required this.value, required this.style});

  @override
  State<_AnimatedRingValue> createState() => _AnimatedRingValueState();
}

class _AnimatedRingValueState extends State<_AnimatedRingValue> {
  int? _numeric;
  int _last = 0;

  int? _parse(String s) => int.tryParse(s.replaceAll(RegExp(r'[^0-9]'), ''));

  @override
  void initState() {
    super.initState();
    _numeric = _parse(widget.value);
    _last = _numeric ?? 0;
  }

  @override
  void didUpdateWidget(_AnimatedRingValue old) {
    super.didUpdateWidget(old);
    final n = _parse(widget.value);
    if (n != null && n != _last) _last = n;
    _numeric = n;
  }

  @override
  Widget build(BuildContext context) {
    final n = _numeric;
    if (n == null) return Text(widget.value, style: widget.style);
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: _last, end: n),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => Text('$v', style: widget.style),
    );
  }
}

class _MacroRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  _MacroRingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final arc = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -3.14159 / 2,
        2 * 3.14159 * progress.clamp(0.0, 1.0),
        false,
        arc,
      );
    }
  }

  @override
  bool shouldRepaint(_MacroRingPainter old) =>
      old.progress != progress || old.color != color || old.trackColor != trackColor;
}
