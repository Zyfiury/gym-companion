import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../utils/auth_validator.dart';

class PasswordStrengthMeter extends StatelessWidget {
  final String password;
  final bool showRequirements;

  const PasswordStrengthMeter({
    super.key,
    required this.password,
    this.showRequirements = true,
  });

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();

    final t = context.appTheme;
    final c = context.appColors;
    final req = PasswordRequirements.evaluate(password);
    final strength = AuthValidator.passwordStrength(password);
    final strengthLabel = switch (strength) {
      PasswordStrength.weak => 'Weak',
      PasswordStrength.fair => 'Fair',
      PasswordStrength.strong => 'Strong',
    };
    final strengthColor = switch (strength) {
      PasswordStrength.weak => c.error,
      PasswordStrength.fair => c.sand,
      PasswordStrength.strong => c.mint,
    };
    final fill = switch (strength) {
      PasswordStrength.weak => 0.33,
      PasswordStrength.fair => 0.66,
      PasswordStrength.strong => 1.0,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: fill,
                  minHeight: 4,
                  backgroundColor: t.progressTrack,
                  color: strengthColor,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              strengthLabel,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: strengthColor),
            ),
          ],
        ),
        if (showRequirements) ...[
          const SizedBox(height: 10),
          _RequirementRow(label: 'At least ${AuthValidator.minPasswordLength} characters', met: req.minLength),
          _RequirementRow(label: 'One uppercase letter', met: req.hasUppercase),
          _RequirementRow(label: 'One lowercase letter', met: req.hasLowercase),
          _RequirementRow(label: 'One number', met: req.hasNumber),
          _RequirementRow(label: 'One special character (!@#…)', met: req.hasSpecial),
        ],
      ],
    );
  }
}

class _RequirementRow extends StatelessWidget {
  final String label;
  final bool met;

  const _RequirementRow({required this.label, required this.met});

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final c = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 16,
            color: met ? c.mint : t.textMuted,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: met ? t.textSecondary : t.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
