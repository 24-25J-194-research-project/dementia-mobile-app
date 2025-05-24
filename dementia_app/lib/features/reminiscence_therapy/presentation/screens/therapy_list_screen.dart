import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:provider/provider.dart';

import '../../../auth/presentation/providers/auth_service.dart';
import '../../../memories/data/repositories/memory_repository_impl.dart';
import '../../../memories/domain/entities/memory_model.dart';
import '../../../memories/domain/use_cases/memory_use_case.dart';
import '../../../onboarding/presentation/providers/onboarding_provider.dart';
import '../../../onboarding/presentation/widgets/therapy_tutorial_overlay.dart';
import '../../data/repositories/therapy_outline_repository_impl.dart';
import '../../domain/entities/therapy_outline.dart';
import '../../domain/use_cases/therapy_outline_use_case.dart';

class ReminiscenceTherapiesScreen extends StatefulWidget {
  const ReminiscenceTherapiesScreen({super.key});

  @override
  ReminiscenceTherapiesScreenState createState() =>
      ReminiscenceTherapiesScreenState();
}

class ReminiscenceTherapiesScreenState
    extends State<ReminiscenceTherapiesScreen> {
  bool isLoading = true;
  String? patientId;
  List<TherapyOutline> therapyOutlines = [];
  List<Memory> memories = [];

  final TherapyOutlineUseCase _therapyOutlineUseCase = TherapyOutlineUseCase(
    TherapyOutlineRepositoryImpl(),
  );
  final MemoryUseCase _memoryUseCase = MemoryUseCase(MemoryRepository());

  @override
  void initState() {
    super.initState();
    _loadTherapyOutlines();
  }

  Future<void> _loadTherapyOutlines() async {
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

  @override
  Widget build(BuildContext context) {
    final onboardingProvider = Provider.of<OnboardingProvider>(context);
    final onboardingStatus = onboardingProvider.onboardingStatus;
    final bool showTutorial = onboardingStatus != null &&
        onboardingStatus.isPhaseOneComplete &&
        !onboardingStatus.hasCompletedTherapyTutorial;

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Reminiscence Therapies'),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
          ),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : therapyOutlines.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      itemCount: therapyOutlines.length,
                      itemBuilder: (context, index) {
                        final therapyOutline = therapyOutlines[index];
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
                      },
                    ),
        ),
        if (showTutorial)
          TherapyTutorialOverlay(
            onComplete: () => setState(() {}),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
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
    // Collect all unique media URLs from therapy steps using a Set
    Set<String> uniqueMediaUrls = {};
    if (therapyOutline.steps != null) {
      for (var step in therapyOutline.steps!) {
        uniqueMediaUrls.addAll(step.mediaUrls);
      }
    }
    final List<String> allMediaUrls = uniqueMediaUrls.toList();

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
            if (allMediaUrls.isNotEmpty) ...[
              CarouselSlider(
                options: CarouselOptions(
                  height: 200.0,
                  aspectRatio: 16/9,
                  viewportFraction: 0.8,
                  enableInfiniteScroll: false,
                  autoPlay: false,
                  enlargeCenterPage: true,
                ),
                items: allMediaUrls.map((url) {
                  return Builder(
                    builder: (BuildContext context) {
                      return Container(
                        width: MediaQuery.of(context).size.width,
                        margin: const EdgeInsets.symmetric(horizontal: 5.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.network(
                            url,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                  size: 32,
                                ),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
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
