import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../services/plate_calculator_service.dart';
import '../../core/navigation/app_router.dart';
import '../../theme/app_theme.dart';
import '../../utils/sheet_padding.dart';

Future<void> showPlateCalculatorSheet(
  BuildContext context, {
  double? initialWeightKg,
}) {
  return AppRouter.pushModal(
    context,
    Scaffold(
      backgroundColor: context.appColors.bgBase,
      appBar: AppBar(
        backgroundColor: context.appColors.bgBase,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: context.appColors.textMuted),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Plate calculator', style: TextStyle(color: context.appColors.textPrimary)),
      ),
      body: _PlateCalculatorBody(initialWeightKg: initialWeightKg),
    ),
  );
}

class _PlateCalculatorBody extends StatefulWidget {
  final double? initialWeightKg;
  const _PlateCalculatorBody({this.initialWeightKg});

  @override
  State<_PlateCalculatorBody> createState() => _PlateCalculatorBodyState();
}

class _PlateCalculatorBodyState extends State<_PlateCalculatorBody> {
  late final TextEditingController _weightCtrl;
  double _barWeight = 20;

  @override
  void initState() {
    super.initState();
    final userBar = context.read<AppState>().user?.barWeightKg ?? 20;
    _barWeight = userBar;
    _weightCtrl = TextEditingController(
      text: widget.initialWeightKg?.toStringAsFixed(1) ?? '',
    );
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    super.dispose();
  }

  Color _plateColor(String key, AppColorsExtension c) => switch (key) {
        'red' => c.error,
        'blue' => c.dusk,
        'yellow' => c.sand,
        'green' => c.mint,
        'grey' => c.textMuted,
        'black' => c.textPrimary,
        _ => c.surface3,
      };

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final c = context.appColors;
    final target = double.tryParse(_weightCtrl.text) ?? 0;
    final result = target > 0
        ? PlateCalculatorService.calculate(targetKg: target, barWeightKg: _barWeight)
        : null;

    return Padding(
      padding: sheetInsets(context),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _weightCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Target weight (kg)'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Text('Bar weight', style: TextStyle(color: t.textSecondary, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('20 kg Olympic'),
                  selected: _barWeight == 20,
                  onSelected: (_) => setState(() => _barWeight = 20),
                ),
                ChoiceChip(
                  label: const Text("15 kg Women's"),
                  selected: _barWeight == 15,
                  onSelected: (_) => setState(() => _barWeight = 15),
                ),
              ],
            ),
            if (result != null) ...[
              const SizedBox(height: 20),
              if (result.isClosestMatch)
                Text(
                  'Closest achievable weight',
                  style: TextStyle(color: c.sand, fontSize: 12),
                ),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final plate in result.platesPerSide)
                    Builder(
                      builder: (_) {
                        final spec = PlateCalculatorService.standardPlates
                            .firstWhere((p) => p.kg == plate, orElse: () => const PlateWeight(0, 'light_grey'));
                        return Column(
                          children: [
                            Container(
                              width: plate >= 20 ? 56 : 44,
                              height: plate >= 20 ? 56 : 44,
                              decoration: BoxDecoration(
                                color: _plateColor(spec.colorKey, c),
                                shape: BoxShape.circle,
                                border: Border.all(color: c.border),
                              ),
                              alignment: Alignment.center,
                              child: Text('${plate.toStringAsFixed(plate == plate.roundToDouble() ? 0 : 1)}',
                                  style: TextStyle(color: c.onPrimary, fontSize: 11, fontWeight: FontWeight.w500)),
                            ),
                          ],
                        );
                      },
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                PlateCalculatorService.summaryPerSide(result),
                style: TextStyle(color: t.textSecondary, fontSize: 13),
              ),
              Text(
                'Total: ${result.totalWeight.toStringAsFixed(1)} kg',
                style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
