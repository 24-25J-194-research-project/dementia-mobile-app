// noise_calibration_dialog.dart
import 'dart:async';
import 'package:dementia_app/utils/appColors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

class NoiseCalibrationDialog extends StatefulWidget {
  final Function(double) onCalibrationComplete;

  const NoiseCalibrationDialog({
    Key? key,
    required this.onCalibrationComplete,
  }) : super(key: key);

  @override
  State<NoiseCalibrationDialog> createState() => _NoiseCalibrationDialogState();
}

class _NoiseCalibrationDialogState extends State<NoiseCalibrationDialog> {
  int _remainingSeconds = 3;
  double _currentNoiseLevel = 0.0;
  Timer? _timer;
  bool _calibrationComplete = false;

  @override
  void initState() {
    super.initState();
    _startCalibration();
  }

  void _startCalibration() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        timer.cancel();
        setState(() {
          _calibrationComplete = true;
        });
        //wait a moment before closing the dialog
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            Navigator.of(context).pop();

            Future.microtask(() {
              widget.onCalibrationComplete(_currentNoiseLevel);
            });
          }
        });
      }
    });
  }

  void _updateNoiseLevel(double level) {
    setState(() {
      _currentNoiseLevel = level;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      contentPadding: const EdgeInsets.all(24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Listening to Environment",
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.deepBlue,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            "Please stay quiet for a moment while we adjust for background noise",
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // Animation for listening
          SizedBox(
            width: 150,
            height: 150,
            child: _calibrationComplete
                ? Lottie.asset(
                    'assets/animations/complete_blue.json',
                    repeat: false,
                  )
                : Lottie.asset(
                    'assets/animations/analyzing.json',
                    repeat: true,
                  ),
          ),
          const SizedBox(height: 16),
          if (!_calibrationComplete)
            Text(
              "$_remainingSeconds",
              style: GoogleFonts.inter(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            )
          else
            Text(
              "All Set!",
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          const SizedBox(height: 16),
          if (!_calibrationComplete)
            LinearProgressIndicator(
              value: (3 - _remainingSeconds) / 3,
              backgroundColor: Colors.grey[200],
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
            ),
        ],
      ),
    );
  }
}
