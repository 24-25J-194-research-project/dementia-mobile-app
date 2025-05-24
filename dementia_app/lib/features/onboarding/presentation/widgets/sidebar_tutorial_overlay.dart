import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/onboarding_provider.dart';

class SidebarTutorialOverlay extends StatefulWidget {
  final VoidCallback onOpenDrawer;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const SidebarTutorialOverlay({
    Key? key,
    required this.onOpenDrawer,
    required this.onNext,
    required this.onSkip,
  }) : super(key: key);

  @override
  State<SidebarTutorialOverlay> createState() => _SidebarTutorialOverlayState();
}

class _SidebarTutorialOverlayState extends State<SidebarTutorialOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isVisible = true;

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

    // Automatically open drawer after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        widget.onOpenDrawer();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleNext() async {
    setState(() => _isVisible = false);
    await _controller.reverse();
    if (mounted) {
      await Provider.of<OnboardingProvider>(context, listen: false)
          .completeSidebarTutorial();
      widget.onNext();
    }
  }

  void _handleSkip() async {
    setState(() => _isVisible = false);
    await _controller.reverse();
    if (mounted) {
      await Provider.of<OnboardingProvider>(context, listen: false)
          .skipOnboarding();
      widget.onSkip();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();

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
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).padding.bottom + 20,
            child: Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Explore the Menu',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Here\'s what you can do:',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureItem(
                      icon: Icons.photo_album,
                      title: 'Memories',
                      description: 'Store and view precious memories',
                    ),
                    _buildFeatureItem(
                      icon: Icons.play_circle,
                      title: 'Reminiscence Therapies',
                      description: 'Engage in therapeutic activities',
                    ),
                    _buildFeatureItem(
                      icon: Icons.account_circle,
                      title: 'Patient Profile',
                      description: 'Manage patient information',
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: _handleSkip,
                          child: const Text('Skip'),
                        ),
                        ElevatedButton(
                          onPressed: _handleNext,
                          child: const Text('Next'),
                        ),
                      ],
                    ),
                  ],
                ),
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
          Icon(icon, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
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
