import 'package:flutter/material.dart';

/// Bottom sheet padding that clears the keyboard and the home indicator.
EdgeInsets sheetInsets(
  BuildContext context, {
  double horizontal = 24,
  double top = 24,
  double extra = 24,
}) {
  final mq = MediaQuery.of(context);
  return EdgeInsets.only(
    left: horizontal,
    right: horizontal,
    top: top,
    bottom: mq.viewInsets.bottom + mq.padding.bottom + extra,
  );
}

/// List/scroll bottom padding above the floating nav bar and home indicator.
double scrollBottomInset(BuildContext context, {double extra = 16}) {
  return MediaQuery.paddingOf(context).bottom + extra;
}
