import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../data/repositories/memory_repository_impl.dart';
import '../../domain/entities/memory_model.dart';
import '../../domain/use_cases/memory_use_case.dart';
import '../widgets/media_card.dart';

class UploadStatus {
  final bool isUploading;
  final String? error;
  final String? uploadedUrl;

  UploadStatus({
    this.isUploading = false,
    this.error,
    this.uploadedUrl,
  });
}

class MediaWithStatus {
  final Media media;
  final UploadStatus uploadStatus;

  MediaWithStatus({
    required this.media,
    UploadStatus? uploadStatus,
  }) : uploadStatus = uploadStatus ?? UploadStatus();

  MediaWithStatus copyWith({
    Media? media,
    UploadStatus? uploadStatus,
  }) {
    return MediaWithStatus(
      media: media ?? this.media,
      uploadStatus: uploadStatus ?? this.uploadStatus,
    );
  }
}

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

  List<MediaWithStatus> mediaList = [];
  bool get hasUploadsInProgress =>
      mediaList.any((m) => m.uploadStatus.isUploading);
  bool get hasUploadErrors =>
      mediaList.any((m) => m.uploadStatus.error != null);

  final ImagePicker _picker = ImagePicker();

  Future<void> _uploadMedia(int index) async {
    final mediaWithStatus = mediaList[index];
    final media = mediaWithStatus.media;

    if (media.url == null) return;

    setState(() {
      mediaList[index] = mediaWithStatus.copyWith(
        uploadStatus: UploadStatus(isUploading: true),
      );
    });

    try {
      final mediaUrl = await MemoryUseCase(MemoryRepository()).uploadMedia(
        File(media.url!),
        media.description,
      );

      setState(() {
        mediaList[index] = mediaWithStatus.copyWith(
          uploadStatus: UploadStatus(uploadedUrl: mediaUrl),
          media: Media(
            type: media.type,
            url: mediaUrl,
            description: media.description,
          ),
        );
      });
    } catch (e) {
      setState(() {
        mediaList[index] = mediaWithStatus.copyWith(
          uploadStatus: UploadStatus(error: e.toString()),
        );
      });
    }
  }

  Future<void> _addMedia() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        mediaList.add(
          MediaWithStatus(
            media: Media(
              type: MediaType.image,
              url: pickedFile.path,
              description: '',
            ),
          ),
        );
      });

      // Start upload immediately after adding
      _uploadMedia(mediaList.length - 1);
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
      if (hasUploadsInProgress) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please wait for all uploads to complete')),
        );
        return;
      }

      if (hasUploadErrors) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please fix upload errors before saving')),
        );
        return;
      }

      final memory = Memory(
        patientId: widget.patientId,
        title: titleController.text,
        description: descriptionController.text,
        date: dateController.text,
        media:
            mediaList.map((m) => m.media).where((m) => m.url != null).toList(),
      );

      await MemoryUseCase(MemoryRepository()).saveMemory(memory);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Memory saved')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving memory: $e')),
      );
    }
  }

  void _deleteMedia(int index) {
    setState(() {
      mediaList.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Memory')),
      body: CustomScrollView(
        slivers: [
          SliverList(
            delegate: SliverChildListDelegate(
              [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    controller: titleController,
                    decoration:
                        const InputDecoration(labelText: 'Memory Title'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    controller: descriptionController,
                    decoration:
                        const InputDecoration(labelText: 'Memory Description'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    controller: dateController,
                    decoration: const InputDecoration(labelText: 'Memory Date'),
                    readOnly: true,
                    onTap: _selectDate,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: _addMedia,
                    child: const Text('Add Media'),
                  ),
                ),
              ],
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final mediaWithStatus = mediaList[index];
                return Stack(
                  children: [
                    MediaCard(
                      media: mediaWithStatus.media,
                      onDelete: () => _deleteMedia(index),
                      onEdit: (_) {},
                    ),
                    if (mediaWithStatus.uploadStatus.isUploading)
                      const Positioned.fill(
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    if (mediaWithStatus.uploadStatus.error != null)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Tooltip(
                          message: mediaWithStatus.uploadStatus.error!,
                          child: const Icon(
                            Icons.error,
                            color: Colors.red,
                          ),
                        ),
                      ),
                  ],
                );
              },
              childCount: mediaList.length,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: hasUploadsInProgress || hasUploadErrors ? null : _saveMemory,
        icon: const Icon(Icons.save),
        label: Text(
          hasUploadsInProgress
              ? 'Uploading...'
              : hasUploadErrors
                  ? 'Fix Errors'
                  : 'Save Memory',
          style: const TextStyle(fontSize: 16),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
