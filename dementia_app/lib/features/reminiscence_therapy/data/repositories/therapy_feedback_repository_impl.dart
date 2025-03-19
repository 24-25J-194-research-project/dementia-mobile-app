import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/therapy_feedback.dart';
import '../../domain/repositories/therapy_feedback_repository.dart';

class TherapyFeedbackRepositoryImpl implements TherapyFeedbackRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<void> saveFeedback(TherapyFeedback feedback) async {
    try {
        await _firestore.collection('therapy_feedbacks').add(feedback.toMap());
    } catch (e) {
      throw Exception("Error saving therapy feedback: $e");
    }
  }
}
