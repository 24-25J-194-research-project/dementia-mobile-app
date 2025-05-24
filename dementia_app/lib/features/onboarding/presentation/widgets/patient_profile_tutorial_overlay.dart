import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/onboarding_provider.dart';

class PatientProfileTutorialOverlay extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const PatientProfileTutorialOverlay({
    Key? key,
    required this.onNext,
    required this.onSkip,
  }) : super(key: key);

  @override
  State<PatientProfileTutorialOverlay> createState() =>
      _PatientProfileTutorialOverlayState();
}

class _PatientProfileTutorialOverlayState
    extends State<PatientProfileTutorialOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleNext() async {
    await _controller.reverse();
    if (mounted) {
      await Provider.of<OnboardingProvider>(context, listen: false)
          .completePatientProfile();
      widget.onNext();
    }
  }

  void _handleSkip() async {
    await _controller.reverse();
    if (mounted) {
      await Provider.of<OnboardingProvider>(context, listen: false)
          .skipOnboarding();
      widget.onSkip();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Stack(
        children: [
          // Semi-transparent background
          Positioned.fill(
            child: Container(
              color: Colors.black54,
            ),
          ),
          // Tutorial content
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Patient Profile: The Key to Personalization',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Your patient profile helps us create a more meaningful and personalized therapy experience.',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Add important details about the patient, including:\n'
                    '• Personal background\n'
                    '• Family members\n'
                    '• Life experiences\n'
                    '• Education history',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.left,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'This information helps us tailor reminiscence therapies to make them more effective and meaningful.',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: _handleSkip,
                        child: const Text('Skip'),
                      ),
                      ElevatedButton(
                        onPressed: _handleNext,
                        child: const Text('Go to Profile'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
