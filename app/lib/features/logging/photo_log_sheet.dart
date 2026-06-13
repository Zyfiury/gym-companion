import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/navigation/app_router.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/skeletons.dart';
import '../../providers/app_state.dart';
import '../../services/meal_photo_service.dart';
import '../../services/photo_nutrition_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/sheet_padding.dart';
import 'food_search_sheet.dart';

Future<void> showPhotoLogSheet(BuildContext context) async {
  final picker = ImagePicker();
  final file = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
  if (file == null || !context.mounted) return;

  await AppRouter.pushModal(
    context,
    _PhotoLogConfirmPage(image: File(file.path)),
  );
}

class _PhotoLogConfirmPage extends StatelessWidget {
  final File image;
  const _PhotoLogConfirmPage({required this.image});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.bgBase,
      body: SafeArea(
        child: _PhotoLogConfirm(image: image),
      ),
    );
  }
}

class _PhotoLogConfirm extends StatefulWidget {
  final File image;
  const _PhotoLogConfirm({required this.image});

  @override
  State<_PhotoLogConfirm> createState() => _PhotoLogConfirmState();
}

class _PhotoLogConfirmState extends State<_PhotoLogConfirm> {
  PhotoNutritionResult? _result;
  bool _loading = true;
  double _portion = 1.0;
  late String _mealName;
  final Map<int, double> _itemGrams = {};

  static const _portionOptions = [
    (value: 0.5, label: 'Half portion'),
    (value: 0.75, label: '¾ portion'),
    (value: 1.0, label: 'Standard'),
    (value: 1.5, label: 'Large'),
    (value: 2.0, label: 'Double'),
  ];

  @override
  void initState() {
    super.initState();
    _mealName = '';
    _analyse();
  }

  Future<void> _analyse() async {
    final result = await PhotoNutritionService.analyze(widget.image);
    if (!mounted) return;
    for (var i = 0; i < result.items.length; i++) {
      _itemGrams[i] = result.items[i].estimatedGrams;
    }
    setState(() {
      _result = result;
      _mealName = result.mealName;
      _loading = false;
    });
  }

  PhotoNutritionResult get _scaled {
    final base = _result!;
    final items = base.items.asMap().entries.map((e) {
      final g = _itemGrams[e.key] ?? e.value.estimatedGrams;
      final ratio = e.value.estimatedGrams > 0 ? g / e.value.estimatedGrams : 1.0;
      return PhotoNutritionItem(
        name: e.value.name,
        estimatedGrams: g,
        calories: (e.value.calories * ratio * _portion).round(),
      );
    }).toList();
    final scaled = PhotoNutritionService.scale(base, _portion);
    return PhotoNutritionResult(
      mealName: _mealName,
      estimatedCalories: scaled.estimatedCalories,
      confidence: scaled.confidence,
      protein: scaled.protein,
      carbs: scaled.carbs,
      fat: scaled.fat,
      fiber: scaled.fiber,
      sugar: scaled.sugar,
      sodiumMg: scaled.sodiumMg,
      items: items,
      portionNote: scaled.portionNote,
      error: scaled.error,
    );
  }

  Future<void> _editGrams(int index, PhotoNutritionItem item) async {
    final c = context.appColors;
    var grams = _itemGrams[index] ?? item.estimatedGrams;
    await showModalBottomSheet(
      context: context,
      backgroundColor: context.appTheme.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: sheetInsets(ctx),
        child: StatefulBuilder(
          builder: (ctx, setLocal) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.name, style: TextStyle(fontWeight: FontWeight.w600, color: c.textPrimary)),
              const SizedBox(height: 16),
              Text('${grams.round()}g', style: GoogleFonts.gloock(fontSize: 28, color: c.textPrimary)),
              Slider(
                value: grams.clamp(50, 500),
                min: 50,
                max: 500,
                divisions: 45,
                activeColor: c.primary,
                onChanged: (v) => setLocal(() => grams = v),
              ),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    setState(() => _itemGrams[index] = grams);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final c = context.appColors;

    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            SkeletonCard(height: 200),
            SizedBox(height: 16),
            SkeletonText(width: 180, height: 14),
          ],
        ),
      );
    }

    final scaled = _scaled;
    final conf = scaled.confidence;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: sheetInsets(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(widget.image, width: 80, height: 80, fit: BoxFit.cover),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () async {
                              final ctrl = TextEditingController(text: _mealName);
                              final name = await showDialog<String>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Edit meal name'),
                                  content: TextField(controller: ctrl, autofocus: true),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                    FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Save')),
                                  ],
                                ),
                              );
                              if (name != null && name.isNotEmpty) setState(() => _mealName = name);
                            },
                            child: Text(
                              _mealName,
                              style: GoogleFonts.gloock(fontSize: 22, color: t.textPrimary),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _ConfidencePill(confidence: conf),
                        ],
                      ),
                    ),
                  ],
                ),
                if (scaled.items.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text('DETECTED ITEMS', style: TextStyle(fontSize: 11, letterSpacing: 0.88, color: t.textMuted)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: scaled.items.asMap().entries.map((e) {
                      final g = _itemGrams[e.key] ?? e.value.estimatedGrams;
                      return ActionChip(
                        label: Text('${e.value.name} · ${g.round()}g'),
                        onPressed: () => _editGrams(e.key, e.value),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 20),
                Text('PORTION', style: TextStyle(fontSize: 11, letterSpacing: 0.88, color: t.textMuted)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _portionOptions.map((e) {
                    final selected = _portion == e.value;
                    return ChoiceChip(
                      label: Text(e.label),
                      selected: selected,
                      onSelected: (_) => setState(() => _portion = e.value),
                    );
                  }).toList(),
                ),
                if (scaled.error != null) ...[
                  const SizedBox(height: 12),
                  Text(scaled.error!, style: TextStyle(color: c.error, fontSize: 13)),
                ],
              ],
            ),
          ),
        ),
        Container(
          padding: sheetInsets(context, extra: 16),
          decoration: BoxDecoration(
            color: c.surface,
            border: Border(top: BorderSide(color: c.border)),
          ),
          child: Column(
            children: [
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: scaled.estimatedCalories),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                builder: (_, val, __) => Text(
                  '$val kcal',
                  style: GoogleFonts.gloock(fontSize: 32, color: t.textPrimary),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: conf == PhotoConfidence.low
                      ? null
                      : () async {
                          HapticFeedback.lightImpact();
                          final state = context.read<AppState>();
                          String? photoUrl;
                          if (state.userId != null) {
                            photoUrl = await MealPhotoService.upload(uid: state.userId!, image: widget.image);
                          }
                          await state.addFoodEntry(
                            name: _mealName.trim(),
                            calories: scaled.estimatedCalories,
                            protein: scaled.protein,
                            carbs: scaled.carbs,
                            fat: scaled.fat,
                            fiber: scaled.fiber,
                            sugar: scaled.sugar,
                            sodiumMg: scaled.sodiumMg,
                            source: 'photo',
                            photoUrl: photoUrl,
                          );
                          if (context.mounted) {
                            Navigator.pop(context);
                            AppToast.success(context, 'Meal logged ✓');
                          }
                        },
                  child: Text(conf == PhotoConfidence.low ? 'Edit before logging' : 'Log this meal'),
                ),
              ),
              if (scaled.items.isEmpty && scaled.estimatedCalories == 0)
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    showFoodSearchSheet(context);
                  },
                  child: const Text('Log manually'),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ConfidencePill extends StatelessWidget {
  final PhotoConfidence confidence;
  const _ConfidencePill({required this.confidence});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final (bg, fg, label) = switch (confidence) {
      PhotoConfidence.high => (c.mintDim, c.mint, 'High confidence'),
      PhotoConfidence.medium => (c.sandDim, c.sand, 'Medium confidence'),
      PhotoConfidence.low => (c.errorDim, c.error, 'Low confidence · Edit before logging'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: fg, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
