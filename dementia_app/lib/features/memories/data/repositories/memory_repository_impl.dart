import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../domain/entities/memory_model.dart';
import '../../domain/repositories/memory_repository.dart';

class MemoryRepository implements IMemoryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _firebaseStorage = FirebaseStorage.instance;

  @override
  Future<void> saveMemory(Memory memory) async {
    try {
      if (memory.id != null) {
        await _firestore.collection('memories').doc(memory.id).update(memory.toMap());
      } else {
        await _firestore.collection('memories').add(memory.toMap());
      }
    } catch (e) {
      throw Exception('Error saving memory: $e');
    }
  }

  @override
  Future<List<Memory>> getMemories(String patientId) async {
    try {
      final querySnapshot = await _firestore
          .collection('memories')
          .where('patientId', isEqualTo: patientId)
          .get();
      return querySnapshot.docs
          .map((doc) => Memory.fromMap(doc.data(), id: doc.id))
          .toList();
    } catch (e) {
      throw Exception('Error fetching memories: $e');
    }
  }

  @override
  Future<Memory?> getMemoryById(String id) async {
    try {
      final docSnapshot = await _firestore.collection('memories').doc(id).get();
      if (docSnapshot.exists) {
        return Memory.fromMap(docSnapshot.data()!, id: docSnapshot.id);
      } else {
        return null;
      }
    } catch (e) {
      throw Exception('Error fetching memory by ID: $e');
    }
  }

  @override
  Future<List<Memory>> getMemoriesByIds(List<String> ids) async {
    try {
      final querySnapshot = await _firestore
          .collection('memories')
          .where(FieldPath.documentId, whereIn: ids)
          .get();
      return querySnapshot.docs
          .map((doc) => Memory.fromMap(doc.data(), id: doc.id))
          .toList();
    } catch (e) {
      throw Exception('Error fetching memories by IDs: $e');
    }
  }

  @override
  Future<String> uploadMedia(File file, String fileName) async {
    try {
      final storageReference = _firebaseStorage
          .ref()
          .child('memories/${fileName}_${DateTime.now().millisecondsSinceEpoch}');
      if (await file.exists()) {
        final uploadTask = storageReference.putFile(file);
        await uploadTask.whenComplete(() {});
        final mediaUrl = await storageReference.getDownloadURL();
        return mediaUrl;
      } else {
        throw Exception("File does not exist at ${file.path}");
      }
    } catch (e) {
      throw Exception('Error uploading media: $e');
    }
  }
}
