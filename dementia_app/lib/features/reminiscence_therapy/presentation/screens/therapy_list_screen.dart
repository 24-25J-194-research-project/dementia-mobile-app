import 'package:flutter/material.dart';

import '../../../auth/presentation/providers/auth_service.dart';
import '../../../memories/data/repositories/memory_repository_impl.dart';
import '../../../memories/domain/entities/memory_model.dart';
import '../../../memories/domain/use_cases/memory_use_case.dart';
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
    return Scaffold(
      appBar: AppBar(title: const Text('Reminiscence Therapies')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : therapyOutlines.isEmpty || memories.isEmpty
              ? _buildEmptyView()
              : SingleChildScrollView(
                  child: Column(
                    children: therapyOutlines.map((therapyOutline) {
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
                    }).toList(),
                  ),
                ),
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
            const SizedBox(height: 12),
            Text(
              'Status: ${therapyOutline.status}',
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
