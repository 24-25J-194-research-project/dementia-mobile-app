import 'package:flutter/material.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import '../../../auth/domain/entities/user_model.dart';

class FamilyMemberCard extends StatelessWidget {
  final FamilyMember familyMember;
  final Function onSave;
  final Function onDelete;
  final Function(FamilyMember) onEdit;
  final List<String> existingFamilyMemberNames; // Added list of existing family member names

  const FamilyMemberCard({
    super.key,
    required this.familyMember,
    required this.onSave,
    required this.onDelete,
    required this.onEdit,
    required this.existingFamilyMemberNames,  // Pass existing family member names
  });

  @override
  Widget build(BuildContext context) {
    TextEditingController nameController = TextEditingController(text: familyMember.name);
    TextEditingController genderController = TextEditingController(text: familyMember.gender);
    TextEditingController relationController = TextEditingController(text: familyMember.relation);
    TextEditingController dobController = TextEditingController(text: familyMember.dob);
    TextEditingController birthPlaceController = TextEditingController(text: familyMember.birthPlace);
    TextEditingController spouseController = TextEditingController(text: familyMember.spouse);
    TextEditingController notesController = TextEditingController(text: familyMember.notes);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name input field
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              onChanged: (value) {
                familyMember.name = value;
              },
            ),

            // Gender dropdown
            DropdownButtonFormField<String>(
              value: familyMember.gender.isEmpty ? null : familyMember.gender,
              decoration: const InputDecoration(labelText: 'Gender'),
              items: ['Male', 'Female', 'Other']
                  .map((gender) => DropdownMenuItem<String>(
                value: gender,
                child: Text(gender),
              ))
                  .toList(),
              onChanged: (value) {
                familyMember.gender = value!;
              },
            ),

            // Relation input field
            TextFormField(
              controller: relationController,
              decoration: const InputDecoration(labelText: 'Relation'),
              onChanged: (value) {
                familyMember.relation = value;
              },
            ),

            // Date of Birth input field
            TextFormField(
              controller: dobController,
              decoration: const InputDecoration(labelText: 'Date of Birth'),
              onChanged: (value) {
                familyMember.dob = value;
              },
            ),

            // Birth place input field
            TextFormField(
              controller: birthPlaceController,
              decoration: const InputDecoration(labelText: 'Birth Place'),
              onChanged: (value) {
                familyMember.birthPlace = value;
              },
            ),

            // Marital status dropdown
            DropdownButtonFormField<MaritalStatus>(
              value: familyMember.maritalStatus,
              decoration: const InputDecoration(labelText: 'Marital Status'),
              items: MaritalStatus.values
                  .map((status) => DropdownMenuItem<MaritalStatus>(
                value: status,
                child: Text(status.toString().split('.').last),
              ))
                  .toList(),
              onChanged: (value) {
                familyMember.maritalStatus = value;
              },
            ),

            // Spouse input field
            TextFormField(
              controller: spouseController,
              decoration: const InputDecoration(labelText: 'Spouse'),
              onChanged: (value) {
                familyMember.spouse = value;
              },
            ),

            // Notes input field
            TextFormField(
              controller: notesController,
              decoration: const InputDecoration(labelText: 'Notes'),
              onChanged: (value) {
                familyMember.notes = value;
              },
            ),

            const SizedBox(height: 10),
            const Text('Children'),
            MultiSelectDialogField(
              items: existingFamilyMemberNames
                  .map((child) => MultiSelectItem<String>(child, child))
                  .toList(),
              initialValue: familyMember.children ?? [],
              onConfirm: (values) {
                familyMember.children = values.cast<String>();
              },
            ),

            // Display selected children
            const SizedBox(height: 10),
            if (familyMember.children != null && familyMember.children!.isNotEmpty)
              Wrap(
                children: familyMember.children!
                    .map((child) => Chip(label: Text(child)))
                    .toList(),
              ),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    onDelete();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: () {
                    onEdit(familyMember);
                    onSave();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
