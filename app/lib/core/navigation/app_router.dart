import 'package:flutter/material.dart';

/// Premium page transitions - no default Material white flash.
class AppRouter {
  AppRouter._();

  static Route<T> slide<T>(Widget page) => PageRouteBuilder<T>(
        pageBuilder: (_, __, ___) => page,
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
      );

  static Route<T> modal<T>(Widget page) => PageRouteBuilder<T>(
        opaque: true,
        fullscreenDialog: true,
        pageBuilder: (_, __, ___) => page,
        transitionDuration: const Duration(milliseconds: 380),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween(
            begin: const Offset(0.0, 1.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: FadeTransition(opacity: anim, child: child),
        ),
      );

  static Route<T> fade<T>(Widget page) => PageRouteBuilder<T>(
        pageBuilder: (_, __, ___) => page,
        transitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      );

  static Future<T?> pushSlide<T>(BuildContext context, Widget page) =>
      Navigator.push<T>(context, slide<T>(page));

  static Future<T?> pushModal<T>(BuildContext context, Widget page) =>
      Navigator.push<T>(context, modal<T>(page));

  static Future<T?> pushFade<T>(BuildContext context, Widget page) =>
      Navigator.push<T>(context, fade<T>(page));
}
