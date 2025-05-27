import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import '../../Models/Cognitive_Training/cash_tally_models.dart';
import '../../Data/Cognitive_Training/cash_tally_easy_questions.dart';
import '../../Data/Cognitive_Training/cash_tally_medium_questions.dart';
import '../../Data/Cognitive_Training/cash_tally_hard_questions.dart';
import '../../API/cash_tally_openAI_api.dart';
import '../../Shared/constants.dart';
import 'dart:math';

class CashTallyQuestionGenerator {
  final CashTallyOpenAIAPI? openAIService;
  
  // Define money notes
  static final List<MoneyNote> availableNotes = [
    const MoneyNote(value: 10, imagePath: 'assets/cash_tally/10_note.jpg'),
    const MoneyNote(value: 20, imagePath: 'assets/cash_tally/20_note.jpg'),
    const MoneyNote(value: 50, imagePath: 'assets/cash_tally/50_note.jpg'),
    const MoneyNote(value: 100, imagePath: 'assets/cash_tally/100_note.jpg'),
    const MoneyNote(value: 500, imagePath: 'assets/cash_tally/500_note.jpg'),
    const MoneyNote(value: 1000, imagePath: 'assets/cash_tally/1000_note.jpg')
  ];
  
  CashTallyQuestionGenerator({this.openAIService});
  
  //get allowed quantities for each difficulty level
  List<int> _getAllowedQuantities(DifficultyLevel difficulty) {
    switch (difficulty) {
      case DifficultyLevel.easy:
        return [1, 2];
      case DifficultyLevel.medium:
        return [1, 2]; 
      case DifficultyLevel.hard:
        return [1, 3];
    }
  }
  
  Future<List<CashTallyQuestion>> getQuestions({
    required DifficultyLevel difficulty,
    required int numberOfQuestions,
    bool useAI = true,
  }) async {
    //if OpenAI is disabled or no openAIService is provided, use predefined questions
    if (!useAI || openAIService == null) {
      return _getPredefinedQuestions(difficulty, numberOfQuestions);
    }
    
    try {
      //try to generate questions using OpenAI
      final questions = await openAIService!.generateCashTallyQuestions(
        numberOfQuestions: numberOfQuestions,
        difficulty: difficulty,
        availableNotes: availableNotes,
      );
      
      //validate questions with quantity constraints
      if (_validateQuestions(questions, difficulty)) {
        return questions;
      } else {
        if (kDebugMode) {
          debugPrint('Generated questions failed validation, using predefined questions');
        }
        return _getPredefinedQuestions(difficulty, numberOfQuestions);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error generating questions with AI: $e');
        debugPrint('Falling back to predefined questions');
      }
      
      //on error, fall back to predefined questions
      return _getPredefinedQuestions(difficulty, numberOfQuestions);
    }
  }
  
  List<CashTallyQuestion> _getPredefinedQuestions(DifficultyLevel difficulty, int count) {
    List<CashTallyQuestion> allQuestions;
    
    //get questions from appropriate source based on difficulty
    switch (difficulty) {
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
    if (allQuestions.length <= count) {
      //if we have fewer questions than requested, use all of them
      return allQuestions;
    } else {
      //shuffle the questions randomly
      allQuestions.shuffle(Random());
      //take only the first n questions
      return allQuestions.sublist(0, count);
    }
  }
  
  //validate that the generated questions and follow quantity constraints
  bool _validateQuestions(List<CashTallyQuestion> questions, DifficultyLevel difficulty) {
    if (questions.isEmpty) {
      if (kDebugMode) debugPrint('❌ Validation failed: No questions generated');
      return false;
    }
    
    //get allowed quantities for this difficulty level
    final allowedQuantities = _getAllowedQuantities(difficulty);
    
    //track validation results for debugging
    int validCount = 0;
    int invalidCount = 0;
    List<String> errors = [];
    
    for (int i = 0; i < questions.length; i++) {
      final question = questions[i];
      bool isValid = true;
      
      //check that we have items
      if (question.items.isEmpty) {
        errors.add('Question $i: No items');
        isValid = false;
      }
      
      //check that we have choices
      if (question.choices.isEmpty) {
        errors.add('Question $i: No choices');
        isValid = false;
      }
      
      //check that correctChoiceIndex is valid
      if (question.correctChoiceIndex < 0 || question.correctChoiceIndex >= question.choices.length) {
        errors.add('Question $i: Invalid correctChoiceIndex: ${question.correctChoiceIndex}');
        isValid = false;
      }
      
      //check quantity constraints for each item
      for (final item in question.items) {
        if (!allowedQuantities.contains(item.quantity)) {
          errors.add('Question $i: Item ${item.name} has invalid quantity ${item.quantity}. '
              'Allowed values: ${allowedQuantities.join(' or ')}');
          isValid = false;
        }
      }
      
      //calculate expected total
      final expectedTotal = question.items.fold(0.0, (sum, item) => sum + item.totalPrice);
      
      //verify correct choice matches expected total
      if (question.correctChoiceIndex >= 0 && question.correctChoiceIndex < question.choices.length) {
        final correctChoice = question.choices[question.correctChoiceIndex];
        final diff = (correctChoice.total - expectedTotal).abs();
        
        if (diff > 0.01) {
          errors.add('Question $i: Correct choice total (${correctChoice.total}) '
              'does not match expected total ($expectedTotal), diff: $diff');
          isValid = false;
        }
      }
      
      if (isValid) {
        validCount++;
      } else {
        invalidCount++;
      }
    }
    
    //log validation results
    if (kDebugMode) {
      debugPrint('🔍 Validation results: $validCount valid, $invalidCount invalid');
      
      if (errors.isNotEmpty) {
        debugPrint('❌ Validation errors:');
        for (final error in errors) {
          debugPrint('  - $error');
        }
      }
    }
    
    //all questions must be valid
    return invalidCount == 0 && validCount > 0;
  }
}