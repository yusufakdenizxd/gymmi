import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> updateLeaderboard({
    required String userId,
    required String userName,
    required int steps,
    required int week,
    required int month,
    required int year,
  }) async {
    // Update weekly leaderboard
    final weeklyRef = _firestore.collection('leaderboard_weekly').doc('${year}_$week');

    await _firestore.runTransaction((transaction) async {
      final weeklyDoc = await transaction.get(weeklyRef);

      if (weeklyDoc.exists) {
        final List<dynamic> users = weeklyDoc.data()?['users'] ?? [];
        final existingUserIndex = users.indexWhere((u) => u['userId'] == userId);

        if (existingUserIndex != -1) {
          users[existingUserIndex]['steps'] += steps;
        } else {
          users.add({
            'userId': userId,
            'userName': userName,
            'steps': steps,
          });
        }

        transaction.update(weeklyRef, {'users': users});
      } else {
        transaction.set(weeklyRef, {
          'week': week,
          'year': year,
          'users': [
            {
              'userId': userId,
              'userName': userName,
              'steps': steps,
            }
          ]
        });
      }
    });

    // Update monthly leaderboard
    final monthlyRef = _firestore.collection('leaderboard_monthly').doc('${year}_$month');

    await _firestore.runTransaction((transaction) async {
      final monthlyDoc = await transaction.get(monthlyRef);

      if (monthlyDoc.exists) {
        final List<dynamic> users = monthlyDoc.data()?['users'] ?? [];
        final existingUserIndex = users.indexWhere((u) => u['userId'] == userId);

        if (existingUserIndex != -1) {
          users[existingUserIndex]['steps'] += steps;
        } else {
          users.add({
            'userId': userId,
            'userName': userName,
            'steps': steps,
          });
        }

        transaction.update(monthlyRef, {'users': users});
      } else {
        transaction.set(monthlyRef, {
          'month': month,
          'year': year,
          'users': [
            {
              'userId': userId,
              'userName': userName,
              'steps': steps,
            }
          ]
        });
      }
    });
  }

  Stream<DocumentSnapshot> getWeeklyLeaderboard(int week, int year) {
    return _firestore.collection('leaderboard_weekly').doc('${year}_$week').snapshots();
  }

  Stream<DocumentSnapshot> getMonthlyLeaderboard(int month, int year) {
    return _firestore.collection('leaderboard_monthly').doc('${year}_$month').snapshots();
  }
}
