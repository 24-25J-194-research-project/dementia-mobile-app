// import 'dart:async';
// import 'dart:math';
// import 'dart:collection';
// import 'package:flutter/material.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:flutter_sound/flutter_sound.dart';

// /// Enhanced SoundDetector with amplitude smoothing and dynamic thresholding
// class SoundDetector {
//   final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
//   StreamSubscription? _recorderSubscription;
//   bool _isRecording = false;

//   // Callback for when clap/snap is detected
//   final Function() onSoundDetected;

//   // Threshold settings
//   double _threshold = 0.2; // Default threshold (0.0 to 1.0)
//   int _cooldownMs = 300; // Cooldown period to prevent multiple detections
//   DateTime? _lastDetection;

//   // Amplitude smoothing for more accurate detection
//   final Queue<double> _amplitudeBuffer = Queue<double>();
//   final int _bufferSize =
//       10; // Number of samples to keep for average background noise
//   double _backgroundNoise = 0.0; // Average background noise level
//   bool _isCalibrating = true; // Initially calibrating to room noise
//   int _calibrationSamples = 0;
//   final int _calibrationTime = 20; // Number of samples to use for calibration

//   // Analytics
//   int _totalDetections = 0;
//   double _lastAmplitude = 0.0;

//   SoundDetector({required this.onSoundDetected});

//   // Initialize and request permissions
//   Future<bool> init() async {
//     final status = await Permission.microphone.request();
//     if (status != PermissionStatus.granted) {
//       return false;
//     }

//     try {
//       await _recorder.openRecorder();
//       // Set up recorder parameters
//       await _recorder.setSubscriptionDuration(const Duration(milliseconds: 50));
//       return true;
//     } catch (e) {
//       print('Error initializing recorder: $e');
//       return false;
//     }
//   }

//   // Start listening for sounds
//   Future<void> startListening() async {
//     if (_isRecording) return;

//     try {
//       // Reset calibration on start
//       _resetCalibration();

//       // Start recording
//       await _recorder.startRecorder(
//         toFile: 'temp_audio', // Temporary file path
//         codec: Codec.pcm16,
//         numChannels: 1,
//         sampleRate: 16000,
//       );

//       _isRecording = true;

//       // Listen to audio updates
//       _recorderSubscription =
//           _recorder.onProgress!.listen((RecordingDisposition event) {
//         // Get decibel level from the recording disposition
//         final double? decibels = event.decibels;
//         if (decibels != null) {
//           _processAmplitude(decibels);
//         }
//       });

//       print('Started listening for claps/snaps');
//     } catch (e) {
//       print('Error starting sound detection: $e');
//     }
//   }

//   // Reset calibration
//   void _resetCalibration() {
//     _isCalibrating = true;
//     _calibrationSamples = 0;
//     _amplitudeBuffer.clear();
//     _backgroundNoise = 0.0;
//   }

//   // Stop listening
//   Future<void> stopListening() async {
//     if (!_isRecording) return;

//     try {
//       await _recorderSubscription?.cancel();
//       await _recorder.stopRecorder();
//       _isRecording = false;
//       print('Stopped listening for claps/snaps');
//     } catch (e) {
//       print('Error stopping sound detection: $e');
//     }
//   }

//   // Process amplitude level
//   void _processAmplitude(double decibels) {
//     // Convert dB to amplitude ratio (0.0 to 1.0)
//     // Typically values are between -60dB (quiet) to 0dB (loud)
//     final double normalizedAmp = min(1.0, max(0.0, (decibels + 60) / 60));
//     _lastAmplitude = normalizedAmp;

//     // During calibration phase, establish the baseline noise level
//     if (_isCalibrating) {
//       _amplitudeBuffer.add(normalizedAmp);
//       _calibrationSamples++;

//       if (_calibrationSamples >= _calibrationTime) {
//         // Complete calibration
//         _isCalibrating = false;
//         _backgroundNoise = _calculateAverageAmplitude();
//         print(
//             'Calibration complete. Background noise level: ${_backgroundNoise.toStringAsFixed(3)}');
//       }
//       return;
//     }

//     // Add sample to buffer for noise tracking
//     _amplitudeBuffer.add(normalizedAmp);
//     if (_amplitudeBuffer.length > _bufferSize) {
//       _amplitudeBuffer.removeFirst();
//     }

//     // Gradually update background noise level (except during spikes)
//     if (normalizedAmp < _backgroundNoise + 0.1) {
//       _backgroundNoise = 0.95 * _backgroundNoise + 0.05 * normalizedAmp;
//     }

//     // Calculate how much this sample exceeds the background
//     double excessAmplitude = normalizedAmp - _backgroundNoise;

//     // Debug amplitude for high values
//     if (excessAmplitude > 0.1) {
//       print(
//           'Sound level: ${normalizedAmp.toStringAsFixed(2)} (${excessAmplitude.toStringAsFixed(2)} above noise)');
//     }

//     // Check if we're in cooldown period
//     final now = DateTime.now();
//     if (_lastDetection != null &&
//         now.difference(_lastDetection!).inMilliseconds < _cooldownMs) {
//       return;
//     }

//     // Compare excess amplitude to threshold
//     if (excessAmplitude > _threshold) {
//       _lastDetection = now;
//       _totalDetections++;
//       print(
//           'Sound detected! Amplitude: ${normalizedAmp.toStringAsFixed(2)}, Excess: ${excessAmplitude.toStringAsFixed(2)}');
//       onSoundDetected();
//     }
//   }

//   // Calculate average amplitude from buffer
//   double _calculateAverageAmplitude() {
//     if (_amplitudeBuffer.isEmpty) return 0.0;
//     double sum = 0.0;
//     for (var amp in _amplitudeBuffer) {
//       sum += amp;
//     }
//     return sum / _amplitudeBuffer.length;
//   }

//   // Update threshold settings
//   void setThreshold(double threshold) {
//     _threshold = threshold.clamp(0.05, 0.95);
//     print('Threshold updated to: $_threshold');
//   }

//   // Update cooldown period
//   void setCooldown(int milliseconds) {
//     _cooldownMs = milliseconds.clamp(100, 1000);
//   }

//   // Get current sound level (useful for UI visualization)
//   double getCurrentAmplitude() => _lastAmplitude;

//   // Get relative sound level (how much above background)
//   double getExcessAmplitude() => max(0.0, _lastAmplitude - _backgroundNoise);

//   // Get detection analytics
//   int getTotalDetections() => _totalDetections;

//   // Reset analytics
//   void resetAnalytics() {
//     _totalDetections = 0;
//   }

//   // Check if currently listening
//   bool get isListening => _isRecording;

//   // Check if still calibrating
//   bool get isCalibrating => _isCalibrating;

//   // Release resources
//   Future<void> dispose() async {
//     await stopListening();
//     await _recorder.closeRecorder();
//   }
// }
