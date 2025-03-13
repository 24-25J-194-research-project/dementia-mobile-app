import 'package:flutter/material.dart';
import 'package:dementia_app/features/auth/domain/entities/user_model.dart';

class EducationCard extends StatelessWidget {
  final Education education;
  final Function onSave;
  final Function onDelete;
  final Function(Education) onEdit;

  const EducationCard({super.key, required this.education, required this.onSave, required this.onDelete, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    TextEditingController nameController = TextEditingController(text: education.name);
    TextEditingController yearFromController = TextEditingController(text: education.yearFrom);
    TextEditingController yearToController = TextEditingController(text: education.yearTo);
    TextEditingController descriptionController = TextEditingController(text: education.description);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Education Name'),
            ),
            TextField(
              controller: yearFromController,
              decoration: const InputDecoration(labelText: 'Year From'),
            ),
            TextField(
              controller: yearToController,
              decoration: const InputDecoration(labelText: 'Year To'),
            ),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => onDelete(),
                ),
                IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: () {
                    Education updatedEducation = Education(
                      name: nameController.text,
                      yearFrom: yearFromController.text,
                      yearTo: yearToController.text,
                      description: descriptionController.text,
                    );
                    onEdit(updatedEducation);
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
