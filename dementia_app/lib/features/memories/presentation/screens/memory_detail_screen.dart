import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../data/repositories/memory_repository_impl.dart';
import '../../domain/entities/memory_model.dart';
import '../../domain/use_cases/memory_use_case.dart';
import '../widgets/media_card.dart';

class MemoryDetailScreen extends StatefulWidget {
  final Memory memory;

  const MemoryDetailScreen({super.key, required this.memory});

  @override
  _MemoryDetailScreenState createState() => _MemoryDetailScreenState();
}

class _MemoryDetailScreenState extends State<MemoryDetailScreen> {
  late TextEditingController titleController;
  late TextEditingController descriptionController;
  late TextEditingController dateController;

  List<Media> mediaList = [];

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.memory.title);
    descriptionController = TextEditingController(text: widget.memory.description);
    dateController = TextEditingController(text: widget.memory.date);

    // Initialize the media list with the media from the selected memory
    mediaList = widget.memory.media ?? [];
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

  Future<void> _saveMemory() async {
    try {
      List<Media> uploadedMediaList = [];

      for (var media in mediaList) {
        if (media.url != null && media.url!.startsWith('http')) {
          // If media URL is already present and valid (uploaded media), keep it as is.
          uploadedMediaList.add(media);
        } else {
          // Upload new media
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

      final updatedMemory = widget.memory.copyWith(
        title: titleController.text,
        description: descriptionController.text,
        date: dateController.text,
        media: uploadedMediaList,
      );

      await MemoryUseCase(MemoryRepository()).saveMemory(updatedMemory);

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Memory updated')));
      Navigator.pushNamed(context, '/memories');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving memory: $e')));
    }
  }

  void _deleteMedia(Media media) {
    setState(() {
      mediaList.remove(media);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Memory')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Memory Title
            TextFormField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Memory Title'),
            ),
            const SizedBox(height: 12),

            // Memory Description
            TextFormField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Memory Description'),
            ),
            const SizedBox(height: 12),

            // Memory Date
            TextFormField(
              controller: dateController,
              decoration: const InputDecoration(labelText: 'Memory Date'),
              readOnly: true,
              onTap: _selectDate,
            ),
            const SizedBox(height: 12),

            // Categories
            Text(
              'Categories: ${widget.memory.categories?.join(', ') ?? 'Not processed yet'}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),

            // Emotions
            Text(
              'Emotions: ${widget.memory.emotions?.join(', ') ?? 'Not processed yet'}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),

            // Tags
            Text(
              'Tags: ${widget.memory.tags?.join(', ') ?? 'Not processed yet'}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),

            // Add Media Button
            ElevatedButton(
              onPressed: _addMedia,
              child: const Text('Add Media'),
            ),
            const SizedBox(height: 12),

            // Media List
            ListView.builder(
              shrinkWrap: true,
              itemCount: mediaList.length,
              itemBuilder: (context, index) {
                final media = mediaList[index];
                return MediaCard(
                  media: media,
                  onDelete: () => _deleteMedia(media),
                  onEdit: (_) {}, // Media editing not supported here
                );
              },
            ),
            const SizedBox(height: 12),

            // Save Memory Button
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
