import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../theme/app_theme.dart';

class RestTimerController extends ChangeNotifier {
  Timer? _timer;
  int _secondsLeft = 0;
  String? _exerciseName;
  bool get isActive => _secondsLeft > 0;
  int get secondsLeft => _secondsLeft;
  String? get exerciseName => _exerciseName;

  void start({required int seconds, String? exerciseName}) {
    _timer?.cancel();
    _secondsLeft = seconds;
    _exerciseName = exerciseName;
    notifyListeners();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsLeft <= 1) {
        _timer?.cancel();
        _secondsLeft = 0;
        HapticFeedback.mediumImpact();
        notifyListeners();
        return;
      }
      _secondsLeft--;
      notifyListeners();
    });
  }

  void skip() {
    _timer?.cancel();
    _secondsLeft = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

class RestTimerPill extends StatelessWidget {
  const RestTimerPill({super.key});

  String _format(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final c = context.appColors;
    final timer = context.watch<RestTimerController>();
    if (!timer.isActive) return const SizedBox.shrink();

    return Semantics(
      identifier: 'rest-timer-pill',
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: c.surface2,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: c.border),
          boxShadow: c.cardShadow,
        ),
        child: Row(
          children: [
            Text('Rest', style: TextStyle(fontWeight: FontWeight.w500, color: c.primary)),
            const SizedBox(width: 12),
            Text(_format(timer.secondsLeft), style: TextStyle(fontFamily: 'DM Mono', color: t.textPrimary, fontSize: 16)),
            const Spacer(),
            TextButton(
              onPressed: timer.skip,
              child: Text('Skip', style: TextStyle(color: c.primary)),
            ),
          ],
        ),
      ),
    );
  }
}
