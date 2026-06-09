import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';

class ShimmerSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;

  const ShimmerSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    return Shimmer.fromColors(
      baseColor: t.elevated,
      highlightColor: t.card,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(color: t.elevated, borderRadius: borderRadius),
      ),
    );
  }
}

class MealCardSkeleton extends StatelessWidget {
  const MealCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ShimmerSkeleton(width: double.infinity, height: 160, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        const SizedBox(height: 16),
        const ShimmerSkeleton(width: 200, height: 20),
        const SizedBox(height: 8),
        const ShimmerSkeleton(width: double.infinity, height: 14),
        const SizedBox(height: 16),
        Row(
          children: List.generate(4, (_) => const Padding(
                padding: EdgeInsets.only(right: 8),
                child: ShimmerSkeleton(width: 56, height: 28, borderRadius: BorderRadius.all(Radius.circular(14))),
              )),
        ),
      ],
    );
  }
}

class FeedPostSkeleton extends StatelessWidget {
  const FeedPostSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerSkeleton(width: 40, height: 40, borderRadius: BorderRadius.all(Radius.circular(20))),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerSkeleton(width: 120, height: 14),
                SizedBox(height: 8),
                ShimmerSkeleton(width: double.infinity, height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
