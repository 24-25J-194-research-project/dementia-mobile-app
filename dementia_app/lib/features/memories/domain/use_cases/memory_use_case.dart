import 'dart:io';

import '../../data/repositories/memory_repository_impl.dart';
import '../entities/memory_model.dart';

class MemoryUseCase {
  final MemoryRepository _repository;

  MemoryUseCase(this._repository);

  // Fetch memories for a patient
  Future<List<Memory>> getMemories(String patientId) {
    return _repository.getMemories(patientId);
  }

  // Save a new memory
  Future<void> saveMemory(Memory memory) async {
    await _repository.saveMemory(memory);
  }

  // Upload media (e.g., images, videos)
  Future<String> uploadMedia(File file, String fileName) async {
    return await _repository.uploadMedia(file, fileName);
  }
}
