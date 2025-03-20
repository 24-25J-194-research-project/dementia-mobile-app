import '../entities/therapy_feedback.dart';
import '../repositories/therapy_feedback_repository.dart';

class TherapyFeedbackUseCase {
  final TherapyFeedbackRepository _repository;

  TherapyFeedbackUseCase(this._repository);

  Future<void> saveFeedback(TherapyFeedback feedback) async {
    await _repository.saveFeedback(feedback);
  }
}
