import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import '../Models/Cognitive_Training/cash_tally_models.dart';
import '../Shared/constants.dart';

enum DifficultyLevel {
  easy,
  medium,
  hard
}

class CashTallyOpenAIAPI {
  final apiKey = Constants.openAIAPIKey;
  final baseUrl = Constants.openAIBaseUrl;
  
  CashTallyOpenAIAPI({required apiKey});
  
  Future<List<CashTallyQuestion>> generateCashTallyQuestions({
    int numberOfQuestions = 5,
    required DifficultyLevel difficulty,
    required List<MoneyNote> availableNotes,
  }) async {
    try {
      //define number of items based on difficulty
      int itemsPerQuestion;
      int paymentOptionsCount;
      List<int> allowedQuantities;

      switch (difficulty) {
        case DifficultyLevel.easy:
          itemsPerQuestion = 2;
          paymentOptionsCount = 3;
          allowedQuantities = [1, 2];
          break;
        case DifficultyLevel.medium:
          itemsPerQuestion = 3;
          paymentOptionsCount = 4;
          allowedQuantities = [1, 2];
          break;
        case DifficultyLevel.hard:
          itemsPerQuestion = 4;
          paymentOptionsCount = 5;
          allowedQuantities = [1, 3];
          break;
      }
      
      //create prompt with improved math guidance
      final systemPrompt = """
        You are a math education assistant that creates shopping calculation exercises. 
        Use **ONLY** these Sri Lankan Rupee notes:
          [10, 20, 50, 100, 500, 1000]

        Create exactly $numberOfQuestions shopping scenarios where people calculate total cost and pay with money notes.

        IMPORTANT MATH STEPS TO FOLLOW:
        1. Include exactly $itemsPerQuestion grocery items with name, quantity, and price per unit
        2. Quantity must be ONLY ${allowedQuantities.join(' or ')} (no other values allowed)
        3. Calculate EACH item's total cost (quantity × pricePerUnit)
        4. Sum these individual totals to get the EXACT total cost for all items
        5. Double-check your math calculation!
        6. Generate EXACTLY $paymentOptionsCount payment options (no more, no less)
        7. Each option must use ONLY notes from [10,20,50,100,500,1000], with at most 5 notes
        8. Ensure exactly ONE payment option equals the EXACT total cost
        9. For each option, verify the sum of notes matches what you intended

        For example with quantities ${allowedQuantities.join(' or ')}:
        - Rice: ${allowedQuantities.last} × 80 = ${allowedQuantities.last * 80}
        - Sugar: ${allowedQuantities.first} × 50 = ${allowedQuantities.first * 50}
        Total: ${allowedQuantities.last * 80} + ${allowedQuantities.first * 50} = ${allowedQuantities.last * 80 + allowedQuantities.first * 50}

        Correct payment: [100, 100, 100, 10] = ${allowedQuantities.last * 80 + allowedQuantities.first * 50}
        Incorrect options: [500] = 500, [100, 100, 50] = 250

        Output in this exact JSON format:
        {
          "questions": [
            {
              "items": [
                {"name": "item name", "quantity": number, "pricePerUnit": number},
                ...
              ],
              "expectedTotal": number,
              "choices": [
                {"notes": [10, 20, 50, ...], "total": number, "isCorrect": true/false},
                ...
              ]
            },
            ...
          ]
        }

        Before returning, verify:
        1. Each question has EXACTLY $itemsPerQuestion items
        2. Each item quantity is EXACTLY ${allowedQuantities.join(' or ')} (no other values)
        3. Each question has EXACTLY $paymentOptionsCount payment options
        4. The math is correct for ALL calculations
        5. One and only one payment option matches the exact total
        6. Make sure to generate exactly $numberOfQuestions questions
        """;

      //create messages payload
      final messages = [
        {"role": "system", "content": systemPrompt},
        {"role": "user", "content": "Generate exactly $numberOfQuestions ${difficulty.toString().split('.').last} cash tally questions with $itemsPerQuestion items each. Double-check all math calculations."}
      ];
      
      //create request body
      final body = jsonEncode({
        "model": "gpt-4.1-mini-2025-04-14",
        "messages": messages,
        "temperature": 0.0,
        "max_tokens": 3000,
      });
      
      //the API request
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: body,
      );
      
      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        final content = responseBody['choices'][0]['message']['content'];
        
        //extract JSON from response
        final jsonContent = _extractJsonFromString(content);
        final parsed = jsonDecode(jsonContent);
        if (kDebugMode) {
          debugPrint('🔍 [AI RAW JSON] $jsonContent');
        }
        
        //convert JSON to CashTallyQuestion objects
        final List<CashTallyQuestion> questions = [];
        
        for (var questionData in parsed['questions']) {
          //parse items
          final items = <GroceryItem>[];
          for (var itemData in questionData['items']) {
            items.add(GroceryItem(
              name: itemData['name'],
              quantity: (itemData['quantity'] is double)
                  ? (itemData['quantity'] as double).toInt()
                  : itemData['quantity'],
              pricePerUnit: (itemData['pricePerUnit'] is int) 
                  ? itemData['pricePerUnit'].toDouble() 
                  : itemData['pricePerUnit'],
            ));
          }
          
          //calculate the expected total from items
          final calculatedTotal = items.fold(
              0.0, (sum, item) => sum + (item.quantity * item.pricePerUnit));
          
          //log the calculated total vs what GPT provided - only on debug mode
          if (kDebugMode && questionData.containsKey('expectedTotal')) {
            final gpTotal = questionData['expectedTotal'] is int
                ? questionData['expectedTotal'].toDouble()
                : questionData['expectedTotal'];
            debugPrint('🧮 Total: ${calculatedTotal.toStringAsFixed(2)} (calculated) vs '
                '${gpTotal.toStringAsFixed(2)} (GPT)');
          }
          
          //parse choices
          var choices = <CashTallyChoice>[];
          int correctIndex = -1;
          
          for (int i = 0; i < questionData['choices'].length; i++) {
            final choiceData = questionData['choices'][i];
            
            //convert note values to MoneyNote objects
            final notes = <MoneyNote>[];
            for (var noteValue in choiceData['notes']) {
              //find the matching MoneyNote for this value
              final noteObj = availableNotes.firstWhere(
                (note) => note.value == (noteValue is int ? noteValue.toDouble() : noteValue),
                orElse: () => availableNotes.first //fallback if note not found
              );
              notes.add(noteObj);
            }
            
            choices.add(CashTallyChoice(notes: notes));
            
            //check if this is marked as correct by GPT
            if (choiceData['isCorrect'] == true) {
              //verify if GPT's marked choice actually matches the calculated total
              if ((choices[i].total - calculatedTotal).abs() < 0.01) {
                correctIndex = i;
              } else if (kDebugMode) {
                debugPrint('⚠️ GPT marked choice $i as correct but total doesn\'t match: '
                    '${choices[i].total} ≠ $calculatedTotal');
              }
            }
          }
          
          //if GPT model do not mark any choice correctly, find the best match
          if (correctIndex == -1) {
            //try to find an exact match
            for (int i = 0; i < choices.length; i++) {
              if ((choices[i].total - calculatedTotal).abs() < 0.01) {
                correctIndex = i;
                if (kDebugMode) {
                  debugPrint('✅ Found exact match at index $i: ${choices[i].total}');
                }
                break;
              }
            }
            
            //no exact match found, need to create a valid option
            if (correctIndex == -1) {
              if (kDebugMode) {
                debugPrint('⚠️ No matching choice found for total $calculatedTotal');
                debugPrint('Available choices: ${choices.map((c) => c.total).join(', ')}');
              }
              
              //create a valid money combination
              final correctNotes = _createMoneyNotesCombination(
                  calculatedTotal.toInt(), availableNotes);
              
              if (correctNotes.isNotEmpty) {
                //add as a new correct choice
                choices.add(CashTallyChoice(notes: correctNotes));
                correctIndex = choices.length - 1;
                if (kDebugMode) {
                  debugPrint('🔧 Created valid choice: '
                      '${correctNotes.map((n) => n.value.toInt()).join('+')} = $calculatedTotal');
                }
              } else {
                //if we couldn't create a valid combination, skip this question
                if (kDebugMode) {
                  debugPrint('❌ Couldn\'t create valid money combination for $calculatedTotal');
                }
                continue;
              }

              if (choices.length > paymentOptionsCount) {
                //if we have too many choices, need to trim some
                //keep the correct one and remove others
                final correctChoice = choices[choices.length - 1]; 
                
                //create a new list with the required number of choices
                final trimmedChoices = <CashTallyChoice>[];
                trimmedChoices.add(correctChoice);
                
                //find the most diverse other choices to keep
                //sort remaining choices by how different they are from correct total
                final remainingChoices = List<CashTallyChoice>.from(choices)
                  ..removeAt(choices.length - 1);
                
                remainingChoices.sort((a, b) {
                  //sort by absolute difference from correct total, largest first
                  return (b.total - calculatedTotal).abs().compareTo((a.total - calculatedTotal).abs());
                });
                
                //take just enough to reach paymentOptionsCount
                final neededCount = paymentOptionsCount - 1;
                for (int i = 0; i < neededCount && i < remainingChoices.length; i++) {
                  trimmedChoices.add(remainingChoices[i]);
                }
                
                //if we still don't have enough, create some
                while (trimmedChoices.length < paymentOptionsCount) {
                  //create an incorrect choice that's different from what we have
                  final incorrectTotal = calculatedTotal + (50 * (trimmedChoices.length % 2 == 0 ? 1 : -1));
                  final incorrectNotes = _createMoneyNotesCombination(
                      incorrectTotal.toInt(), availableNotes);
                  
                  if (incorrectNotes.isNotEmpty) {
                    trimmedChoices.add(CashTallyChoice(notes: incorrectNotes));
                  } else {
                    //if we can't create a good incorrect choice, just add something simple
                    trimmedChoices.add(CashTallyChoice(notes: [_findNote(500, availableNotes)]));
                  }
                }
                
                //replace the choices and update correctIndex
                choices = trimmedChoices;
                correctIndex = 0;  //the correct one is now the first
              } else if (choices.length < paymentOptionsCount) {
                //if we don't have enough choices, need to add some
                while (choices.length < paymentOptionsCount) {
                  //create an incorrect option with a total different from the correct one
                  final incorrectTotal = calculatedTotal + (50 * (choices.length % 2 == 0 ? 1 : -1));
                  final incorrectNotes = _createMoneyNotesCombination(
                      incorrectTotal.toInt(), availableNotes);
                  
                  if (incorrectNotes.isNotEmpty) {
                    choices.add(CashTallyChoice(notes: incorrectNotes));
                  } else {
                    //if we can't create a good incorrect choice, just add something simple
                    choices.add(CashTallyChoice(notes: [_findNote(500, availableNotes)]));
                  }
                }
              }


            }
          }
          
          //add the question only if we have a valid correct answer
          if (correctIndex >= 0) {
            if (choices.length != paymentOptionsCount) {
              if (kDebugMode) {
                debugPrint('⚙️ Adjusting choice count from ${choices.length} to $paymentOptionsCount');
              }
              
              if (choices.length > paymentOptionsCount) {
                //too many choices, keep the correct one and some diverse others
                final correctChoice = choices[correctIndex];
                final remainingChoices = List<CashTallyChoice>.from(choices);
                remainingChoices.removeAt(correctIndex);
                
                //sort by how different they are from the correct total
                remainingChoices.sort((a, b) {
                  return (b.total - calculatedTotal).abs().compareTo((a.total - calculatedTotal).abs());
                });
                
                //create new list with exactly paymentOptionsCount items
                final trimmedChoices = <CashTallyChoice>[];
                trimmedChoices.add(correctChoice);
                
                //add most diverse incorrect choices
                final neededCount = paymentOptionsCount - 1;
                for (int i = 0; i < neededCount && i < remainingChoices.length; i++) {
                  trimmedChoices.add(remainingChoices[i]);
                }
                
                choices = trimmedChoices;
                correctIndex = 0;
              } else {
                //too few choices, add some incorrect ones
                while (choices.length < paymentOptionsCount) {
                  // Add incorrect choices with totals different from existing ones
                  final existingTotals = choices.map((c) => c.total).toSet();
                  double newTotal;
                  do {
                    newTotal = calculatedTotal + (50 * ((choices.length % 2) == 0 ? 1 : -1));
                  } while (existingTotals.contains(newTotal));
                  
                  final incorrectNotes = _createMoneyNotesCombination(newTotal.toInt(), availableNotes);
                  if (incorrectNotes.isNotEmpty) {
                    choices.add(CashTallyChoice(notes: incorrectNotes));
                  } else {
                    // Fallback to a simple option
                    choices.add(CashTallyChoice(notes: [_findNote(500, availableNotes)]));
                  }
                }
              }
            }
            questions.add(CashTallyQuestion(
              items: items,
              choices: choices,
              correctChoiceIndex: correctIndex,
            ));
          }
        }
        
        //log final questions in debug mode
        if (kDebugMode) {
          for (var q in questions) {
            debugPrint('🛒 Items (${q.items.length}): '
              '${q.items.map((i) => '${i.quantity}×${i.name}@${i.pricePerUnit}').join(', ')}');
            final correctTotal = q.items.fold(0.0, (sum, item) => sum + item.totalPrice);
            debugPrint('💰 Choices (${q.choices.length}): '
              '${q.choices.map((c) => c.total).join(', ')}  correctIndex=${q.correctChoiceIndex}');
            debugPrint('💯 Correct total: $correctTotal, '
                'chosen amount: ${q.choices[q.correctChoiceIndex].total}');
          }
        }
        
        //ensure we have enough questions or get predefined ones
        if (questions.isEmpty) {
          throw Exception('No valid questions could be generated');
        }
        
        return questions;
      } else {
        if (kDebugMode) {
          debugPrint('OpenAI API Error: ${response.statusCode} - ${response.body}');
        }
        throw Exception('Failed to generate questions: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error generating Cash Tally questions: $e');
      }
      throw Exception('Failed to generate questions: $e');
    }
  }
  
  //helper method to create valid money notes combination for a given amount
  List<MoneyNote> _createMoneyNotesCombination(int amount, List<MoneyNote> availableNotes) {
    //sort notes from highest to lowest
    final sortedNotes = List<MoneyNote>.from(availableNotes)
      ..sort((a, b) => b.value.compareTo(a.value));
    
    //greedy algorithm to find combination (up to 5 notes max)
    List<MoneyNote> result = [];
    int remaining = amount;
    
    //try largest notes first
    for (final note in sortedNotes) {
      while (result.length < 5 && remaining >= note.value) {
        result.add(note);
        remaining -= note.value.toInt();
      }
      
      if (remaining == 0) break;
    }
    
    //if we couldn't make exact change with 5 notes max, try some common combinations
    if (remaining > 0 || result.length > 5) {
      //try some predefined combinations based on common amounts
      final int noteValue10 = 10;
      final int noteValue20 = 20;
      final int noteValue50 = 50;
      final int noteValue100 = 100;
      final int noteValue500 = 500;
      
      //reset result
      result = [];
      
      //try different approaches based on amount ranges
      if (amount <= 100) {
        //for amounts up to 100, try combinations of smaller notes
        if (amount == 30) return _findNotes([10, 20], sortedNotes);
        if (amount == 60) return _findNotes([50, 10], sortedNotes);
        if (amount == 70) return _findNotes([50, 20], sortedNotes);
        if (amount == 80) return _findNotes([50, 20, 10], sortedNotes);
        if (amount == 90) return _findNotes([50, 20, 20], sortedNotes);
        if (amount == 100) return _findNotes([100], sortedNotes);
      } else if (amount <= 500) {
        //for amounts between 100-500, try different combinations
        if (amount % 100 == 0) {
          // Even hundreds
          for (int i = 0; i < amount ~/ 100 && result.length < 5; i++) {
            result.add(_findNote(noteValue100, sortedNotes));
          }
        } else {
          //mixed combinations
          int hundreds = amount ~/ 100;
          int remainder = amount % 100;
          
          for (int i = 0; i < hundreds && result.length < 4; i++) {
            result.add(_findNote(noteValue100, sortedNotes));
          }
          
          if (remainder <= 50 && result.length < 5) {
            result.add(_findNote(noteValue50, sortedNotes));
            remainder -= 50;
          }
          
          while (remainder >= 20 && result.length < 5) {
            result.add(_findNote(noteValue20, sortedNotes));
            remainder -= 20;
          }
          
          while (remainder >= 10 && result.length < 5) {
            result.add(_findNote(noteValue10, sortedNotes));
            remainder -= 10;
          }
        }
      } else {
        //for larger amounts, use 500+ notes
        while (amount >= 500 && result.length < 5) {
          result.add(_findNote(noteValue500, sortedNotes));
          amount -= 500;
        }
        
        while (amount >= 100 && result.length < 5) {
          result.add(_findNote(noteValue100, sortedNotes));
          amount -= 100;
        }
        
        if (amount > 0 && result.length < 5) {
          result.add(_findNote(noteValue50, sortedNotes));
          amount -= 50;
        }
        
        while (amount >= 20 && result.length < 5) {
          result.add(_findNote(noteValue20, sortedNotes));
          amount -= 20;
        }
        
        while (amount >= 10 && result.length < 5) {
          result.add(_findNote(noteValue10, sortedNotes));
          amount -= 10;
        }
      }
    }
    
    //verify our solution
    int total = result.fold(0, (sum, note) => sum + note.value.toInt());
    if (total == amount && result.length <= 5) {
      return result;
    }
    
    //if we got here, we couldn't find a valid combination
    return [];
  }
  
  //helper to find a note of specific value
  MoneyNote _findNote(int value, List<MoneyNote> notes) {
    return notes.firstWhere(
      (note) => note.value == value.toDouble(),
      orElse: () => notes.first // Fallback if not found
    );
  }
  
  //helper to find a list of notes
  List<MoneyNote> _findNotes(List<int> values, List<MoneyNote> availableNotes) {
    List<MoneyNote> result = [];
    for (int value in values) {
      result.add(_findNote(value, availableNotes));
    }
    return result;
  }
  
  //helper method to extract JSON from a string that might contain markdown or extra text
  String _extractJsonFromString(String input) {
    // try to find content between ```json and ``` markers
    final RegExp jsonBlockRegex = RegExp(r'```json\s*([\s\S]*?)\s*```');
    final match = jsonBlockRegex.firstMatch(input);
    
    if (match != null && match.groupCount >= 1) {
      return match.group(1)!;
    }
    
    //if no code block, try to find content between { } 
    final int firstBrace = input.indexOf('{');
    final int lastBrace = input.lastIndexOf('}');
    
    if (firstBrace != -1 && lastBrace != -1) {
      return input.substring(firstBrace, lastBrace + 1);
    }
    
    //if all else fails, return the original string
    return input;
  }
}