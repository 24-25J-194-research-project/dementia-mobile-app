import '../entities/therapy_feedback.dart';

abstract class TherapyFeedbackRepository {
  Future<void> saveFeedback(TherapyFeedback feedback);
}
