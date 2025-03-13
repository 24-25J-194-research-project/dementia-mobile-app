import 'package:flutter/material.dart';
import 'package:dementia_app/features/auth/domain/entities/user_model.dart';
import 'package:dementia_app/features/profile/domain/use_cases/profile_use_case.dart';
import 'package:dementia_app/features/profile/presentation/widgets/work_experience_card.dart';
import '../../data/repositories/profile_repository_impl.dart';

class WorkExperienceScreen extends StatefulWidget {
  final String userId;

  const WorkExperienceScreen({super.key, required this.userId});

  @override
  WorkExperienceScreenState createState() => WorkExperienceScreenState();
}

class WorkExperienceScreenState extends State<WorkExperienceScreen> {
  late List<WorkExperience> workExperienceList;
  bool isLoading = true;

  late ProfileUseCase _profileUseCase;

  @override
  void initState() {
    super.initState();
    _profileUseCase = ProfileUseCase(ProfileRepositoryImpl());
    _loadUserProfile();
  }

  // Load user profile with work experiences
  void _loadUserProfile() async {
    try {
      UserModel user = await _profileUseCase.getUserProfile(widget.userId);
      setState(() {
        workExperienceList = user.workExperiences ?? [];
        isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error loading user profile')));
    }
  }

  // Add new work experience
  void _addNewWorkExperience() {
    setState(() {
      workExperienceList.add(WorkExperience(company: '', position: '', yearFrom: '', yearTo: '', description: ''));
    });
  }

  // Save work experience list to database
  Future<void> _saveWorkExperience() async {
    try {
      await _profileUseCase.saveUserWorkExperience(widget.userId, workExperienceList);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Work Experience updated successfully')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error saving work experience')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Work Experience'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addNewWorkExperience, // Add new work experience
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
              workExperienceList.isEmpty
                  ? const Center(child: Text('No Work Experience Info. Add New Work Experience'))
                  : Column(
                children: workExperienceList.map((workExperience) {
                  return WorkExperienceCard(
                    workExperience: workExperience,
                    onSave: () {
                      // Handle save functionality per card (edit/save)
                      _saveWorkExperience();
                    },
                    onDelete: () {
                      setState(() {
                        workExperienceList.remove(workExperience);
                      });
                    },
                    onEdit: (updatedWorkExperience) {
                      setState(() {
                        workExperienceList[workExperienceList.indexOf(workExperience)] = updatedWorkExperience;
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
