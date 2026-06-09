import 'package:flutter/material.dart';

/// Shared-axis fade + slide page transition (Framer Motion style).
class SharedAxisPageRoute<T> extends PageRouteBuilder<T> {
  SharedAxisPageRoute({required Widget page, bool horizontal = true})
      : super(
          pageBuilder: (_, __, ___) => page,
          transitionDuration: const Duration(milliseconds: 320),
          reverseTransitionDuration: const Duration(milliseconds: 280),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
            final offset = horizontal ? const Offset(0.08, 0) : const Offset(0, 0.06);
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(begin: offset, end: Offset.zero).animate(curved),
                child: child,
              ),
            );
          },
        );
}

Future<T?> pushPremium<T>(BuildContext context, Widget page, {bool horizontal = true}) {
  return Navigator.push<T>(context, SharedAxisPageRoute<T>(page: page, horizontal: horizontal));
}
