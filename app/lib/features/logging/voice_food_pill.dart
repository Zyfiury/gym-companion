import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../services/voice_food_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/barcode_confirm_sheet.dart';
import '../../core/widgets/app_toast.dart';

/// Prominent voice-log entry on the Food tab - tap to record immediately.
class VoiceFoodPill extends StatefulWidget {
  const VoiceFoodPill({super.key});

  @override
  State<VoiceFoodPill> createState() => _VoiceFoodPillState();
}

class _VoiceFoodPillState extends State<VoiceFoodPill> {
  final _speech = SpeechToText();
  bool _listening = false;
  String _transcript = '';

  Future<void> _stop() async {
    await _speech.stop();
    if (mounted) setState(() => _listening = false);
  }

  Future<void> _start() async {
    if (_listening) {
      await _stop();
      return;
    }
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      if (mounted) AppToast.error(context, 'Microphone permission required');
      return;
    }
    if (!await _speech.initialize()) {
      if (mounted) AppToast.error(context, 'Speech recognition unavailable');
      return;
    }
    setState(() {
      _listening = true;
      _transcript = '';
    });
    await _speech.listen(
      onResult: (r) async {
        if (!mounted) return;
        setState(() => _transcript = r.recognizedWords.trim());
        if (!r.finalResult) return;
        setState(() => _listening = false);
        final text = r.recognizedWords.trim();
        if (text.isEmpty) return;
        final parsed = await VoiceFoodService.parse(text);
        if (!mounted) return;
        if (parsed.name.isEmpty && parsed.calories == 0) {
          AppToast.error(context, 'Could not understand - try again');
          return;
        }
        await BarcodeConfirmSheet.show(context, parsed.toProductMap());
      },
      listenFor: const Duration(seconds: 12),
      pauseFor: const Duration(seconds: 2),
      localeId: 'en_GB',
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final t = context.appTheme;
    final label = _listening
        ? (_transcript.isEmpty ? 'Listening… tap to stop' : _transcript)
        : 'Tell me what you ate…';

    return Semantics(
      identifier: 'voice-food-pill',
      button: true,
      label: 'Tell me what you ate',
      child: GestureDetector(
        onTap: _start,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _listening ? c.primary.withValues(alpha: 0.08) : c.surface2,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: _listening ? c.primary : c.border),
          ),
          child: Row(
            children: [
              Icon(
                _listening ? Icons.mic : Icons.mic_none_outlined,
                color: c.primary,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: _listening && _transcript.isNotEmpty ? t.textPrimary : t.textMuted,
                    fontStyle: _listening && _transcript.isEmpty ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ),
              if (_listening)
                Icon(Icons.close, size: 18, color: t.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
