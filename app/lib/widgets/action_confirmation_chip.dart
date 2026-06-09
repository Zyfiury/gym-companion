import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ActionConfirmationChip extends StatelessWidget {
  final String text;
  const ActionConfirmationChip({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.hydroTintBg,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppColors.hydroTintBorder),
      ),
      child: Text(text, style: const TextStyle(fontSize: 11, color: AppColors.hydro, fontWeight: FontWeight.w500)),
    );
  }
}
