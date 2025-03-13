import 'package:flutter/material.dart';
import 'package:dementia_app/features/auth/domain/entities/user_model.dart';
import 'package:dementia_app/features/profile/domain/use_cases/profile_use_case.dart';
import 'package:dementia_app/features/profile/presentation/widgets/education_card.dart';
import '../../data/repositories/profile_repository_impl.dart';

class EducationScreen extends StatefulWidget {
  final String userId;

  const EducationScreen({super.key, required this.userId});

  @override
  EducationScreenState createState() => EducationScreenState();
}

class EducationScreenState extends State<EducationScreen> {
  late List<Education> educationList;
  bool isLoading = true;

  late ProfileUseCase _profileUseCase;

  @override
  void initState() {
    super.initState();
    _profileUseCase = ProfileUseCase(ProfileRepositoryImpl());
    _loadUserProfile();
  }

  void _loadUserProfile() async {
    try {
      UserModel user = await _profileUseCase.getUserProfile(widget.userId);
      setState(() {
        educationList = user.educations ?? [];
        isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error loading user profile')));
    }
  }

  void _addNewEducation() {
    setState(() {
      educationList.add(Education(name: '', yearFrom: '', yearTo: '', description: ''));
    });
  }

  // Save education list to database
  Future<void> _saveEducation() async {
    try {
      await _profileUseCase.saveUserEducation(widget.userId, educationList);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Education updated successfully')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error saving education')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Education'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addNewEducation,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              educationList.isEmpty
                  ? const Center(child: Text('No Education Info. Add New Education'))
                  : Column(
                children: educationList.map((education) {
                  return EducationCard(
                    education: education,
                    onSave: () {
                      _saveEducation();
                    },
                    onDelete: () {
                      setState(() {
                        educationList.remove(education);
                      });
                    },
                    onEdit: (updatedEducation) {
                      setState(() {
                        educationList[educationList.indexOf(education)] = updatedEducation;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
