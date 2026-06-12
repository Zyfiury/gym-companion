class ParsedExercise {
  final String name;
  final int sets;
  final int reps;
  final double? weightKg;

  const ParsedExercise({
    required this.name,
    this.sets = 3,
    this.reps = 10,
    this.weightKg,
  });
}

class ExerciseParser {
  static final _setsReps = RegExp(r'(\d+)\s*[×x]\s*(\d+(?:-\d+)?)', caseSensitive: false);
  static final _weightAt = RegExp(r'@\s*([\d.]+)\s*kg', caseSensitive: false);

  static ParsedExercise parse(String raw) {
    final trimmed = raw.trim();
    var name = trimmed;
    var sets = 3;
    var reps = 10;
    double? weightKg;

    final weightMatch = _weightAt.firstMatch(trimmed);
    if (weightMatch != null) {
      weightKg = double.tryParse(weightMatch.group(1)!);
      name = trimmed.substring(0, weightMatch.start).trim();
    }

    final match = _setsReps.firstMatch(trimmed);
    if (match != null) {
      sets = int.tryParse(match.group(1)!) ?? sets;
      final repPart = match.group(2)!;
      reps = int.tryParse(repPart.split('-').first) ?? reps;
      name = trimmed.substring(0, match.start).trim();
    } else {
      name = trimmed.split(RegExp(r'\s+\d')).first.trim();
    }

    if (name.isEmpty) name = trimmed;

    return ParsedExercise(name: name, sets: sets, reps: reps, weightKg: weightKg);
  }

  static List<ParsedExercise> parseAll(List<String> exercises) =>
      exercises.map(parse).toList();
}
