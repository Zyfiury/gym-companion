import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_theme.dart';
import 'shimmer_skeleton.dart';

/// Subtle inline loader - replaces raw [CircularProgressIndicator] in buttons and rows.
class InlineLoading extends StatelessWidget {
  final double width;
  final double height;

  const InlineLoading({super.key, this.width = 20, this.height = 20});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Shimmer.fromColors(
      baseColor: c.surface2,
      highlightColor: c.surface,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: c.surface2,
          borderRadius: BorderRadius.circular(height / 2),
        ),
      ),
    );
  }
}

/// Full-width content placeholder while async data loads.
class ContentLoadingSkeleton extends StatelessWidget {
  final int lines;

  const ContentLoadingSkeleton({super.key, this.lines = 3});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(
        lines,
        (i) => Padding(
          padding: EdgeInsets.only(bottom: i < lines - 1 ? 10 : 0),
          child: ShimmerSkeleton(
            width: i == 0 ? double.infinity : (i == 1 ? 220 : 160),
            height: i == 0 ? 18 : 14,
          ),
        ),
      ),
    );
  }
}
