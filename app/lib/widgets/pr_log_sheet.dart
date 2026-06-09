import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

const _units = ['kg', 'lbs', 'reps', 'seconds', 'minutes'];

Future<void> showPrLogSheet(BuildContext context, {List<String> extraExercises = const []}) {
  final exerciseCtrl = TextEditingController();
  final valueCtrl = TextEditingController();
  var unit = 'kg';
  final options = extraExercises.toList()..sort();

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.appTheme.card,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Log a PR', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: ctx.appTheme.textPrimary)),
              const SizedBox(height: 16),
              TextField(
                controller: exerciseCtrl,
                textCapitalization: TextCapitalization.words,
                style: TextStyle(color: ctx.appTheme.textPrimary),
                decoration: const InputDecoration(labelText: 'Exercise name', hintText: 'e.g. Bench Press'),
              ),
              if (options.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: options.take(10).map((name) {
                    return ActionChip(
                      label: Text(name, style: const TextStyle(fontSize: 11)),
                      onPressed: () => exerciseCtrl.text = name,
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: valueCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(color: ctx.appTheme.textPrimary),
                decoration: const InputDecoration(labelText: 'Weight / reps / time', hintText: 'e.g. 100'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: unit,
                decoration: const InputDecoration(labelText: 'Unit'),
                items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                onChanged: (v) => setLocal(() => unit = v ?? 'kg'),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.white),
                  onPressed: () async {
                    final name = exerciseCtrl.text.trim();
                    final value = double.tryParse(valueCtrl.text.trim());
                    if (name.isEmpty || value == null) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Enter an exercise name and a valid number')),
                      );
                      return;
                    }
                    final chip = await ctx.read<AppState>().logPersonalRecord(
                          exerciseName: name,
                          value: value,
                          unit: unit,
                        );
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      if (chip != null) {
                        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(chip)));
                      }
                    }
                  },
                  child: const Text('Save PR'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ).whenComplete(() {
    exerciseCtrl.dispose();
    valueCtrl.dispose();
  });
}
