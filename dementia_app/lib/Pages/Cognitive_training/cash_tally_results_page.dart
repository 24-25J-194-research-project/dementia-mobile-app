import 'package:flutter/material.dart';
import '../../Models/Cognitive_Training/cash_tally_models.dart';

class CashTallyResultsPage extends StatelessWidget {
  final List<CashTallyQuestion> questions;
  final List<int?> userAnswers;
  final int score;
  final VoidCallback onTryAgain;

  const CashTallyResultsPage({
    super.key,
    required this.questions,
    required this.userAnswers,
    required this.score,
    required this.onTryAgain,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Results'),
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[100]!, Colors.blue[50]!],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Score summary card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      'Results',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Your Score: $score out of ${questions.length} (${(score/questions.length) * 100}%)',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: onTryAgain,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      ),
                      child: const Text('Try Again', style: TextStyle(fontSize: 18)),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Each question review
            ...List.generate(questions.length, (index) {
              return _buildQuestionReviewCard(index);
            }),
          ],
        ),
      ),
    );
  }
  
  Widget _buildQuestionReviewCard(int questionIndex) {
    final question = questions[questionIndex];
    final userAnswer = userAnswers[questionIndex];
    final isCorrect = userAnswer == question.correctChoiceIndex;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question header
          Container(
            padding: const EdgeInsets.all(12),
            color: isCorrect ? Colors.green[50] : Colors.red[50],
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCorrect ? Colors.green : Colors.red,
                  ),
                  child: Icon(
                    isCorrect ? Icons.check : Icons.close,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Question ${questionIndex + 1}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isCorrect ? Colors.green[800] : Colors.red[800],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Question content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Grocery items
                ...question.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    '• ${item.name} × ${item.quantity} - Price per each Rs.${item.pricePerUnit.toInt()}',
                    style: const TextStyle(fontSize: 16),
                  ),
                )),
                
                const SizedBox(height: 16),
                
                const Text(
                  'Correct total amount:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Rs.${question.correctTotal.toInt()}',
                  style: const TextStyle(fontSize: 16),
                ),
                
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                
                // Each answer choice
                ...List.generate(question.choices.length, (choiceIndex) {
                  final isUserChoice = userAnswer == choiceIndex;
                  final isCorrectChoice = question.correctChoiceIndex == choiceIndex;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isCorrectChoice 
                            ? Colors.green 
                            : (isUserChoice ? Colors.red : Colors.grey.shade300),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: isUserChoice
                          ? (isCorrectChoice ? Colors.green[50] : Colors.red[50])
                          : (isCorrectChoice ? Colors.green[50] : null),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Choice header
                          Row(
                            children: [
                              Text(
                                '${choiceIndex + 1}) ',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              if (isUserChoice && !isCorrectChoice)
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.red,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              if (isCorrectChoice)
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.green,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          
                          // Money notes explicitly arranged in pairs
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (int i = 0; i < question.choices[choiceIndex].notes.length; i += 2)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Row(
                                    children: [
                                      // First note in pair
                                      Expanded(
                                        child: Column(
                                          children: [
                                            Image.asset(
                                              question.choices[choiceIndex].notes[i].imagePath,
                                              height: 40,
                                            ),
                                            Text('Rs.${question.choices[choiceIndex].notes[i].value.toInt()}'),
                                          ],
                                        ),
                                      ),
                                      // Second note in pair (if exists)
                                      if (i + 1 < question.choices[choiceIndex].notes.length)
                                        Expanded(
                                          child: Column(
                                            children: [
                                              Image.asset(
                                                question.choices[choiceIndex].notes[i + 1].imagePath,
                                                height: 40,
                                              ),
                                              Text('Rs.${question.choices[choiceIndex].notes[i + 1].value.toInt()}'),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          
                          const SizedBox(height: 4),
                          Text(
                            'Total: Rs.${question.choices[choiceIndex].total.toInt()}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}