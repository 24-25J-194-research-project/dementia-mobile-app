import 'package:flutter/material.dart';
import 'package:dementia_app/features/auth/domain/entities/user_model.dart';
import 'package:dementia_app/features/profile/domain/use_cases/profile_use_case.dart';
import 'package:dementia_app/features/profile/presentation/widgets/family_member_card.dart';
import '../../data/repositories/profile_repository_impl.dart';

class FamilyMemberScreen extends StatefulWidget {
  final String userId;

  const FamilyMemberScreen({super.key, required this.userId});

  @override
  FamilyMemberScreenState createState() => FamilyMemberScreenState();
}

class FamilyMemberScreenState extends State<FamilyMemberScreen> {
  late List<FamilyMember> familyMemberList;
  bool isLoading = true;

  late ProfileUseCase _profileUseCase;

  @override
  void initState() {
    super.initState();
    _profileUseCase = ProfileUseCase(ProfileRepositoryImpl());
    _loadUserProfile();
  }

  // Load user profile with family members
  void _loadUserProfile() async {
    try {
      UserModel user = await _profileUseCase.getUserProfile(widget.userId);
      setState(() {
        familyMemberList = user.familyMembers ?? [];
        isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error loading user profile')));
    }
  }

  // Add new family member
  void _addNewFamilyMember() {
    setState(() {
      familyMemberList.add(FamilyMember(name: '', gender: '', relation: '', dob: '', birthPlace: ''));
    });
  }

  // Save family member list to database
  Future<void> _saveFamilyMembers() async {
    try {
      await _profileUseCase.saveUserFamilyMembers(widget.userId, familyMemberList);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Family Members updated successfully')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error saving family members')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Members'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addNewFamilyMember, // Add new family member
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
              familyMemberList.isEmpty
                  ? const Center(child: Text('No Family Member Info. Add New Family Member'))
                  : Column(
                children: familyMemberList.map((familyMember) {
                  return FamilyMemberCard(
                    familyMember: familyMember,
                    onSave: () {
                      _saveFamilyMembers();
                    },
                    onDelete: () {
                      setState(() {
                        familyMemberList.remove(familyMember);
                      });
                    },
                    onEdit: (updatedFamilyMember) {
                      setState(() {
                        familyMemberList[familyMemberList.indexOf(familyMember)] = updatedFamilyMember;
                      });
                    },
                    existingFamilyMemberNames: familyMemberList
                        .where((member) => member != familyMember)
                        .map((member) => member.name)
                        .toList(),
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
