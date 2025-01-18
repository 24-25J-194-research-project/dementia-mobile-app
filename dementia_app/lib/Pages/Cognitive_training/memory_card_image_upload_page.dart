// lib/Pages/memory_card_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import '../Components/user_avatar.dart';

class MemoryCardPage extends StatefulWidget {
  const MemoryCardPage({super.key});

  @override
  State<MemoryCardPage> createState() => _MemoryCardPageState();
}

class _MemoryCardPageState extends State<MemoryCardPage> {
  final supabase = Supabase.instance.client;
  final List<TextEditingController> _textControllers = List.generate(
      5, (index) => TextEditingController());
  final List<File?> _imageFiles = List.filled(5, null);
  bool _isUploading = false;

  bool get _isFormValid {
    // Check if at least one pair of image and text is filled
    for (int i = 0; i < 5; i++) {
      if (_imageFiles[i] != null && _textControllers[i].text.isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  Future<void> _pickImage(int index) async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedImage = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedImage != null) {
      setState(() {
        _imageFiles[index] = File(pickedImage.path);
      });
    }
  }

  Future<String?> _uploadImage(int index) async {
    if (_imageFiles[index] == null || _textControllers[index].text.isEmpty) {
      return null;
    }

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw 'User not authenticated';

      final userId = user.id;
      final file = _imageFiles[index]!;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
      final filePath = '$userId/memory_card/$fileName';

      await supabase.storage.from('memory_cards').upload(
        filePath,
        file,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );

      // Get the public URL for the uploaded image
      final imageUrl = supabase.storage.from('memory_cards').getPublicUrl(filePath);
      
      return imageUrl;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: $e')),
      );
      return null;
    }
  }

  Future<void> _uploadImages() async {
    if (!_isFormValid) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final uploadResults = <Map<String, String>>[];
      
      for (int i = 0; i < 5; i++) {
        final imageUrl = await _uploadImage(i);
        if (imageUrl != null) {
          uploadResults.add({
            'image_url': imageUrl,
            'text': _textControllers[i].text,
          });
        }
      }

      // Here you would send the results to your Node.js API
      // Example: await ApiService().uploadMemoryCardData(uploadResults);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Images uploaded successfully!')),
      );
      
      // Clear the form
      setState(() {
        for (int i = 0; i < 5; i++) {
          _textControllers[i].clear();
          _imageFiles[i] = null;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading images: $e')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _textControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Memory Card'),
        centerTitle: true,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: UserAvatar(),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[100]!, Colors.blue[50]!],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Upload Images for Memory Card',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: 5,
                  itemBuilder: (context, index) {
                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Image ${index + 1}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            InkWell(
                              onTap: () => _pickImage(index),
                              child: Container(
                                height: 150,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: _imageFiles[index] != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.file(
                                          _imageFiles[index]!,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : const Center(
                                        child: Icon(
                                          Icons.add_photo_alternate,
                                          size: 50,
                                          color: Colors.grey,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _textControllers[index],
                              decoration: const InputDecoration(
                                labelText: 'Image Name',
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isFormValid && !_isUploading
                    ? _uploadImages
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  disabledBackgroundColor: Colors.blue.withOpacity(0.5),
                ),
                child: _isUploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Upload Images',
                        style: TextStyle(fontSize: 18),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}