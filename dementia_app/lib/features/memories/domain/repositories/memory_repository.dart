import 'dart:io';

import '../entities/memory_model.dart';

abstract class IMemoryRepository {
  Future<void> saveMemory(Memory memory);
  Future<List<Memory>> getMemories(String patientId);
  Future<Memory?> getMemoryById(String id);
  Future<List<Memory>> getMemoriesByIds(List<String> ids);
  Future<String> uploadMedia(File file, String fileName);
  Future<void> deleteMemory(String id);
}
