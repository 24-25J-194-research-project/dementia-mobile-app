// /lib/routes/app_routes.dart

import 'package:dementia_app/features/auth/presentation/screens/login.dart';
import 'package:dementia_app/features/auth/presentation/screens/signup.dart';
import 'package:dementia_app/features/home/presentation/screens/home_screen.dart';
import 'package:flutter/material.dart';

import '../features/profile/presentation/screens/profile_screen.dart';

class AppRoutes {
  static const String home = '/home';
  static const String signUp = '/signup';
  static const String login = '/login';
  static const String profile = '/profile';

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
      default:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
    }
  }
}
