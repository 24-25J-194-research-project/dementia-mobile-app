// /lib/routes/app_routes.dart

import 'package:dementia_app/features/auth/presentation/screens/login.dart';
import 'package:dementia_app/features/auth/presentation/screens/signup.dart';
import 'package:dementia_app/features/home/presentation/screens/home_screen.dart';
import 'package:dementia_app/features/memories/presentation/screens/memory_screen.dart';
import 'package:flutter/material.dart';

import '../features/memories/domain/entities/memory_model.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/reminiscence_therapy/domain/entities/therapy_outline.dart';
import '../features/reminiscence_therapy/presentation/screens/play_therapy_screen.dart';
import '../features/reminiscence_therapy/presentation/screens/therapy_list_screen.dart';

class AppRoutes {
  static const String home = '/home';
  static const String signUp = '/signup';
  static const String login = '/login';
  static const String profile = '/profile';
  static const String memories = '/memories';
  static const String reminiscenceTherapies = '/reminiscence-therapies';
  static const String playTherapy = '/play-therapy';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case signUp:
        return MaterialPageRoute(builder: (_) => const SignUpPage());
      case login:
        return MaterialPageRoute(builder: (_) => LoginPage());
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case memories:
        return MaterialPageRoute(builder: (_) => const MemoryScreen());
      case reminiscenceTherapies:
        return MaterialPageRoute(builder: (_) => const ReminiscenceTherapiesScreen());
      case playTherapy:
        final args = settings.arguments as Map<String, dynamic>;
        final therapyOutline = args['therapyOutline'] as TherapyOutline;
        final memory = args['memory'] as Memory;
        return MaterialPageRoute(
          builder: (_) => PlayTherapyScreen(therapyOutline: therapyOutline, memory: memory),
        );
      default:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
    }
  }
}
