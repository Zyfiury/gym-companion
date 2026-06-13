import 'package:flutter/material.dart';

/// Brief skeleton placeholder on first tab paint (polish pass).
class TabLoadGate extends StatefulWidget {
  final Widget skeleton;
  final Widget child;
  final Duration delay;

  const TabLoadGate({
    super.key,
    required this.skeleton,
    required this.child,
    this.delay = const Duration(milliseconds: 380),
  });

  @override
  State<TabLoadGate> createState() => _TabLoadGateState();
}

class _TabLoadGateState extends State<TabLoadGate> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return widget.skeleton;
    return widget.child;
  }
}
