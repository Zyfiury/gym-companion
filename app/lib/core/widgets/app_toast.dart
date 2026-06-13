import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';

class AppToast {
  AppToast._();

  static OverlayEntry? _current;

  static void show(
    BuildContext context,
    String message, {
    bool isSuccess = true,
    Duration? duration,
    HapticFeedbackType haptic = HapticFeedbackType.light,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    // Toasts with an action stay longer so the button is tappable.
    final visible = duration ?? (actionLabel != null ? const Duration(seconds: 5) : const Duration(seconds: 2));
    _current?.remove();
    _current = null;

    switch (haptic) {
      case HapticFeedbackType.light:
        HapticFeedback.lightImpact();
      case HapticFeedbackType.medium:
        HapticFeedback.mediumImpact();
      case HapticFeedbackType.heavy:
        HapticFeedback.heavyImpact();
      case HapticFeedbackType.none:
        break;
    }

    final overlay = Overlay.of(context);
    final c = context.appColors;
    final bg = isSuccess ? c.primary : c.error;
    final fg = c.onPrimary;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _ToastWidget(
        message: message,
        isSuccess: isSuccess,
        background: bg,
        foreground: fg,
        visibleFor: visible,
        actionLabel: actionLabel,
        onAction: onAction,
        onDismiss: () {
          entry.remove();
          if (_current == entry) _current = null;
        },
      ),
    );
    _current = entry;
    overlay.insert(entry);
    Future.delayed(visible + const Duration(milliseconds: 400), () {
      if (entry.mounted) entry.remove();
      if (_current == entry) _current = null;
    });
  }

  static void success(
    BuildContext context,
    String message, {
    HapticFeedbackType haptic = HapticFeedbackType.light,
    String? actionLabel,
    VoidCallback? onAction,
  }) =>
      show(context, message, isSuccess: true, haptic: haptic, actionLabel: actionLabel, onAction: onAction);

  static void error(BuildContext context, String message) =>
      show(context, message, isSuccess: false, haptic: HapticFeedbackType.medium);
}

enum HapticFeedbackType { none, light, medium, heavy }

class _ToastWidget extends StatefulWidget {
  final String message;
  final bool isSuccess;
  final Color background;
  final Color foreground;
  final Duration visibleFor;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onDismiss;

  const _ToastWidget({
    required this.message,
    required this.isSuccess,
    required this.background,
    required this.foreground,
    required this.visibleFor,
    this.actionLabel,
    this.onAction,
    required this.onDismiss,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _slide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
    Future.delayed(widget.visibleFor - const Duration(milliseconds: 200), () async {
      if (!mounted) return;
      await _ctrl.reverse();
      widget.onDismiss();
    });
  }

  void _handleAction() {
    widget.onAction?.call();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: MediaQuery.paddingOf(context).bottom + 24,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Material(
                color: widget.background,
                elevation: 6,
                borderRadius: BorderRadius.circular(100),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.isSuccess ? Icons.check_circle_outline : Icons.error_outline,
                        size: 16,
                        color: widget.foreground,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          widget.message,
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: widget.foreground,
                          ),
                        ),
                      ),
                      if (widget.actionLabel != null) ...[
                        const SizedBox(width: 10),
                        InkWell(
                          onTap: _handleAction,
                          borderRadius: BorderRadius.circular(100),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: widget.foreground.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              widget.actionLabel!,
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: widget.foreground,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
