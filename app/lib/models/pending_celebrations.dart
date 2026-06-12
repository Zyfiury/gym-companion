class PendingPrCelebration {
  final String exercise;
  final double value;
  final String unit;
  final String? recordId;
  final double? previousBest;

  const PendingPrCelebration({
    required this.exercise,
    required this.value,
    required this.unit,
    this.recordId,
    this.previousBest,
  });
}

class PendingTdeeUpdate {
  final int oldTarget;
  final int newTarget;

  const PendingTdeeUpdate({required this.oldTarget, required this.newTarget});
}
