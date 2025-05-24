import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../auth/presentation/providers/auth_service.dart';
import '../../../memories/data/repositories/memory_repository_impl.dart';
import '../../../memories/domain/entities/memory_model.dart';
import '../../../memories/domain/use_cases/memory_use_case.dart';
import '../../../onboarding/presentation/providers/onboarding_provider.dart';
import '../../../onboarding/presentation/widgets/patient_profile_tutorial_overlay.dart';
import '../../../onboarding/presentation/widgets/sidebar_tutorial_overlay.dart';
import '../../../onboarding/presentation/widgets/welcome_tutorial_overlay.dart';
import '../../../reminiscence_therapy/data/repositories/therapy_outline_repository_impl.dart';
import '../../../reminiscence_therapy/domain/entities/therapy_outline.dart';
import '../../../reminiscence_therapy/domain/use_cases/therapy_outline_use_case.dart';
import '../widgets/drawer_menu.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  bool isLoading = true;
  String? patientId;
  List<TherapyOutline> therapyOutlines = [];
  List<Memory> memories = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final TherapyOutlineUseCase _therapyOutlineUseCase = TherapyOutlineUseCase(
    TherapyOutlineRepositoryImpl(),
  );
  final MemoryUseCase _memoryUseCase = MemoryUseCase(MemoryRepository());

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      final user = await AuthService().getCurrentUser();
      if (user != null) {
        patientId = user.uid;

        if (patientId != null) {
          therapyOutlines = await _therapyOutlineUseCase
              .fetchCompletedTherapyOutlines(patientId!);
        }

        if (therapyOutlines.isEmpty) {
          setState(() {
            isLoading = false;
          });
          return;
        }

        List<String> memoryIds =
            therapyOutlines.map((outline) => outline.memoryId).toList();
        memories = await _memoryUseCase.getMemoryByIds(memoryIds);

        setState(() {
          isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('User not logged in')));
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading therapy outlines: $e')),
      );
    }
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  void _handleOnboardingComplete() {
    setState(() {}); // Refresh the UI
  }

  void _navigateToProfile() {
    Navigator.pushNamed(context, '/profile');
  }

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return "Good Morning";
    } else if (hour < 17) {
      return "Good Afternoon";
    } else {
      return "Good Evening";
    }
  }

  @override
  Widget build(BuildContext context) {
    final onboardingProvider = Provider.of<OnboardingProvider>(context);
    final onboardingStatus = onboardingProvider.onboardingStatus;
    final bool isOnboardingLoading = onboardingProvider.isLoading;

    Widget? tutorialOverlay;
    if (!isOnboardingLoading) {
      // Only show tutorials if onboarding is not loading
      if (onboardingStatus == null || !onboardingStatus.hasCompletedWelcome) {
        tutorialOverlay = WelcomeTutorialOverlay(
          onNext: () => setState(() {}),
          onSkip: _handleOnboardingComplete,
        );
      } else if (!onboardingStatus.hasCompletedSidebarTutorial) {
        tutorialOverlay = SidebarTutorialOverlay(
          onOpenDrawer: _openDrawer,
          onNext: () => setState(() {}),
          onSkip: _handleOnboardingComplete,
        );
      } else if (!onboardingStatus.hasCompletedPatientProfile) {
        tutorialOverlay = PatientProfileTutorialOverlay(
          onNext: () {
            _navigateToProfile();
            _handleOnboardingComplete();
          },
          onSkip: _handleOnboardingComplete,
        );
      }
    }

    return Stack(
      children: [
        Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(
            title: Text(
              '${getGreeting()}!',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            iconTheme: const IconThemeData(size: 36, color: Colors.black),
          ),
          drawer: const DrawerMenu(),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : therapyOutlines.isEmpty || memories.isEmpty
                  ? _buildEmptyView()
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Image.asset(
                              'assets/images/home.jpg',
                              fit: BoxFit.cover,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'Reminiscence Therapies',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          ...therapyOutlines.map((therapyOutline) {
                            final memory = memories.firstWhere(
                              (m) => m.id == therapyOutline.memoryId,
                              orElse: () => Memory(
                                  patientId: '',
                                  title: '',
                                  description: '',
                                  date: '',
                                  media: []),
                            );
                            return _buildTherapyCard(therapyOutline, memory);
                          }),
                        ],
                      ),
                    ),
        ),
        if (tutorialOverlay != null) tutorialOverlay,
      ],
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            'No therapies generated yet.',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildTherapyCard(TherapyOutline therapyOutline, Memory memory) {
    return Card(
      elevation: 5,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              memory.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              memory.description ?? 'No description',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/play-therapy', arguments: {
                    'therapyOutline': therapyOutline,
                    'memory': memory,
                  });
                },
                child: const Text('Start Therapy'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
