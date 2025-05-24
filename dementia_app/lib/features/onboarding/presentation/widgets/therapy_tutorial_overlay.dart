import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/onboarding_provider.dart';

class TherapyTutorialOverlay extends StatefulWidget {
  final VoidCallback onComplete;

  const TherapyTutorialOverlay({
    Key? key,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<TherapyTutorialOverlay> createState() => _TherapyTutorialOverlayState();
}

class _TherapyTutorialOverlayState extends State<TherapyTutorialOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
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

  void _handleComplete() async {
    await _controller.reverse();
    if (mounted) {
      await Provider.of<OnboardingProvider>(context, listen: false)
          .completeTherapyTutorial();
      widget.onComplete();
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
                    'Reminiscence Therapy Session',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                      decoration: TextDecoration.none,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Let\'s explore how therapy sessions work:',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                      height: 1.4,
                      decoration: TextDecoration.none,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureItem(
                    icon: Icons.play_circle_outline,
                    title: 'Start Session',
                    description: 'Begin by clicking the "Start Therapy" button',
                  ),
                  _buildFeatureItem(
                    icon: Icons.navigate_next,
                    title: 'Navigate Steps',
                    description:
                        'Use Next and Previous buttons to move through the session',
                  ),
                  _buildFeatureItem(
                    icon: Icons.check_circle_outline,
                    title: 'Complete Session',
                    description:
                        'Once you have viewed all the steps, you can finish the session and provide the feedback. Your feedback helps improve future sessions',
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _handleComplete,
                    child: const Text('Got it!'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Theme.of(context).primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                    decoration: TextDecoration.none,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.4,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
