import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ActionConfirmationChip extends StatelessWidget {
  final String text;
  const ActionConfirmationChip({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.accentTintBg,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: c.accentTintBorder),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, color: c.dusk, fontWeight: FontWeight.w500)),
    );
  }
}
