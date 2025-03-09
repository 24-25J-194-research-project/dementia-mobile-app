import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:dementia_app/features/auth/domain/entities/user_model.dart';
import 'package:dementia_app/features/profile/domain/use_cases/profile_use_case.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dementia_app/core/logging/logger.dart';
import '../../../auth/presentation/providers/auth_service.dart';
import '../../data/repositories/profile_repository_impl.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  late UserModel user;
  bool isLoading = true;
  late String profilePicUrl;

  final AuthService _authService = AuthService();
  late ProfileUseCase _profileUseCase;
  TextEditingController dateOfBirthController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _profileUseCase = ProfileUseCase(ProfileRepositoryImpl());
    _loadUserProfile();
  }

  // Load user profile from AuthService
  void _loadUserProfile() async {
    try {
      user = await _authService.getCurrentUser() ?? UserModel(
        uid: '',
        email: '',
        firstName: '',
        lastName: '',
        dateOfBirth: '',
        gender: '',
        profilePicUrl: '',  // Default to empty string if no profile picture
      );
      profilePicUrl = user.profilePicUrl ?? '';
      dateOfBirthController.text = user.dateOfBirth;
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      logger.e('Error loading user profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error loading user profile')));
    }
  }

  // Update profile picture
  Future<void> _updateProfilePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      try {
        File imageFile = File(pickedFile.path);
        String newPicUrl = await _profileUseCase.updateProfilePicture(user.uid, imageFile);
        setState(() {
          profilePicUrl = newPicUrl;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile picture updated successfully')));
      } catch (e) {
        logger.e('Error updating profile picture: $e');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error updating profile picture')));
      }
    }
  }

  // Update user profile information
  Future<void> _updateUserProfile() async {
    try {
      await _profileUseCase.updateUserProfile(user);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully')));
    } catch (e) {
      logger.e('Error updating profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error updating profile')));
    }
  }

  // Select Date of Birth
  Future<void> _selectDateOfBirth(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        dateOfBirthController.text = pickedDate.toString().split(" ")[0]; // Set the selected date
        user.dateOfBirth = dateOfBirthController.text;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // The profile picture
                ClipOval(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: profilePicUrl.isNotEmpty
                        ? NetworkImage(profilePicUrl)
                        : const AssetImage('assets/images/default_profile_pic.png') as ImageProvider,
                    backgroundColor: Colors.grey[200],
                  ),
                ),
                Positioned(
                  top: 50,
                  left: 30,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Positioned(
                  top: 47,
                  left: 26,
                  child: IconButton(
                    onPressed: _updateProfilePicture,
                    icon: const Icon(Icons.camera_alt),
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              initialValue: user.firstName,
              decoration: const InputDecoration(
                labelText: 'First Name',
                icon: Icon(Icons.person),
              ),
              onChanged: (value) => user.firstName = value,
            ),
            const SizedBox(height: 12), // Gap between fields
            TextFormField(
              initialValue: user.lastName,
              decoration: const InputDecoration(
                labelText: 'Last Name',
                icon: Icon(Icons.person),
              ),
              onChanged: (value) => user.lastName = value,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: dateOfBirthController,
              decoration: const InputDecoration(
                labelText: 'Date of Birth',
                icon: Icon(Icons.calendar_today),
              ),
              readOnly: true,
              onTap: () => _selectDateOfBirth(context), // Show date picker
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: user.gender.isEmpty ? null : user.gender,
              decoration: const InputDecoration(
                labelText: 'Gender',
                icon: Icon(Icons.accessibility),
              ),
              items: ['Male', 'Female', 'Other']
                  .map((gender) => DropdownMenuItem<String>(
                value: gender,
                child: Text(gender),
              ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  user.gender = value!;
                });
              },
            ),
            const SizedBox(height: 20), // Gap between fields and button
            ElevatedButton(
              onPressed: _updateUserProfile,
              child: const Text('Update Profile'),
            ),
          ],
        ),
      ),
    );
  }
}
