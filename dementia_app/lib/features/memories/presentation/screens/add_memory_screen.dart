import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../data/repositories/memory_repository_impl.dart';
import '../../domain/entities/memory_model.dart';
import '../../domain/use_cases/memory_use_case.dart';
import '../widgets/media_card.dart';

class AddMemoryScreen extends StatefulWidget {
  final String patientId;

  const AddMemoryScreen({super.key, required this.patientId});

  @override
  _AddMemoryScreenState createState() => _AddMemoryScreenState();
}

class _AddMemoryScreenState extends State<AddMemoryScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController dateController = TextEditingController();

  List<Media> mediaList = [];

  final ImagePicker _picker = ImagePicker();

  Future<void> _addMedia() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        mediaList.add(Media(
          type: MediaType.image,
          url: pickedFile.path,
          description: '',
        ));
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        dateController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
      });
    }
  }

  Future<void> _saveMemory() async {
    try {
      List<Media> uploadedMediaList = [];

      for (var media in mediaList) {
        if (media.url != null) {
          final mediaUrl = await MemoryUseCase(MemoryRepository()).uploadMedia(
            File(media.url!),
            media.description,
          );

          uploadedMediaList.add(Media(
            type: media.type,
            url: mediaUrl,
            description: media.description,
          ));
        }
      }

      final memory = Memory(
        patientId: widget.patientId,
        title: titleController.text,
        description: descriptionController.text,
        date: dateController.text,
        media: uploadedMediaList,
      );

      await MemoryUseCase(MemoryRepository()).saveMemory(memory);

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Memory saved')));
      Navigator.pushNamed(context, '/memories');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving memory: $e')));
    }
  }

  void _editMedia(Media media) {
    setState(() {});
  }

  void _deleteMedia(Media media) {
    setState(() {
      mediaList.remove(media);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Memory')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Memory Title'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Memory Description'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: dateController,
              decoration: const InputDecoration(labelText: 'Memory Date'),
              readOnly: true,
              onTap: _selectDate,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _addMedia,
              child: const Text('Add Media'),
            ),
            const SizedBox(height: 12),

            ListView.builder(
              shrinkWrap: true,
              itemCount: mediaList.length,
              itemBuilder: (context, index) {
                final media = mediaList[index];
                return MediaCard(
                  media: media,
                  onDelete: () => _deleteMedia(media),
                  onEdit: _editMedia,
                );
              },
            ),
            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: _saveMemory,
              child: const Text('Save Memory'),
            ),
          ],
        ),
      ),
    );
  }
}
