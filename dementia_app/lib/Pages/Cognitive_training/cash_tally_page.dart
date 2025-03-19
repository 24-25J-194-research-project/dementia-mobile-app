import 'package:dementia_app/Pages/Cognitive_training/cash_tally_results_page.dart';
import 'package:dementia_app/Shared/constants.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../Components/user_avatar.dart';
import '../../Models/Cognitive_Training/cash_tally_models.dart';
import '../../Data/Cognitive_Training/cash_tally_easy_questions.dart';
import '../../Data/Cognitive_Training/cash_tally_medium_questions.dart';
import '../../Data/Cognitive_Training/cash_tally_hard_questions.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;

enum DifficultyLevel {
  easy,
  medium,
  hard
}
final String baseUrl = Constants.baseAPIUrl;

class CashTallyPage extends StatefulWidget {
  const CashTallyPage({super.key});

  @override
  State<CashTallyPage> createState() => _CashTallyPageState();
}

class _CashTallyPageState extends State<CashTallyPage> {
  //state variables
  int currentQuestionIndex = 0;
  late List<int?> userAnswers;
  late List<CashTallyQuestion> questions;
  final int numberOfQuestionsToShow = 5;
  DifficultyLevel currentDifficulty = DifficultyLevel.easy;
  bool quizCompleted = false;
  
  //get Supabase instance
  final supabase = Supabase.instance.client;
  
  @override
  void initState() {
    super.initState();
    //load questions for initial difficulty
    loadQuestions();
  }
  
  //load questions based on current difficulty
  void loadQuestions() {
    List<CashTallyQuestion> allQuestions;
    
    //get questions from appropriate source based on difficulty
    switch (currentDifficulty) {
      case DifficultyLevel.easy:
        allQuestions = CashTallyDataEasy.getEasyQuestions();
        break;
      case DifficultyLevel.medium:
        allQuestions = CashTallyDataMedium.getMediumQuestions();
        break;
      case DifficultyLevel.hard:
        allQuestions = CashTallyDataHard.getHardQuestions();
        break;
    }
    
    //shuffle and select random questions
    if (allQuestions.length <= numberOfQuestionsToShow) {
      //if we have 5 or fewer questions, use all of them
      questions = allQuestions;
    } else {
      //shuffle the questions randomly
      allQuestions.shuffle(Random());
      //take only the first 5 questions
      questions = allQuestions.sublist(0, numberOfQuestionsToShow);
    }
    
    // Initialize answer array based on selected questions
    userAnswers = List.filled(questions.length, null);
    currentQuestionIndex = 0;
    quizCompleted = false;
  }
  
  // Change difficulty level
  void changeDifficulty(DifficultyLevel newDifficulty) {
    if (newDifficulty != currentDifficulty) {
      setState(() {
        currentDifficulty = newDifficulty;
        loadQuestions();
      });
    }
  }
  
  //calculate score
  int get score {
    int count = 0;
    for (int i = 0; i < questions.length; i++) {
      if (userAnswers[i] == questions[i].correctChoiceIndex) {
        count++;
      }
    }
    return count;
  }
  
  // Calculate error count
  int get errorCount {
    int count = 0;
    for (int i = 0; i < questions.length; i++) {
      if (userAnswers[i] != null && userAnswers[i] != questions[i].correctChoiceIndex) {
        count++;
      }
    }
    return count;
  }
  
  // Get difficulty level as string
  String get difficultyString {
    switch (currentDifficulty) {
      case DifficultyLevel.easy:
        return "easy";
      case DifficultyLevel.medium:
        return "medium";
      case DifficultyLevel.hard:
        return "hard";
    }
  }
  
  Future<void> sendResultsToAPI() async {
    // Store the context and scaffoldMessenger before any async operation
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    try {
      // Get current user ID from Supabase
      final User? currentUser = supabase.auth.currentUser;
      
      if (currentUser == null) {
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('You need to be logged in to save results'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      // Calculate score percentage (without accessing widget state in async gap)
      final int totalQuestions = questions.length;
      final int correctAnswers = score;
      final int incorrectAnswers = errorCount;
      
      final double scorePercentage = (correctAnswers / totalQuestions) * 100;
      final double errorPercentage = (incorrectAnswers / totalQuestions) * 100;
      
      final String difficulty = difficultyString;
      
      // Prepare data for API
      final Map<String, dynamic> data = {
        "user_id": currentUser.id,
        "cognitive_training_id": 1, // ID for Cash Tally activity
        "level": difficulty,
        "score": scorePercentage.round(),
        "error_count": errorPercentage.round()
      };
      
      // Make API request without showing dialog
      final response = await http.post(
        Uri.parse('$baseUrl/api/cognitive-training-history'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      );
      
      // Only access UI if widget is still mounted
      if (mounted) {
        if (response.statusCode == 201 || response.statusCode == 200) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Results saved successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // Format user-friendly error message
          String errorMessage = 'Failed to save results';
          try {
            final errorBody = jsonDecode(response.body);
            if (errorBody['message'] != null) {
              errorMessage = errorBody['message'];
            }
          } catch (e) {
            // If parsing fails, use generic message
          }
          
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
      
      // Log regardless of mounted state
      if (kDebugMode) {
        debugPrint("API Response: ${response.statusCode} - ${response.body}");
      }
      
    } catch (e) {
      // Only show error if widget is still mounted
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Connection error. Please check your internet and try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      
      if (kDebugMode) {
        debugPrint("Error sending results to API: $e");
      }
    }
  }

  // Show a loading dialog with a key for easier dismissal
  void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Text(message),
            ],
          ),
        );
      },
    );
  }

  // Show an error message
  void _showErrorMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  // Show a success message
  void _showSuccessMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }
  
  // Handle answer selection
  void selectAnswer(int choiceIndex) {
    setState(() {
      userAnswers[currentQuestionIndex] = choiceIndex;
    });
  }
  
  // Navigate to next question
  void goToNextQuestion() {
    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
      });
    } else if (userAnswers[currentQuestionIndex] != null) {
      // On last question and answered, navigate to results page
      navigateToResults();
    }
  }
  
  // Navigate to previous question
  void goToPreviousQuestion() {
    if (currentQuestionIndex > 0) {
      setState(() {
        currentQuestionIndex--;
      });
    }
  }
  
  //navigate to results page
  void navigateToResults() {
    //mark the quiz as completed
    setState(() {
      quizCompleted = true;
    });
    
    //navigate to results page first
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CashTallyResultsPage(
          questions: questions,
          userAnswers: userAnswers,
          score: score,
          onTryAgain: resetQuiz,
        ),
      ),
    );
    
    //send results to API
    sendResultsToAPI();
  }
  
  //reset the quiz
  void resetQuiz() {
    setState(() {
      loadQuestions();
    });
    
    //if on results page, pop back to questions
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cash Tally'),
        centerTitle: true,
        backgroundColor: Colors.white,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: UserAvatar(),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[100]!, Colors.blue[50]!],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildQuestionScreen(),
        ),
      ),
    );
  }
  
  Widget _buildQuestionScreen() {
    final question = questions[currentQuestionIndex];
    final currentAnswer = userAnswers[currentQuestionIndex];
    final isLastQuestion = currentQuestionIndex == questions.length - 1;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Combined progress and difficulty indicator
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Difficulty dropdown
                Row(
                  children: [
                    const Text(
                      'Difficulty: ',
                      style: TextStyle(fontSize: 14),
                    ),
                    DropdownButton<DifficultyLevel>(
                      dropdownColor: Colors.white,
                      borderRadius: BorderRadius.circular(16), 
                      itemHeight: 50,
                      style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                      ),
                      value: currentDifficulty,
                      onChanged: (DifficultyLevel? newValue) {
                        if (newValue != null) {
                          changeDifficulty(newValue);
                        }
                      },
                      items: const [
                        DropdownMenuItem(
                          value: DifficultyLevel.easy,
                          child: Text('2 items'),
                        ),
                        DropdownMenuItem(
                          value: DifficultyLevel.medium,
                          child: Text('3 items'),
                        ),
                        DropdownMenuItem(
                          value: DifficultyLevel.hard,
                          child: Text('4 items'),
                        ),
                      ],
                    ),
                  ],
                ),

                // Progress text
                Text(
                  'Question ${currentQuestionIndex + 1} / ${questions.length}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        //items list
        Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...question.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    '• ${item.name} × ${item.quantity} - Price per each Rs.${item.pricePerUnit.toInt()}',
                    style: const TextStyle(fontSize: 16),
                  ),
                )),
                const SizedBox(height: 16),
                const Text(
                  'What is the correct total amount?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        //choices
        Expanded(
          child: ListView.builder(
            itemCount: question.choices.length,
            itemBuilder: (context, index) {
              final isSelected = currentAnswer == index;
              return GestureDetector(
                onTap: () => selectAnswer(index),
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 3,
                  color: isSelected ? Colors.blue[100] : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: isSelected ? Colors.blue : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${index + 1}) ',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Money notes explicitly arranged in pairs
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (int i = 0; i < question.choices[index].notes.length; i += 2)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Row(
                                  children: [
                                    // First note in pair
                                    Expanded(
                                      child: Column(
                                        children: [
                                          Image.asset(
                                            question.choices[index].notes[i].imagePath,
                                            height: 60,
                                          ),
                                          Text('Rs.${question.choices[index].notes[i].value.toInt()}'),
                                        ],
                                      ),
                                    ),
                                    // Second note in pair (if exists)
                                    if (i + 1 < question.choices[index].notes.length)
                                      Expanded(
                                        child: Column(
                                          children: [
                                            Image.asset(
                                              question.choices[index].notes[i + 1].imagePath,
                                              height: 60,
                                            ),
                                            Text('Rs.${question.choices[index].notes[i + 1].value.toInt()}'),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        
        //navigation buttons
        Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Previous button
              ElevatedButton.icon(
                onPressed: currentQuestionIndex > 0 ? goToPreviousQuestion : null,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Previous'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  backgroundColor: Colors.grey[300],
                  foregroundColor: Colors.black,
                ),
              ),
              
              //next/finish button
              ElevatedButton.icon(
                onPressed: currentAnswer != null 
                    ? isLastQuestion ? navigateToResults : goToNextQuestion 
                    : null,
                icon: Icon(isLastQuestion ? Icons.check : Icons.arrow_forward),
                label: Text(isLastQuestion ? 'Finish' : 'Next'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}