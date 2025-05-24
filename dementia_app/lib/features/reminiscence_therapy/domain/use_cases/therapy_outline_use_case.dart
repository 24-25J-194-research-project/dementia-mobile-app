import '../entities/therapy_outline.dart';
import '../repositories/therapy_outline_repository.dart';

class TherapyOutlineUseCase {
  final TherapyOutlineRepository _repository;

  TherapyOutlineUseCase(this._repository);

  Future<List<TherapyOutline>> fetchCompletedTherapyOutlines(
      String patientId) async {
    return await _repository.getCompletedTherapyOutlines(patientId);
  }

  Future<List<TherapyOutline>> fetchAllTherapyOutlines(String patientId) async {
    return await _repository.getAllTherapyOutlines(patientId);
  }

  Future<void> deleteTherapyOutlinesByMemoryId(String memoryId) async {
    await _repository.deleteTherapyOutlinesByMemoryId(memoryId);
  }
}
