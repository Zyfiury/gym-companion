enum WorkoutStatus {
  planned,
  completed,
  skipped,
  modified;

  static WorkoutStatus fromString(String? value) {
    switch (value) {
      case 'completed':
        return WorkoutStatus.completed;
      case 'skipped':
        return WorkoutStatus.skipped;
      case 'modified':
        return WorkoutStatus.modified;
      default:
        return WorkoutStatus.planned;
    }
  }

  String get firestoreValue => name;
}

enum PostType {
  workout,
  meal,
  pr,
  progress,
  general;

  static PostType fromString(String? value) {
    switch (value) {
      case 'workout':
        return PostType.workout;
      case 'meal':
        return PostType.meal;
      case 'pr':
        return PostType.pr;
      case 'progress':
        return PostType.progress;
      default:
        return PostType.general;
    }
  }

  String get firestoreValue => name;
}
