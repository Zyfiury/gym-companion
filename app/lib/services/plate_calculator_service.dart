class PlateWeight {
  final double kg;
  final String colorKey;

  const PlateWeight(this.kg, this.colorKey);
}

class PlateSideResult {
  final List<double> platesPerSide;
  final double totalPerSide;
  final double barWeight;
  final double totalWeight;
  final bool isClosestMatch;

  const PlateSideResult({
    required this.platesPerSide,
    required this.totalPerSide,
    required this.barWeight,
    required this.totalWeight,
    this.isClosestMatch = false,
  });
}

/// Standard gym plate set - 4 of each size per side rack.
class PlateCalculatorService {
  static const standardPlates = [
    PlateWeight(25, 'red'),
    PlateWeight(20, 'blue'),
    PlateWeight(15, 'yellow'),
    PlateWeight(10, 'green'),
    PlateWeight(5, 'grey'),
    PlateWeight(2.5, 'black'),
    PlateWeight(1.25, 'light_grey'),
  ];

  static const maxPerSize = 4;

  static PlateSideResult calculate({
    required double targetKg,
    double barWeightKg = 20,
  }) {
    final exact = _solve(targetKg, barWeightKg);
    if (exact != null) return exact;

    final closest = _findClosest(targetKg, barWeightKg);
    return closest;
  }

  static PlateSideResult? _solve(double targetKg, double barWeightKg) {
    if (targetKg < barWeightKg) return null;
    final perSide = (targetKg - barWeightKg) / 2;
    if (perSide < 0) return null;

    final remaining = perSide;
    final plates = <double>[];
    final inventory = {for (final p in standardPlates) p.kg: maxPerSize};

    for (final plate in standardPlates) {
      var count = 0;
      while (remaining >= plate.kg - 0.001 && count < inventory[plate.kg]!) {
        final next = _sum(plates) + plate.kg;
        if (next > perSide + 0.001) break;
        plates.add(plate.kg);
        count++;
      }
    }

    final sideTotal = _sum(plates);
    if ((sideTotal - perSide).abs() > 0.01) return null;

    return PlateSideResult(
      platesPerSide: plates,
      totalPerSide: sideTotal,
      barWeight: barWeightKg,
      totalWeight: barWeightKg + sideTotal * 2,
    );
  }

  static PlateSideResult _findClosest(double targetKg, double barWeightKg) {
    var best = barWeightKg;
    var bestPlates = <double>[];

    void search(int plateIndex, double sideLoad, List<double> current) {
      final total = barWeightKg + sideLoad * 2;
      if ((total - targetKg).abs() < (best - targetKg).abs()) {
        best = total;
        bestPlates = List.from(current);
      }
      if (plateIndex >= standardPlates.length) return;
      final plate = standardPlates[plateIndex].kg;
      for (var n = 0; n <= maxPerSize; n++) {
        search(plateIndex + 1, sideLoad + plate * n, [...current, ...List.filled(n, plate)]);
      }
    }

    search(0, 0, []);

    return PlateSideResult(
      platesPerSide: bestPlates,
      totalPerSide: _sum(bestPlates),
      barWeight: barWeightKg,
      totalWeight: best,
      isClosestMatch: true,
    );
  }

  static double _sum(List<double> plates) => plates.fold(0.0, (a, b) => a + b);

  static String summaryPerSide(PlateSideResult result) {
    if (result.platesPerSide.isEmpty) return 'Bar only (${result.barWeight.toStringAsFixed(1)} kg)';
    final grouped = <double, int>{};
    for (final p in result.platesPerSide) {
      grouped[p] = (grouped[p] ?? 0) + 1;
    }
    final parts = grouped.entries.map((e) => '${e.value}×${e.key}kg').join(' + ');
    return '$parts per side';
  }
}
