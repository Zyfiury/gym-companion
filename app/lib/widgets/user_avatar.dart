import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class UserAvatar extends StatelessWidget {
  final String? imagePath;
  final String name;
  final double radius;
  final bool showGradientFallback;

  const UserAvatar({
    super.key,
    this.imagePath,
    required this.name,
    this.radius = 18,
    this.showGradientFallback = true,
  });

  String _initials(String raw) {
    final parts = raw.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'A';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  bool _hasImage() {
    if (imagePath == null || imagePath!.isEmpty) return false;
    return File(imagePath!).existsSync();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final c = context.appColors;
    final initials = _initials(name.isNotEmpty ? name : 'A');
    final size = radius * 2;

    if (_hasImage()) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: FileImage(File(imagePath!)),
      );
    }

    if (showGradientFallback) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [c.primary, c.sand]),
          shape: BoxShape.circle,
          border: Border.all(color: t.borderSubtle.withValues(alpha: 0.5)),
        ),
        alignment: Alignment.center,
        child: Text(
          initials.length > 2 ? initials.substring(0, 2) : initials,
          style: GoogleFonts.dmSans(
            fontSize: radius * 0.75,
            fontWeight: FontWeight.w700,
            color: c.onPrimary,
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: c.primary.withValues(alpha: 0.15),
      child: Text(
        initials[0],
        style: TextStyle(
          fontSize: radius * 0.7,
          fontWeight: FontWeight.w700,
          color: c.primary,
        ),
      ),
    );
  }
}
