class ProgressionEvent {
  final String exerciseId;
  final String exerciseName;
  final double suggestedWeightKg;
  final String message;
  final DateTime date;

  const ProgressionEvent({
    required this.exerciseId,
    required this.exerciseName,
    required this.suggestedWeightKg,
    required this.message,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'exerciseId': exerciseId,
        'exerciseName': exerciseName,
        'suggestedWeightKg': suggestedWeightKg,
        'message': message,
        'date': date.toIso8601String().substring(0, 10),
      };

  factory ProgressionEvent.fromJson(Map<String, dynamic> j) => ProgressionEvent(
        exerciseId: j['exerciseId'] as String? ?? '',
        exerciseName: j['exerciseName'] as String? ?? '',
        suggestedWeightKg: (j['suggestedWeightKg'] as num?)?.toDouble() ?? 0,
        message: j['message'] as String? ?? '',
        date: DateTime.tryParse(j['date'] as String? ?? '') ?? DateTime.now(),
      );
}
