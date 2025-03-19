import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/therapy_outline.dart';
import '../../domain/repositories/therapy_outline_repository.dart';

class TherapyOutlineRepositoryImpl implements TherapyOutlineRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<TherapyOutline>> getCompletedTherapyOutlines() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('therapy_outlines')
          .where('status', isEqualTo: 'completed')
          .get();

      List<TherapyOutline> therapyOutlines = snapshot.docs.map((doc) {
        return TherapyOutline.fromMap(doc.data() as Map<String, dynamic>, id: doc.id);
      }).toList();

      Map<String, TherapyOutline> latestOutlinesByMemoryId = {};

      for (var outline in therapyOutlines) {
        if (!latestOutlinesByMemoryId.containsKey(outline.memoryId)) {
          latestOutlinesByMemoryId[outline.memoryId] = outline;
        } else {
          final currentOutline = latestOutlinesByMemoryId[outline.memoryId]!;
          if (outline.id.compareTo(currentOutline.id) > 0) {
            latestOutlinesByMemoryId[outline.memoryId] = outline;
          }
        }
      }
      return latestOutlinesByMemoryId.values.toList();
    } catch (e) {
      throw Exception('Error fetching completed therapy outlines: $e');
    }
  }

  @override
  Future<List<TherapyOutline>> getAllTherapyOutlines() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('therapy_outlines').get();

      List<TherapyOutline> therapyOutlines = snapshot.docs.map((doc) {
        return TherapyOutline.fromMap(doc.data() as Map<String, dynamic>, id: doc.id);
      }).toList();

      return therapyOutlines;
    } catch (e) {
      throw Exception('Error fetching all therapy outlines: $e');
    }
  }
}
