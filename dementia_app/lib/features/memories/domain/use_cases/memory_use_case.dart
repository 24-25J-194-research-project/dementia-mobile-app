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

  // Get a memory by its ID
  Future<Memory> getMemoryById(String memoryId) async {
    Memory? memory = await _repository.getMemoryById(memoryId);
    if (memory == null) {
      throw Exception('Memory not found');
    }
    return memory;
  }

  // Get a memory by ids
  Future<List<Memory>> getMemoryByIds(List<String> memoryIds) async {
    return await _repository.getMemoriesByIds(memoryIds);
  }

  // Upload media (e.g., images, videos)
  Future<String> uploadMedia(File file, String fileName) async {
    return await _repository.uploadMedia(file, fileName);
  }

  // Delete a memory and its associated media
  Future<void> deleteMemory(String memoryId) async {
    await _repository.deleteMemory(memoryId);
  }
}
