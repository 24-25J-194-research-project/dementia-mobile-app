import 'dart:io';

import 'package:dementia_app/features/auth/domain/entities/user_model.dart';
import 'package:dementia_app/features/profile/domain/repositories/profile_repository.dart';

class ProfileUseCase {
  final ProfileRepository repository;

  ProfileUseCase(this.repository);

  Future<UserModel> getUserProfile(String uid) async {
    return await repository.getUserProfile(uid);
  }

  Future<void> updateUserProfile(UserModel userModel) async {
    await repository.updateUserProfile(userModel);
  }

  Future<String> updateProfilePicture(String uid, File imageFile) async {
    return await repository.updateProfilePicture(uid, imageFile);
  }

  Future<void> saveUserEducation(String uid, List<Education> educationList) async {
    await repository.saveUserEducation(uid, educationList);
  }

  Future<void> saveUserWorkExperience(String userId, List<WorkExperience> workExperienceList) async {
    await repository.saveWorkExperience(userId, workExperienceList);
  }

  Future<void> saveUserFamilyMembers(String userId, List<FamilyMember> familyMembers) async {
    await repository.saveUserFamilyMembers(userId, familyMembers);
  }
}
