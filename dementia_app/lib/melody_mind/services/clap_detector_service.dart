import 'dart:async';
import 'dart:math';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';

class ClapDetectorService {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final int sampleRate = 44100;
  final int bufferSize = 1024;
  double clapThreshold = 1000.0;
  StreamSubscription? _subscription;
  Function()? onClapDetected;

  bool _isHighVolumeDetected = false;
  double _lastVolume = 0;
  double _volumeThreshold = 10.0;
  final int _volumeRiseThreshold = 5;

  List<double> _calibrationSamples = [];
  bool _isCalibrating = false;
  Function(double)? onCalibrationUpdate;
  Function(double)? onCalibrationComplete;

  Future<void> init() async {
    //request microphone permission
    await Permission.microphone.request();
    await _recorder.openRecorder();
    await _recorder.setSubscriptionDuration(const Duration(milliseconds: 50));
  }

  //start the calibration process
  Future<void> startCalibration() async {
    _isCalibrating = true;
    _calibrationSamples = [];

    if (_recorder.isRecording) {
      print("ClapDetector: Stopping existing recording before calibration");
      await _subscription?.cancel();
      await _recorder.stopRecorder();
      await Future.delayed(const Duration(milliseconds: 200));
    }
    try {
      await _recorder.startRecorder(
          codec: Codec.pcm16,
          sampleRate: sampleRate,
          bitRate: 16000,
          numChannels: 1);

      print("ClapDetector: Calibration recording started successfully");

      _subscription = _recorder.onProgress!.listen((event) {
        if (event.decibels != null) {
          print("ClapDetector: Got calibration sample: ${event.decibels}");
          _collectCalibrationSample(event.decibels!);
          onCalibrationUpdate?.call(event.decibels!);
        } else {
          print("ClapDetector: Received null decibels in calibration");
        }
      });
    } catch (e) {
      print("ClapDetector: Error starting calibration recording: $e");
      //use default values if recording fails
      _finalizeCalibration();
    }
  }

  void _collectCalibrationSample(double decibel) {
    if (_isCalibrating) {
      _calibrationSamples.add(decibel);

      // // Update calibration progress
      // onCalibrationUpdate?.call(decibel);
      //if we have enough samples, finalize calibration
      if (_calibrationSamples.length >= 30) {
        print(
            "ClapDetector: Collected ${_calibrationSamples.length} samples, finalizing calibration");
        // About 1.5 seconds with 50ms updates
        _finalizeCalibration();
      }
    }
  }

  void _finalizeCalibration() {
    _isCalibrating = false;

    //check if we have enough samples
    if (_calibrationSamples.isEmpty) {
      print("ClapDetector: No calibration samples collected!");
      _volumeThreshold = 10.0;
      clapThreshold = 500.0;

      //stop recorder
      _subscription?.cancel();
      _recorder.stopRecorder();

      //notify that calibration is complete with default values
      onCalibrationComplete?.call(_volumeThreshold);
      return;
    }

    //calculate average and standard deviation of background noise
    double sum = 0;
    for (var sample in _calibrationSamples) {
      sum += sample;
    }

    double avgNoise = sum / _calibrationSamples.length;

    //calculate standard deviation
    double varianceSum = 0;
    for (var sample in _calibrationSamples) {
      varianceSum += pow(sample - avgNoise, 2);
    }
    double stdDev = sqrt(varianceSum / _calibrationSamples.length);

    //set thresholds based on background noise
    _volumeThreshold = avgNoise + (1.3 * stdDev);

    // more moderate threshold
    clapThreshold = avgNoise + (2 * stdDev);

    print("ClapDetector: Calibration complete");
    print("ClapDetector: Average noise: $avgNoise dB");
    print("ClapDetector: Noise StdDev: $stdDev dB");
    print("ClapDetector: Volume threshold set to: $_volumeThreshold dB");
    print("ClapDetector: Clap threshold set to: $clapThreshold");

    //stop recorder temporarily
    _subscription?.cancel();
    _recorder.stopRecorder();

    //notify that calibration is complete
    onCalibrationComplete?.call(_volumeThreshold);
  }

  void startListening() {
    if (_recorder.isRecording) {
      print("ClapDetector: Recorder already active, stopping first");
      _subscription?.cancel();
      _recorder.stopRecorder().then((_) {
        Future.delayed(Duration(milliseconds: 200), () {
          _actuallyStartListening();
        });
      });
    } else {
      _actuallyStartListening();
    }
  }

  void _actuallyStartListening() {
    print("ClapDetector: Actually starting recording for clap detection");
    _recorder
        .startRecorder(
            codec: Codec.pcm16,
            sampleRate: sampleRate,
            bitRate: 16000,
            numChannels: 1)
        .then((_) {
      print("ClapDetector: Recorder started successfully for clap detection");
    }).catchError((error) {
      print("ClapDetector: Error starting recorder for clap detection: $error");
    });

    _subscription = _recorder.onProgress!.listen((event) {
      if (event.decibels == null) {
        print("ClapDetector: Decibels value is null in clap detection");
      } else {
        print("Decibels: ${event.decibels}");
        _detectClapFromVolume(event.decibels!);
      }
    });
  }

  void _detectClapFromVolume(double currentVolume) {
    double volumeDifference = currentVolume - _lastVolume;

    if (volumeDifference > _volumeRiseThreshold &&
        currentVolume > _volumeThreshold &&
        !_isHighVolumeDetected) {
      _isHighVolumeDetected = true;
      onClapDetected?.call();

      //rreset after a short delay to prevent multiple detections of same clap
      Timer(const Duration(milliseconds: 300), () {
        _isHighVolumeDetected = false;
      });
    }

    _lastVolume = currentVolume;
  }

  void stopListening() {
    _subscription?.cancel();
    _recorder.stopRecorder();
  }

  void dispose() {
    stopListening();
    _recorder.closeRecorder();
  }
}
