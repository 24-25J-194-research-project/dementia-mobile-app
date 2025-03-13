// import 'dart:io';
// import 'package:flutter/services.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:image/image.dart' as img;
// import 'package:camera/camera.dart';
// import 'package:flutter/material.dart';
// import 'package:tflite_flutter/tflite_flutter.dart';

// class MoodDetectionScreen extends StatefulWidget {
//   final VoidCallback showHomeScreen;
//   const MoodDetectionScreen({super.key, required this.showHomeScreen});

//   @override
//   State<MoodDetectionScreen> createState() => _MoodDetectionScreenState();
// }

// class _MoodDetectionScreenState extends State<MoodDetectionScreen> {
//   CameraController? _controller;
//   late List<CameraDescription> _cameras;
//   bool _isDetecting = false;
//   String _currentMood = "Detecting...";
//   Interpreter? _interpreter;
//   List<String> _labels = ["Happy", "Angry", "Calm", "Sad"];

//   bool _modelLoaded = false;
//   double _confidence = 0.0;
//   Color _moodColor = Colors.grey;

//   @override
//   void initState() {
//     super.initState();
//     _initializeCamera();
//     _loadModel();
//   }

// // Load the TFLite model
//   Future<void> _loadModel() async {
//     try {
//       // Load model from assets
//       final modelFile = await _getModel('assets/models/emotion_model.tflite');
//       final options = InterpreterOptions();

//       _interpreter = await Interpreter.fromFile(modelFile, options: options);

//       setState(() {
//         _modelLoaded = true;
//       });
//       print('Model loaded successfully');
//     } catch (e) {
//       print('Error loading model: $e');
//     }
//   }

//   // Extract model file from assets
//   Future<File> _getModel(String assetPath) async {
//     final byteData = await rootBundle.load(assetPath);
//     final tempDir = await getTemporaryDirectory();
//     final tempPath = tempDir.path;
//     final filePath = '$tempPath/emotion_model.tflite';
//     final file = File(filePath);
//     await file.writeAsBytes(byteData.buffer.asUint8List());
//     return file;
//   }

//   Future<void> _initializeCamera() async {
//     _cameras = await availableCameras();
//     _controller = CameraController(
//       _cameras![1], // Use front camera (index 1)
//       ResolutionPreset.medium,
//     );
//     await _controller!.initialize();

//     if (mounted) {
//       setState(() {});
//       _startImageStream();
//     }
//   }

//   void _startImageStream() {
//     _controller!.startImageStream((CameraImage image) {
//       if (!_isDetecting && _modelLoaded) {
//         _isDetecting = true;
//         _detectMood(image).then((_) {
//           _isDetecting = false;
//         });
//       }
//     });
//   }

//   // Convert CameraImage to format suitable for model
//   img.Image _convertYUV420ToImage(CameraImage cameraImage) {
//     final width = cameraImage.width;
//     final height = cameraImage.height;

//     final yRowStride = cameraImage.planes[0].bytesPerRow;
//     final uvRowStride = cameraImage.planes[1].bytesPerRow;
//     final uvPixelStride = cameraImage.planes[1].bytesPerPixel!;

//     final image = img.Image(width: width, height: height);

//     for (var w = 0; w < width; w++) {
//       for (var h = 0; h < height; h++) {
//         final uvIndex =
//             uvPixelStride * (w / 2).floor() + uvRowStride * (h / 2).floor();
//         final index = h * width + w;
//         final yIndex = h * yRowStride + w;

//         final y = cameraImage.planes[0].bytes[yIndex];
//         final u = cameraImage.planes[1].bytes[uvIndex];
//         final v = cameraImage.planes[2].bytes[uvIndex];

//         // Convert YUV to RGB
//         var r = (y + v * 1.13983).round();
//         var g = (y - u * 0.39465 - v * 0.58060).round();
//         var b = (y + u * 2.03211).round();

//         // Clipping RGB values to be between 0-255
//         r = r.clamp(0, 255);
//         g = g.clamp(0, 255);
//         b = b.clamp(0, 255);

//         image.setPixelRgba(w, h, r, g, b, 255);
//       }
//     }
//     return image;
//   }

//   // Process image and run inference
//   Future<void> _detectMood(CameraImage image) async {
//     if (_interpreter == null) return;

//     // Convert camera image to proper format
//     img.Image? convertedImage = _convertYUV420ToImage(image);

//     // Resize image to model input size (e.g., 48x48 for emotion models)
//     img.Image resizedImage = img.copyResize(convertedImage,
//         width: 48, height: 48, interpolation: img.Interpolation.linear);

//     // Convert to grayscale if your model requires it
//     img.Image grayscaleImage = img.grayscale(resizedImage);

//     // Convert to input tensor format
//     List<List<List<double>>> input = List.generate(
//       1,
//       (_) => List.generate(
//         48,
//         (y) => List.generate(
//           48,
//           (x) {
//             final pixel = grayscaleImage.getPixel(x, y);
//             // For grayscale images
//             return pixel.r.toDouble() / 255.0;
//           },
//         ),
//       ),
//     );

//     // Output tensor
//     List<List<double>> output = List.generate(
//       1,
//       (_) => List.generate(4, (_) => 0.0),
//     );

//     // Run inference
//     _interpreter!.run(input, output);

//     // Get prediction result
//     final result = output[0];

//     // Find the emotion with highest probability
//     int maxIndex = 0;
//     double maxProb = result[0];

//     for (int i = 1; i < result.length; i++) {
//       if (result[i] > maxProb) {
//         maxProb = result[i];
//         maxIndex = i;
//       }
//     }

//     // Update UI with detected mood
//     setState(() {
//       _currentMood = _labels[maxIndex];
//       _confidence = maxProb;

//       // Set color based on mood
//       switch (_currentMood) {
//         case 'Happy':
//           _moodColor = Colors.yellow;
//           break;
//         case 'Angry':
//           _moodColor = Colors.red;
//           break;
//         case 'Calm':
//           _moodColor = Colors.blue;
//           break;
//         case 'Sad':
//           _moodColor = Colors.purple;
//           break;
//         default:
//           _moodColor = Colors.grey;
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_controller == null || !_controller!.value.isInitialized) {
//       return Scaffold(
//         body: Center(
//           child: CircularProgressIndicator(),
//         ),
//       );
//     }

//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Melody Mind - Mood Detection'),
//         backgroundColor: Colors.black87,
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             flex: 3,
//             child: Stack(
//               children: [
//                 CameraPreview(_controller!),
//                 // Face outline overlay here if needed
//               ],
//             ),
//           ),
//           Expanded(
//             flex: 2,
//             child: Container(
//               width: double.infinity,
//               padding: EdgeInsets.all(20),
//               color: Colors.black87,
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Text(
//                     'Your Current Mood',
//                     style: TextStyle(
//                       fontSize: 18,
//                       color: Colors.white70,
//                     ),
//                   ),
//                   SizedBox(height: 10),
//                   Container(
//                     padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                     decoration: BoxDecoration(
//                       color: _moodColor.withOpacity(0.2),
//                       borderRadius: BorderRadius.circular(30),
//                       border: Border.all(color: _moodColor, width: 2),
//                     ),
//                     child: Text(
//                       _currentMood,
//                       style: TextStyle(
//                         fontSize: 28,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.white,
//                       ),
//                     ),
//                   ),
//                   SizedBox(height: 20),
//                   Text(
//                     'Confidence: ${(_confidence * 100).toStringAsFixed(1)}%',
//                     style: TextStyle(
//                       fontSize: 16,
//                       color: Colors.white70,
//                     ),
//                   ),
//                   SizedBox(height: 20),
//                   ElevatedButton(
//                     onPressed: () {
//                       // Navigate to music selection based on mood
//                       // Navigator.push(
//                       //   context,
//                       //   MaterialPageRoute(
//                       //     builder: (context) =>
//                       //         MusicRecommendationScreen(mood: _currentMood),
//                       //   ),
//                       // );
//                     },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: _moodColor,
//                       padding:
//                           EdgeInsets.symmetric(horizontal: 32, vertical: 16),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(30),
//                       ),
//                     ),
//                     child: Text(
//                       'Get Music Recommendations',
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _controller?.dispose();
//     _interpreter?.close();
//     super.dispose();
//   }
// }
