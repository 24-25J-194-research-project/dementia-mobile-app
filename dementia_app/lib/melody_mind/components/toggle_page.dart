import 'package:dementia_app/melody_mind/components/home_screen.dart';
import 'package:dementia_app/screens/melody_mind/prompt_screen.dart';
import 'package:flutter/material.dart';

class TogglePage extends StatefulWidget {
  const TogglePage({super.key});

  @override
  State<TogglePage> createState() => _TogglePageState();
}

class _TogglePageState extends State<TogglePage> {
  bool _showHomeScreen = true;

  void _toggleScreen() {
    setState(() {
      _showHomeScreen = !_showHomeScreen;
    });
  }
  @override
  Widget build(BuildContext context) {
    if ( _showHomeScreen) {
      return HomeScreen(
        showPromptScreen: _toggleScreen,
      );
    }else{
      return PromptScreen(
        showHomeScreen: _toggleScreen,
      );
    }
  }
}