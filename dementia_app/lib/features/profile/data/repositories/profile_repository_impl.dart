import 'dart:io';

import 'package:dementia_app/features/auth/domain/entities/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:dementia_app/features/profile/domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  Future<UserModel> getUserProfile(String uid) async {
    try {
      DocumentSnapshot snapshot = await _firestore.collection('users').doc(uid).get();
      if (snapshot.exists) {
        print("User profile found.");
        print(snapshot.data());
        return UserModel.fromMap(snapshot.data() as Map<String, dynamic>);
      }
      throw Exception("User profile not found.");
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> updateUserProfile(UserModel userModel) async {
    try {
      await _firestore.collection('users').doc(userModel.uid).update(userModel.toMap());
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<String> updateProfilePicture(String uid, File imageFile) async {
    try {
      final ref = _storage.ref().child('profile_pictures/$uid');
      final uploadTask = await ref.putFile(imageFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      await _firestore.collection('users').doc(uid).update({'profilePicUrl': downloadUrl});
      return downloadUrl;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> saveUserEducation(String uid, List<Education> educationList) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'educations': educationList.map((e) => e.toMap()).toList(),
      });
    } catch (e) {
      throw Exception('Error saving education: $e');
    }
  }

  @override
  Future<void> saveWorkExperience(String userId, List<WorkExperience> workExperienceList) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'workExperiences': workExperienceList.map((e) => e.toMap()).toList(),
      });
    } catch (e) {
      throw Exception('Error saving work experience: $e');
    }
  }

  @override
  Future<void> saveUserFamilyMembers(String userId, List<FamilyMember> familyMemberList) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'familyMembers': familyMemberList.map((e) => e.toMap()).toList(),
      });
    } catch (e) {
      rethrow;
    }
  }
}