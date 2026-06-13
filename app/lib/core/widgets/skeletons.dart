import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class SkeletonBox extends StatefulWidget {
  final double width;
  final double height;
  final double radius;

  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.radius = 12,
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Color?> _color;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final c = context.appColors;
    _color = ColorTween(begin: c.surface2, end: c.surface3).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _color,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: _color.value ?? context.appColors.surface2,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

class SkeletonCard extends StatelessWidget {
  final double height;

  const SkeletonCard({super.key, this.height = 100});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      width: double.infinity,
      height: height,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.appTheme.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: c.border),
        boxShadow: c.cardShadow,
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(width: 120, height: 14),
          SizedBox(height: 12),
          SkeletonBox(width: double.infinity, height: 12),
          SizedBox(height: 8),
          SkeletonBox(width: 180, height: 12),
        ],
      ),
    );
  }
}

class SkeletonText extends StatelessWidget {
  final double width;
  final double height;

  const SkeletonText({super.key, this.width = 120, this.height = 12});

  @override
  Widget build(BuildContext context) => SkeletonBox(width: width, height: height, radius: 6);
}

class SkeletonMacroBar extends StatelessWidget {
  const SkeletonMacroBar({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        SkeletonBox(width: double.infinity, height: 5, radius: 4),
        SizedBox(height: 10),
        SkeletonBox(width: double.infinity, height: 5, radius: 4),
        SizedBox(height: 10),
        SkeletonBox(width: double.infinity, height: 5, radius: 4),
      ],
    );
  }
}

class SkeletonWorkoutItem extends StatelessWidget {
  const SkeletonWorkoutItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SkeletonBox(width: 44, height: 44, radius: 12),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 160, height: 14),
                SizedBox(height: 8),
                SkeletonBox(width: 100, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SkeletonFeedPost extends StatelessWidget {
  const SkeletonFeedPost({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(width: 40, height: 40, radius: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 120, height: 14),
                SizedBox(height: 8),
                SkeletonBox(width: double.infinity, height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
