import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gymmi/features/leaderboard/leaderboard_service.dart';
import 'package:pedometer/pedometer.dart';
import 'package:uuid/uuid.dart';

import 'exercise_model.dart';

class ExerciseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _leaderboardService = LeaderboardService();
  Stream<StepCount>? _stepCountStream;
  Stream<PedestrianStatus>? _pedestrianStatusStream;

  late Stream<StepCount> stepCountStream;
  late Stream<PedestrianStatus> pedestrianStatusStream;

  void initPlatformState() {
    _pedestrianStatusStream = Pedometer.pedestrianStatusStream;
    _stepCountStream = Pedometer.stepCountStream;

    stepCountStream = _stepCountStream!;
    pedestrianStatusStream = _pedestrianStatusStream!;
  }

  Future<void> saveExercise({
    required String userId,
    required String userName,
    required ExerciseType type,
    required int steps,
    required int duration,
    required double distance,
  }) async {
    final now = DateTime.now();
    final exercise = {
      'id': const Uuid().v4(),
      'userId': userId,
      'type': type.name,
      'steps': steps,
      'duration': duration,
      'distance': distance,
      'timestamp': now.toIso8601String(),
    };

    await _firestore.collection('exercises').add(exercise);

    // Update leaderboard
    await _leaderboardService.updateLeaderboard(
      userId: userId,
      userName: userName,
      steps: steps,
      week: (now.difference(DateTime(now.year, 1, 1)).inDays ~/ 7) + 1,
      month: now.month,
      year: now.year,
    );
  }

  Stream<QuerySnapshot> getUserExercises(String userId) {
    return _firestore.collection('exercises').where('userId', isEqualTo: userId).orderBy('timestamp', descending: true).snapshots();
  }

  Future<List<Exercise>> getExercisesForDate(String userId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snapshot = await _firestore.collection('exercises').where('userId', isEqualTo: userId).where('timestamp', isGreaterThanOrEqualTo: startOfDay.toIso8601String()).where('timestamp', isLessThan: endOfDay.toIso8601String()).get();

    return snapshot.docs.map((doc) => Exercise.fromMap(doc.data())).toList();
  }
}
