import '../entities/therapy_outline.dart';
import '../repositories/therapy_outline_repository.dart';

class TherapyOutlineUseCase {
  final TherapyOutlineRepository _therapyOutlineRepository;

  TherapyOutlineUseCase(this._therapyOutlineRepository);

  Future<List<TherapyOutline>> fetchLatestCompletedTherapyOutlines() async {
    try {
      List<TherapyOutline> therapyOutlines = await _therapyOutlineRepository.getCompletedTherapyOutlines();
      return therapyOutlines;
    } catch (e) {
      throw Exception('Error fetching completed therapy outlines: $e');
    }
  }

  Future<List<TherapyOutline>> fetchAllTherapyOutlines() async {
    try {
      List<TherapyOutline> therapyOutlines = await _therapyOutlineRepository.getAllTherapyOutlines();
      return therapyOutlines;
    } catch (e) {
      throw Exception('Error fetching all therapy outlines: $e');
    }
  }
}
