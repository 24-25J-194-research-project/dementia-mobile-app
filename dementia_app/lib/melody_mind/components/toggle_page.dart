import 'package:dementia_app/melody_mind/components/melody_onboarding_screen.dart';
import 'package:dementia_app/screens/melody_mind/music_library_screen.dart';
import 'package:flutter/material.dart';

class TogglePage extends StatefulWidget {
  const TogglePage({super.key});

  @override
  State<TogglePage> createState() => _TogglePageState();
}

class _TogglePageState extends State<TogglePage> {
  // 0 = Home Screen, 1 = Music Library Screen
  int _currentScreen = 0;

  void _showHomeScreen() {
    setState(() {
      _currentScreen = 0;
    });
  }

  void _showMusicLibraryScreen() {
    setState(() {
      _currentScreen = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_currentScreen) {
      case 0:
        return MelodyOnboardingScreen(
          showMusicLibraryScreen: _showMusicLibraryScreen,
        );
      case 1:
        return MusicLibraryScreen(
          showHomeScreen: _showHomeScreen,
        );
      default:
        return MelodyOnboardingScreen(
          showMusicLibraryScreen: _showMusicLibraryScreen,
        );
    }
  }
}
