import '../entities/therapy_outline.dart';

abstract class TherapyOutlineRepository {
  Future<List<TherapyOutline>> getCompletedTherapyOutlines(String patientId);
  Future<List<TherapyOutline>> getAllTherapyOutlines(String patientId);
  Future<void> deleteTherapyOutlinesByMemoryId(String memoryId);
}
