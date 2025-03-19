import 'dart:io';
import 'package:dementia_app/API/memory_card_image_upload_api.dart';
import 'package:dementia_app/Pages/Cognitive_training/memory_card.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import '../../Components/user_avatar.dart';


class MemoryCardImageUploadPage extends StatefulWidget {
  const MemoryCardImageUploadPage({super.key});

  @override
  State<MemoryCardImageUploadPage> createState() => _MemoryCardImageUploadPageState();
}

class _MemoryCardImageUploadPageState extends State<MemoryCardImageUploadPage> {
  final supabase = Supabase.instance.client;
  final List<TextEditingController> _textControllers = List.generate(
      5, (index) => TextEditingController());
  final List<File?> _imageFiles = List.filled(5, null);
  bool _isUploading = false;
  bool _isLoading = true;

    @override
  void initState() {
    super.initState();
    _checkExistingImages();
  }

Future<void> _checkExistingImages() async {
  try {
    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    final userId = user.id;
    final folderPath = '$userId/memory_card';
    
    //set a timeout for the storage request
    final storageResponse = await Future.any([
      supabase.storage.from('cognitive_training').list(path: folderPath),
      Future.delayed(const Duration(seconds: 3), () => throw 'timeout')
    ]);
    
    //continue to upload if not enough images
    if (storageResponse.length < 5) {
      setState(() => _isLoading = false);
      return;
    }
    
    //process image data in parallel
    final futures = <Future<Map<String, String>>>[];
    
    for (int i = 0; i < 5; i++) {
      futures.add(_processImageData(folderPath, storageResponse[i]));
    }
    
    final results = await Future.wait(futures);
    
    //navigate to the activity
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MemoryCardGamePage(cardData: results),
        ),
      );
    }
  } catch (e) {
    //continue to upload page on error
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}

  Future<Map<String, String>> _processImageData(String folderPath, FileObject fileData) async {
    final filePath = '$folderPath/${fileData.name}';
    final imageUrl = await supabase.storage.from('cognitive_training').createSignedUrl(
      filePath, 
      60 * 60 * 24 * 30, //30 days expiry
    );
    
    //get the actual text from the database instead of parsing filename
    final user = supabase.auth.currentUser;
    if (user == null) throw 'User not authenticated';
    
    //query the database to get the card_text that matches this image URL
    final response = await supabase
        .from('memory_card')
        .select('card_text')
        .eq('user_id', user.id)
        .eq('image_url', imageUrl)
        .maybeSingle();
    
    //if found in database, use that text, otherwise fallback to filename
    String cardText;
    if (response != null && response['card_text'] != null) {
      cardText = response['card_text'];
    } else {
      //try to extract from filename as fallback
      final fileName = path.basenameWithoutExtension(fileData.name);
      //try to find text part between first and second underscore
      final parts = fileName.split('_');
      if (parts.length >= 3) {
        //the text should be the second part (index 1) if filename format is timestamp_text_remainder
        cardText = parts[1];
      } else {
        cardText = fileName; //use whole filename if can't parse
      }
    }
    
    return {
      'image_url': imageUrl,
      'text': cardText,
    };
  }

  bool get _isFormValid {
    //check if ALL pairs of images and text are filled
    for (int i = 0; i < 5; i++) {
      if (_imageFiles[i] == null || _textControllers[i].text.isEmpty) {
        return false;
      }
    }
    return true;
  }

  Future<CroppedFile?> _cropImage(String sourcePath) async {
    return await ImageCropper().cropImage(
      sourcePath: sourcePath,
      compressQuality: 90,
      compressFormat: ImageCompressFormat.jpg,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: Colors.blue,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: false,
        ),
        IOSUiSettings(
          title: 'Crop Image',
          aspectRatioLockEnabled: false,
        ),
      ],
    );
  }

  Future<void> _pickImage(int index) async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedImage = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedImage != null) {
      //crop the image
      final croppedFile = await _cropImage(pickedImage.path);
      
      if (croppedFile != null) {
        setState(() {
          _imageFiles[index] = File(croppedFile.path);
        });
      }
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
      final text = _textControllers[index].text.trim();
      
      //include the text in the filename - format: timestamp_TEXT_originalname
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${text}_${path.basename(file.path)}';
      final filePath = '$userId/memory_card/$fileName';

      await supabase.storage.from('cognitive_training').upload(
        filePath,
        file,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );

      //get the public URL for the uploaded image
      final imageUrl = await supabase.storage.from('cognitive_training').createSignedUrl(
        filePath, 
        60 * 60 * 24 * 365, //365 days expiry
      );
      
      return imageUrl;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error uploading image')),
      );
      return null;
    }
  }

  
  //method to upload all images and send to API
  Future<void> _uploadImages() async {
    if (!_isFormValid) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final uploadResults = <Map<String, String>>[];
      final apiResults = <Map<String, dynamic>>[];
      
      //get current user ID
      final user = supabase.auth.currentUser;
      if (user == null) throw 'User not authenticated';
      final userId = user.id;
      
      //upload all images to Supabase
      for (int i = 0; i < 5; i++) {
        final imageUrl = await _uploadImage(i);
        if (imageUrl != null) {
          //add to results for the game
          uploadResults.add({
            'image_url': imageUrl,
            'text': _textControllers[i].text,
          });
          
          //prepare data for API in the required format
          apiResults.add({
            'cognitive_training_id': 3,
            'card_text': _textControllers[i].text,
            'image_url': imageUrl,
            'user_id': userId,
          });
        }
      }
      
      //check if all images were uploaded successfully
      if (uploadResults.length != 5) {
        throw Exception('Some images failed to upload');
      }

      //send the data to the API
      try {
        final apiService = MemoryCardUploadApiService();
        final success = await apiService.uploadMemoryCardData(apiResults);
        
        if (!success) {
          throw Exception('Failed to save card data to database');
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(
              content: Text('Images uploaded and saved successfully!'),
              backgroundColor: Colors.green,
              duration:  Duration(seconds: 5),
            ),
        );
      } catch (apiError) {
        // If API call fails, but images are uploaded, show specific error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Images uploaded, but failed to save to database'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 5),
          ),
        );
        
        //show retry dialog
        if (context.mounted) {
          _retryDatabaseSave(apiResults);
        }
        
        //still proceed to game since images are available
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MemoryCardGamePage(cardData: uploadResults),
            ),
          );
        }
        return;
      }
      
      //clear the form
      setState(() {
        for (int i = 0; i < 5; i++) {
          _textControllers[i].clear();
          _imageFiles[i] = null;
        }
      });

      //navigate to the game page
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MemoryCardGamePage(cardData: uploadResults),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error uploading images'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }


  Future<void> _retryDatabaseSave(List<Map<String, dynamic>> apiData) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Retry Saving to Database?'),
        content: const Text(
          'Your images were uploaded to storage but failed to save to the database. '
          'Would you like to retry saving to the database?'
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              setState(() {
                _isUploading = true;
              });
              
              try {
                final apiService = MemoryCardUploadApiService();
                final success = await apiService.uploadMemoryCardData(apiData);
                
                if (!success) {
                  throw Exception('Failed to save card data to database');
                }
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Card data saved to database successfully!')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to save to database'),
                    backgroundColor: Colors.red,
                  ),
                );
              } finally {
                setState(() {
                  _isUploading = false;
                });
              }
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
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
    if(_isLoading){
      return Scaffold(
        appBar: AppBar(
          title: const Text('Memory Card'),
          centerTitle: true,
          backgroundColor: Colors.white,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.blue[100]!, Colors.blue[50]!],
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Checking for existing images...'),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Memory Card'),
        centerTitle: true,
        backgroundColor: Colors.white,
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
                  color: Color.fromARGB(255, 13, 72, 161),
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