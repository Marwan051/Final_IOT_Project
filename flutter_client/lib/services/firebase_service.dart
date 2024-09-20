import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  // Sign In with Email and Password
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      log(e.toString());
      return null;
    }
  }

  // Get Scores within a specified time range
  Future<List<Score>> getScores(DateTime startTime, DateTime endTime) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('total_score')
          .where('timestamp', isGreaterThanOrEqualTo: startTime)
          .where('timestamp', isLessThanOrEqualTo: endTime)
          .get();
      return querySnapshot.docs
          .map((doc) => Score(
                score: doc['score'].toDouble(),
                timestamp: doc['timestamp'].toDate(),
              ))
          .toList();
    } catch (e) {
      log(e.toString());
      return [];
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}

class Score {
  final double score;
  final DateTime timestamp;

  Score({required this.score, required this.timestamp});

  Map<String, dynamic> toMap() {
    return {
      'score': score.toDouble(),
      'timestamp': timestamp,
    };
  }
}
