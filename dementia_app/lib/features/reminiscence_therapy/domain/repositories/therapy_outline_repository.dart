
import '../entities/therapy_outline.dart';

abstract class TherapyOutlineRepository {
  Future<List<TherapyOutline>> getCompletedTherapyOutlines();
  Future<List<TherapyOutline>> getAllTherapyOutlines();
}
