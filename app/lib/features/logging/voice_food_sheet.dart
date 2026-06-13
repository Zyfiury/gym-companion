import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../services/voice_food_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/sheet_padding.dart';
import '../../widgets/barcode_confirm_sheet.dart';

Future<void> showVoiceFoodSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.appTheme.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => const _VoiceFoodSheet(),
  );
}

class _VoiceFoodSheet extends StatefulWidget {
  const _VoiceFoodSheet();

  @override
  State<_VoiceFoodSheet> createState() => _VoiceFoodSheetState();
}

class _VoiceFoodSheetState extends State<_VoiceFoodSheet> {
  final _speech = SpeechToText();
  bool _listening = false;
  bool _parsing = false;
  String _transcript = '';

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  Future<void> _toggleListen() async {
    if (_listening) {
      await _speech.stop();
      return;
    }
    final status = await Permission.microphone.request();
    if (!status.isGranted) return;
    final available = await _speech.initialize(
      onStatus: (s) {
        if (s == 'done' || s == 'notListening') {
          if (mounted) setState(() => _listening = false);
        }
      },
    );
    if (!available) return;
    setState(() {
      _listening = true;
      _transcript = '';
    });
    await _speech.listen(
      onResult: (r) {
        setState(() => _transcript = r.recognizedWords);
        if (r.finalResult) _speech.stop();
      },
      localeId: 'en_GB',
    );
  }

  Future<void> _parseAndConfirm() async {
    final text = _transcript.trim();
    if (text.isEmpty) return;
    setState(() => _parsing = true);
    final result = await VoiceFoodService.parse(text);
    if (!mounted) return;
    setState(() => _parsing = false);
    if (result.name.isEmpty && result.calories == 0) return;

    Navigator.pop(context);
    await BarcodeConfirmSheet.show(context, result.toProductMap());
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final c = context.appColors;

    return Padding(
      padding: sheetInsets(context, horizontal: 20, top: 20, extra: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(AppRadius.pill)),
            ),
          ),
          Text('Voice log', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: t.textPrimary)),
          const SizedBox(height: 8),
          Text('Say what you ate - we\'ll estimate the macros', style: TextStyle(fontSize: 13, color: t.textSecondary)),
          const SizedBox(height: 20),
          Semantics(
            identifier: 'voice-food-mic',
            button: true,
            label: _listening ? 'Stop listening' : 'Start listening',
            child: Center(
              child: Material(
                color: _listening ? c.primaryGlow : c.surface2,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _parsing ? null : _toggleListen,
                  child: SizedBox(
                    width: 72,
                    height: 72,
                    child: Icon(
                      _listening ? Icons.stop_rounded : Icons.mic_outlined,
                      size: 28,
                      color: _listening ? c.primary : t.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_transcript.isNotEmpty)
            Text(_transcript, style: TextStyle(fontSize: 15, color: t.textPrimary)),
          if (_listening)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text('Listening…', style: TextStyle(fontSize: 12, color: t.textMuted)),
            ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _parsing || _transcript.trim().isEmpty ? null : _parseAndConfirm,
              child: Text(_parsing ? 'Parsing…' : 'Look up & log'),
            ),
          ),
        ],
      ),
    );
  }
}
