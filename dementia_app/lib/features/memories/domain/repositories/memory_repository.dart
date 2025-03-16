import 'dart:io';

import '../entities/memory_model.dart';

abstract class IMemoryRepository {
  Future<void> saveMemory(Memory memory);
  Future<List<Memory>> getMemories(String patientId);
  Future<String> uploadMedia(File file, String fileName);
}
