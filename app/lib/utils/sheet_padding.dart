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

/// List/scroll bottom padding above the tab nav bar and home indicator.
double scrollBottomInset(BuildContext context, {double extra = 88}) {
  return MediaQuery.paddingOf(context).bottom + extra;
}

/// Standard tab screen ListView padding (clears 62px nav + margin).
EdgeInsets tabListPadding(BuildContext context) {
  return EdgeInsets.fromLTRB(20, 4, 20, scrollBottomInset(context));
}
