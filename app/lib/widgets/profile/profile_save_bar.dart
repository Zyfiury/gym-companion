import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../gradient_button.dart';

class ProfileSaveBar extends StatelessWidget {
  final String label;
  final VoidCallback onSave;
  final String? semanticsId;

  const ProfileSaveBar({
    super.key,
    this.label = 'Save changes',
    required this.onSave,
    this.semanticsId,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + MediaQuery.paddingOf(context).bottom),
      decoration: BoxDecoration(
        color: t.scaffold.withValues(alpha: 0.95),
        border: Border(top: BorderSide(color: t.borderSubtle.withValues(alpha: 0.5))),
      ),
      child: Semantics(
        identifier: semanticsId,
        button: true,
        child: GradientButton(label: label, onPressed: onSave, expanded: true),
      ),
    );
  }
}
