import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dementia_app/features/memories/domain/entities/memory_model.dart';
import 'package:dementia_app/features/reminiscence_therapy/domain/entities/therapy_outline.dart';
import '../../../../core/network/memory_vault_api_client.dart';
import '../../../auth/presentation/providers/auth_service.dart';
import '../../../onboarding/presentation/providers/onboarding_provider.dart';
import '../../../onboarding/presentation/widgets/memories_tutorial_overlay.dart';
import '../../../reminiscence_therapy/data/repositories/therapy_outline_repository_impl.dart';
import '../../../reminiscence_therapy/domain/use_cases/therapy_outline_use_case.dart';
import '../../data/repositories/memory_repository_impl.dart';
import '../../domain/use_cases/memory_use_case.dart';
import 'add_memory_screen.dart';
import 'memory_detail_screen.dart';

class MemoryScreen extends StatefulWidget {
  const MemoryScreen({super.key});

  @override
  MemoryScreenState createState() => MemoryScreenState();
}

class MemoryScreenState extends State<MemoryScreen> {
  late List<Memory> memories;
  bool isLoading = true;
  String? patientId;

  final MemoryUseCase _memoryUseCase = MemoryUseCase(MemoryRepository());
  final TherapyOutlineUseCase _therapyOutlineUseCase =
      TherapyOutlineUseCase(TherapyOutlineRepositoryImpl());

  @override
  void initState() {
    super.initState();
    _loadMemories();
  }

  Future<void> _loadMemories() async {
    try {
      final user = await AuthService().getCurrentUser();

      if (user != null) {
        patientId = user.uid;
        memories = await _memoryUseCase.getMemories(patientId!);

        setState(() {
          isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('User not logged in')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error loading memories')));
    }
  }

  void _addMemory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddMemoryScreen(patientId: patientId!),
      ),
    ).then((_) {
      _loadMemories();
    });
  }

  Widget _buildMemoryCard(Memory memory) {
    return Card(
      elevation: 5,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              memory.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // Description
            Text(
              memory.description ?? 'No description',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),

            // Notification alert (Based on therapy outline status)
            FutureBuilder<List<TherapyOutline>>(
              future:
                  _therapyOutlineUseCase.fetchAllTherapyOutlines(patientId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return const Text("Error fetching therapy outlines");
                }

                List<TherapyOutline> therapyOutlines = snapshot.data ?? [];
                TherapyOutline outline = therapyOutlines.firstWhere(
                  (e) => e.memoryId == memory.id,
                  orElse: () => TherapyOutline(
                      memoryId: '',
                      status: 'not processed',
                      id: '',
                      patientId: ''),
                );

                if (outline.status == 'not processed') {
                  return _buildStatus("Not processed yet.", Icons.pending,
                      "Process Now", memory.id!);
                } else if (outline.status == 'completed') {
                  return _buildStatus("This memory is successfully processed.",
                      Icons.check_circle, "View Therapies", memory.id!);
                } else if (outline.status == 'processing' ||
                    outline.status == 'pending') {
                  return _buildStatus("Memory is being processed...",
                      Icons.autorenew, "Wait", memory.id!);
                } else if (outline.status == 'failed') {
                  return _buildStatus("Memory processing failed. Please retry.",
                      Icons.error, "Retry", memory.id!);
                } else {
                  return _buildStatus("Memory is being processed...",
                      Icons.autorenew, "Wait", memory.id!);
                }
              },
            ),
            const SizedBox(height: 8),

            Text(
              'Categories: ${_getFormattedCategories(memory.categories)}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),

            Text(
              'Emotions: ${_getFormattedEmotions(memory.emotions)}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),

            Text(
              'Tags: ${_getFormattedTags(memory.tags)}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),

            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Delete Memory'),
                            content: const Text(
                                'Are you sure you want to delete this memory? This action cannot be undone.'),
                            actions: [
                              TextButton(
                                child: const Text('Cancel'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                              TextButton(
                                child: const Text('Delete',
                                    style: TextStyle(color: Colors.red)),
                                onPressed: () async {
                                  try {
                                    await _memoryUseCase
                                        .deleteMemory(memory.id!);
                                    Navigator.of(context).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Memory deleted successfully')),
                                    );
                                    _loadMemories();
                                  } catch (e) {
                                    Navigator.of(context).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'Error deleting memory: $e')),
                                    );
                                  }
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              MemoryDetailScreen(memory: memory),
                        ),
                      ).then((_) {
                        _loadMemories();
                      });
                    },
                    child: const Text('Edit'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getFormattedCategories(List<MemoryCategory>? categories) {
    if (categories == null) {
      return 'Not processed yet';
    }
    if (categories.isEmpty) {
      return 'No categories';
    }

    return categories
        .map((category) =>
            category.toString().replaceFirst('MemoryCategory.', ''))
        .map((category) => category[0].toUpperCase() + category.substring(1))
        .join(', ');
  }

  String _getFormattedEmotions(List<MemoryEmotion>? emotions) {
    if (emotions == null) {
      return 'Not processed yet';
    }
    if (emotions.isEmpty) {
      return 'No emotions';
    }

    return emotions
        .map((emotion) => emotion.toString().replaceFirst('MemoryEmotion.', ''))
        .map((emotion) => emotion[0].toUpperCase() + emotion.substring(1))
        .join(', ');
  }

  String _getFormattedTags(List<String>? tags) {
    if (tags == null) {
      return 'Not processed yet';
    }
    if (tags.isEmpty) {
      return 'No tags';
    }

    List<String> formattedTags = tags.map((tag) {
      return tag.split(' ').toSet().join(' ');
    }).toList();

    return formattedTags
        .toSet()
        .map((tag) => tag[0].toUpperCase() + tag.substring(1))
        .join(', ');
  }

  Widget _buildStatus(
      String message, IconData icon, String buttonText, String memoryId) {
    Color alertColor;
    if (icon == Icons.check_circle) {
      alertColor = Colors.green.shade100;
    } else if (icon == Icons.error) {
      alertColor = Colors.red.shade100;
    } else if (icon == Icons.autorenew) {
      alertColor = Colors.orange.shade100;
    } else {
      alertColor = Colors.blue.shade100;
    }

    void processMemory() {
      final apiClient = MemoryVaultApiClient();

      apiClient.post('/therapy/process/$memoryId').then((response) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Successfully started processing the memory!')),
        );
        _loadMemories();
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
      });
    }

    void viewTherapy() {
      Navigator.pushNamed(context, '/reminiscence-therapies');
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: alertColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: icon == Icons.check_circle
              ? Colors.green
              : icon == Icons.error
                  ? Colors.red
                  : icon == Icons.autorenew
                      ? Colors.orange
                      : Colors.blue,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: icon == Icons.check_circle
                ? Colors.green
                : icon == Icons.error
                    ? Colors.red
                    : icon == Icons.autorenew
                        ? Colors.orange
                        : Colors.blue,
          ),
          const SizedBox(width: 10),
          // Allow the text to take full width and wrap if needed
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 14),
              softWrap:
                  true, // Allow wrapping the text to the next line if needed
              overflow: TextOverflow
                  .visible, // Make sure the text doesn't get truncated
            ),
          ),
          if (buttonText != "Wait")
            TextButton(
              onPressed: () {
                if (buttonText == "Process Now") {
                  processMemory();
                } else if (buttonText == "View Therapies") {
                  viewTherapy();
                } else if (buttonText == "Retry") {
                  processMemory();
                }
              },
              child: Text(buttonText),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_album_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            'No memories yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add your first memory by tapping the + button',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final onboardingProvider = Provider.of<OnboardingProvider>(context);
    final onboardingStatus = onboardingProvider.onboardingStatus;
    final bool showTutorial = onboardingStatus != null &&
        onboardingStatus.isPhaseOneComplete &&
        !onboardingStatus.hasCompletedMemoriesTutorial;

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Memories'),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
          ),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : memories.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      itemCount: memories.length,
                      itemBuilder: (context, index) {
                        return _buildMemoryCard(memories[index]);
                      },
                    ),
          floatingActionButton: FloatingActionButton(
            onPressed: _addMemory,
            child: const Icon(Icons.add),
          ),
        ),
        if (showTutorial)
          MemoriesTutorialOverlay(
            onComplete: () => setState(() {}),
          ),
      ],
    );
  }
}
