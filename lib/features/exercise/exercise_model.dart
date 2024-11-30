enum ExerciseType {
  walk("Yürüyüş"),
  run("Koşu"),
  bisycle("Bisiklet");

  const ExerciseType(this.name);
  final String name;
}

class Exercise {
  final String id;
  final String userId;
  final ExerciseType type;
  final int steps;
  final int duration;
  final double distance;
  final DateTime timestamp;

  Exercise({
    required this.id,
    required this.userId,
    required this.type,
    required this.steps,
    required this.duration,
    required this.distance,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type.name,
      'steps': steps,
      'duration': duration,
      'distance': distance,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      id: map['id'],
      userId: map['userId'],
      type: ExerciseType.values.firstWhere((e) => e.name == map['type']),
      steps: map['steps'],
      duration: map['duration'],
      distance: map['distance'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}
