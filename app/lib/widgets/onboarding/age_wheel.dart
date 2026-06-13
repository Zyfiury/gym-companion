import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/theme/obsidian_palette.dart';
import '../../theme/app_theme.dart';
import 'obsidian_shell.dart';

/// Simple age picker - large value + scroll wheel.
class SimpleAgePicker extends StatelessWidget {
  final int age;
  final ValueChanged<int> onChanged;
  final String? semanticsId;

  const SimpleAgePicker({
    super.key,
    required this.age,
    required this.onChanged,
    this.semanticsId,
  });

  @override
  Widget build(BuildContext context) {
    final o = context.obsidian;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$age',
          style: ObsidianTypography.mono(
            size: ObsidianTokens.heroStatSize + ObsidianTokens.spacingMd,
            color: o.heroAccent,
          ),
        ),
        SizedBox(height: ObsidianTokens.spacingXs),
        Text('years old', style: ObsidianTypography.label(size: 13, color: o.textMuted)),
        SizedBox(height: ObsidianTokens.spacingLg),
        ObsidianGlass(
          padding: EdgeInsets.zero,
          child: SizedBox(
            height: ObsidianTokens.spacingXl * 5,
            child: Semantics(
              identifier: semanticsId,
              child: CupertinoPicker(
                scrollController: FixedExtentScrollController(initialItem: age - 16),
                itemExtent: ObsidianTokens.spacingXl + ObsidianTokens.spacingSm,
                magnification: 1.05,
                useMagnifier: true,
                onSelectedItemChanged: (i) => onChanged(i + 16),
                children: List.generate(
                  65,
                  (i) => Center(
                    child: Text(
                      '${i + 16}',
                      style: ObsidianTypography.mono(
                        size: 22,
                        color: o.textPrimary,
                        weight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
