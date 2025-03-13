import 'dart:io';

import 'package:dementia_app/features/auth/domain/entities/user_model.dart';

abstract class ProfileRepository {
  Future<UserModel> getUserProfile(String uid);
  Future<void> updateUserProfile(UserModel userModel);
  Future<String> updateProfilePicture(String uid, File imageFile);
  Future<void> saveUserEducation(String uid, List<Education> educationList);
  Future<void> saveWorkExperience(String userId, List<WorkExperience> workExperienceList);
  Future<void> saveUserFamilyMembers(String userId, List<FamilyMember> familyMembers);
}