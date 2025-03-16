import 'package:flutter/material.dart';
import 'package:dementia_app/features/auth/presentation/providers/auth_service.dart';
import '../../domain/use_cases/memory_use_case.dart';
import 'add_memory_screen.dart';
import 'memory_detail_screen.dart';
import '../../data/repositories/memory_repository_impl.dart';
import '../../domain/entities/memory_model.dart';
import 'package:dementia_app/core/logging/logger.dart';

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

  @override
  void initState() {
    super.initState();
    _loadMemories();
  }

  void _loadMemories() async {
    try {
      final user = await AuthService().getCurrentUser();

      if (user != null) {
        patientId = user.uid;
        memories = await _memoryUseCase.getMemories(patientId!);

        setState(() {
          isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User not logged in')));
      }
    } catch (e) {
      logger.e('Error loading memories: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading memories')));
    }
  }

  void _addMemory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddMemoryScreen(patientId: patientId!),
      ),
    );
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
            // Categories
            Text(
              'Categories: ${memory.categories?.join(', ') ?? 'Not processed yet'}',
              style: const TextStyle(fontSize: 14),
            ),
            // Emotions
            Text(
              'Emotions: ${memory.emotions?.join(', ') ?? 'Not processed yet'}',
              style: const TextStyle(fontSize: 14),
            ),
            // Tags
            Text(
              'Tags: ${memory.tags?.join(', ') ?? 'Not processed yet'}',
              style: const TextStyle(fontSize: 14),
            ),
            // Navigate to MemoryDetailScreen when tapped
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MemoryDetailScreen(memory: memory),
                    ),
                  );
                },
                child: const Text('Edit'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Memories')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: memories.length,
        itemBuilder: (context, index) {
          final memory = memories[index];
          return _buildMemoryCard(memory);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addMemory,
        child: const Icon(Icons.add),
      ),
    );
  }
}
