import 'package:flutter/material.dart';
import 'package:dementia_app/features/auth/domain/entities/user_model.dart';

class WorkExperienceCard extends StatelessWidget {
  final WorkExperience workExperience;
  final Function onSave;
  final Function onDelete;
  final Function(WorkExperience) onEdit;

  const WorkExperienceCard({
    super.key,
    required this.workExperience,
    required this.onSave,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    TextEditingController companyController = TextEditingController(text: workExperience.company);
    TextEditingController positionController = TextEditingController(text: workExperience.position);
    TextEditingController yearFromController = TextEditingController(text: workExperience.yearFrom);
    TextEditingController yearToController = TextEditingController(text: workExperience.yearTo);
    TextEditingController descriptionController = TextEditingController(text: workExperience.description);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: companyController,
              decoration: const InputDecoration(labelText: 'Company'),
              onChanged: (value) {
                workExperience.company = value;
              },
            ),
            TextFormField(
              controller: positionController,
              decoration: const InputDecoration(labelText: 'Position'),
              onChanged: (value) {
                workExperience.position = value;
              },
            ),
            TextFormField(
              controller: yearFromController,
              decoration: const InputDecoration(labelText: 'Year From'),
              onChanged: (value) {
                workExperience.yearFrom = value;
              },
            ),
            TextFormField(
              controller: yearToController,
              decoration: const InputDecoration(labelText: 'Year To'),
              onChanged: (value) {
                workExperience.yearTo = value;
              },
            ),
            TextFormField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              onChanged: (value) {
                workExperience.description = value;
              },
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
                    onEdit(workExperience);
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
