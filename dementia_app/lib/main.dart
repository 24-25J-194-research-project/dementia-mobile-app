import 'package:dementia_app/features/auth/presentation/providers/auth_service.dart';
import 'package:dementia_app/features/auth/presentation/screens/login.dart';
import 'package:dementia_app/features/home/presentation/screens/home_screen.dart';
import 'package:dementia_app/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:dementia_app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'l10n/providers/locale_provider.dart';

Future<void> main() async {
  await dotenv.load();
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => OnboardingProvider()),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, child) {
          return MaterialApp(
            title: 'Memory Bloom',
            theme: ThemeData(
              primarySwatch: Colors.blue,
              visualDensity: VisualDensity.adaptivePlatformDensity,
              textTheme: Theme.of(context).textTheme.apply(
                    bodyColor: Colors.black87,
                    displayColor: Colors.black87,
                    decoration: TextDecoration.none,
                  ),
            ),
            locale: localeProvider.locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const AuthChecker(),
            onGenerateRoute: AppRoutes.generateRoute,
          );
        },
      ),
    );
  }
}

class AuthChecker extends StatelessWidget {
  const AuthChecker({super.key});

  Future<bool> _initializeApp(BuildContext context) async {
    final isLoggedIn = await AuthService().isLoggedIn();
    if (isLoggedIn) {
      final user = await AuthService().getCurrentUser();
      if (user != null) {
        // Load onboarding status before showing home screen
        await Provider.of<OnboardingProvider>(context, listen: false)
            .loadOnboardingStatus(user.uid);
      }
    }
    return isLoggedIn;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _initializeApp(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == true) {
          return const HomeScreen();
        }

        return LoginPage();
      },
    );
  }
}
