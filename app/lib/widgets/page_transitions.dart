import 'package:flutter/material.dart';

import '../core/navigation/app_router.dart';

export '../core/navigation/app_router.dart';

/// Standard push - slide from right.
Future<T?> pushPremium<T>(BuildContext context, Widget page) =>
    AppRouter.pushSlide<T>(context, page);

/// Modal push - slide from bottom (paywall, sheets as routes).
Future<T?> pushModal<T>(BuildContext context, Widget page) =>
    AppRouter.pushModal<T>(context, page);

/// Fade push - auth / splash transitions.
Future<T?> pushFade<T>(BuildContext context, Widget page) =>
    AppRouter.pushFade<T>(context, page);
