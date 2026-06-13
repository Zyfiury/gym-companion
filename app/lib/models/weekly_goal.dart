enum GoalType {
  protein,
  calories,
  workouts,
  water,
  steps,
  streak,
  weight,
}

class WeeklyGoal {
  final String id;
  final GoalType type;
  final double targetValue;
  final int targetDays;
  final int daysAchieved;
  final DateTime weekStart;
  final bool isActive;
  final String createdBy;

  const WeeklyGoal({
    required this.id,
    required this.type,
    required this.targetValue,
    required this.targetDays,
    this.daysAchieved = 0,
    required this.weekStart,
    this.isActive = true,
    this.createdBy = 'user',
  });

  String get label => switch (type) {
        GoalType.protein => 'Hit ${targetValue.round()}g protein',
        GoalType.calories => 'Stay within ${targetValue.round()} kcal',
        GoalType.workouts => 'Complete ${targetValue.round()} workouts',
        GoalType.water => 'Drink ${targetValue.round()}L water',
        GoalType.steps => 'Walk ${targetValue.round()} steps',
        GoalType.streak => 'Keep a ${targetValue.round()}-day streak',
        GoalType.weight => 'Reach ${targetValue.toStringAsFixed(1)} kg',
      };

  String get progressLabel => '$daysAchieved of $targetDays days done';

  double get progress => targetDays > 0 ? (daysAchieved / targetDays).clamp(0.0, 1.0) : 0;

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'targetValue': targetValue,
        'targetDays': targetDays,
        'daysAchieved': daysAchieved,
        'weekStart': weekStart.toIso8601String().substring(0, 10),
        'isActive': isActive,
        'createdBy': createdBy,
      };

  factory WeeklyGoal.fromJson(String id, Map<String, dynamic> j) => WeeklyGoal(
        id: id,
        type: GoalType.values.firstWhere(
          (t) => t.name == j['type'],
          orElse: () => GoalType.protein,
        ),
        targetValue: (j['targetValue'] as num?)?.toDouble() ?? 0,
        targetDays: j['targetDays'] as int? ?? 5,
        daysAchieved: j['daysAchieved'] as int? ?? 0,
        weekStart: DateTime.tryParse(j['weekStart'] as String? ?? '') ?? _weekStart(),
        isActive: j['isActive'] as bool? ?? true,
        createdBy: j['createdBy'] as String? ?? 'user',
      );

  WeeklyGoal copyWith({
    int? daysAchieved,
    bool? isActive,
  }) =>
      WeeklyGoal(
        id: id,
        type: type,
        targetValue: targetValue,
        targetDays: targetDays,
        daysAchieved: daysAchieved ?? this.daysAchieved,
        weekStart: weekStart,
        isActive: isActive ?? this.isActive,
        createdBy: createdBy,
      );

  static DateTime _weekStart() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return DateTime(monday.year, monday.month, monday.day);
  }
}
