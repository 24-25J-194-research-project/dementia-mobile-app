import '../../Models/Cognitive_Training/cash_tally_models.dart';

class CashTallyDataEasy {
  // Define money notes (same as in hard level)
  static final List<MoneyNote> availableNotes = [
    const MoneyNote(value: 10, imagePath: 'assets/cash_tally/10_note.jpg'),
    const MoneyNote(value: 20, imagePath: 'assets/cash_tally/20_note.jpg'),
    const MoneyNote(value: 50, imagePath: 'assets/cash_tally/50_note.jpg'),
    const MoneyNote(value: 100, imagePath: 'assets/cash_tally/100_note.jpg'),
    const MoneyNote(value: 500, imagePath: 'assets/cash_tally/500_note.jpg'),
    const MoneyNote(value: 1000, imagePath: 'assets/cash_tally/1000_note.jpg'),
    const MoneyNote(value: 5000, imagePath: 'assets/cash_tally/5000_note.jpg'),
  ];
  
  // Returns 10 medium-level Cash Tally questions, each with exactly 4 items.
  static List<CashTallyQuestion> getEasyQuestions() {
    return [
      // Question 1
      CashTallyQuestion(
        items: [
          GroceryItem(name: 'Oranges', quantity: 3, pricePerUnit: 30), // 90
          GroceryItem(name: 'Yogurt', quantity: 2, pricePerUnit: 45),  // 90
        ],
        // Total = 180
        choices: [
          CashTallyChoice(notes: [availableNotes[4]]), // 500 (over)
          CashTallyChoice(notes: [ // Correct: 100+50+20+10
            availableNotes[3], 
            availableNotes[2], 
            availableNotes[1], 
            availableNotes[0]
          ]),
          CashTallyChoice(notes: [ // 50x3 + 20 + 10
            availableNotes[2], 
            availableNotes[2], 
            availableNotes[2], 
            availableNotes[1], 
            availableNotes[0]
          ]),
        ],
        correctChoiceIndex: 1,
      ),

      // Question 2
      CashTallyQuestion(
        items: [
          GroceryItem(name: 'Bread', quantity: 2, pricePerUnit: 50), // 100
          GroceryItem(name: 'Jam', quantity: 1, pricePerUnit: 100),  // 100
        ],
        // Total = 200
        choices: [
          CashTallyChoice(notes: [availableNotes[4]]), // 500 (over)
          CashTallyChoice(notes: [ // Correct: 100x2
            availableNotes[3], 
            availableNotes[3]
          ]),
          CashTallyChoice(notes: [ // 50x4
            availableNotes[2], 
            availableNotes[2], 
            availableNotes[2], 
            availableNotes[2]
          ]),
        ],
        correctChoiceIndex: 1,
      ),

      // Question 3
      CashTallyQuestion(
        items: [
          GroceryItem(name: 'Milk', quantity: 1, pricePerUnit: 70),   // 70
          GroceryItem(name: 'Cereal', quantity: 2, pricePerUnit: 90), // 180
        ],
        // Total = 250
        choices: [
          CashTallyChoice(notes: [ // Correct: 100x2 + 50
            availableNotes[3], 
            availableNotes[3], 
            availableNotes[2]
          ]),
          CashTallyChoice(notes: [ // 50x5
            availableNotes[2], 
            availableNotes[2], 
            availableNotes[2], 
            availableNotes[2], 
            availableNotes[2]
          ]),
          CashTallyChoice(notes: [ // 100+100+20+20+10
            availableNotes[3], 
            availableNotes[3], 
            availableNotes[1], 
            availableNotes[1], 
            availableNotes[0]
          ]),
        ],
        correctChoiceIndex: 0,
      ),

      // Question 4
      CashTallyQuestion(
        items: [
          GroceryItem(name: 'Chicken', quantity: 1, pricePerUnit: 320), // 320
          GroceryItem(name: 'Rice', quantity: 2, pricePerUnit: 40),     // 80
        ],
        // Total = 400
        choices: [
          CashTallyChoice(notes: [availableNotes[5]]), // 1000 (over)
          CashTallyChoice(notes: [ // Correct: 100x4
            availableNotes[3], 
            availableNotes[3], 
            availableNotes[3], 
            availableNotes[3]
          ]),
          CashTallyChoice(notes: [ // 500-100 (incorrect)
            availableNotes[4], 
            availableNotes[3]
          ]),
        ],
        correctChoiceIndex: 1,
      ),

      // Question 5
      CashTallyQuestion(
        items: [
          GroceryItem(name: 'Shampoo', quantity: 1, pricePerUnit: 250), // 250
          GroceryItem(name: 'Soap', quantity: 2, pricePerUnit: 50),     // 100
        ],
        // Total = 350
        choices: [
          CashTallyChoice(notes: [availableNotes[3], availableNotes[0]]), // 100+10
          CashTallyChoice(notes: [ // Correct: 100x3 + 50
            availableNotes[3], 
            availableNotes[3], 
            availableNotes[3], 
            availableNotes[2]
          ]),
          CashTallyChoice(notes: [ // 200+100+50 (invalid 200 note)
            availableNotes[3], 
            availableNotes[3], 
            availableNotes[2]
          ]),
        ],
        correctChoiceIndex: 1,
      ),

      // Question 6
      CashTallyQuestion(
        items: [
          GroceryItem(name: 'Eggs', quantity: 3, pricePerUnit: 20),  // 60
          GroceryItem(name: 'Butter', quantity: 1, pricePerUnit: 140), // 140
        ],
        // Total = 200
        choices: [
          CashTallyChoice(notes: [ // Correct: 100x2
            availableNotes[3], 
            availableNotes[3]
          ]),
          CashTallyChoice(notes: [ // 50x4
            availableNotes[2], 
            availableNotes[0], 
            availableNotes[2]
          ]),
          CashTallyChoice(notes: [ // Mixed
            availableNotes[3], 
            availableNotes[2], 
            availableNotes[1]
          ]),
        ],
        correctChoiceIndex: 0,
      ),

      // Question 7
      CashTallyQuestion(
        items: [
          GroceryItem(name: 'Notebook', quantity: 1, pricePerUnit: 150), // 150
          GroceryItem(name: 'Pens', quantity: 3, pricePerUnit: 50),      // 150
        ],
        // Total = 300
        choices: [
          CashTallyChoice(notes: [availableNotes[5], availableNotes[0]]), // 1000 + 10
          CashTallyChoice(notes: [ // Correct: 100x3
            availableNotes[3], 
            availableNotes[3], 
            availableNotes[3]
          ]),
          CashTallyChoice(notes: [ // Mixed
            availableNotes[4], 
            availableNotes[3]
          ]),
        ],
        correctChoiceIndex: 1,
      ),

      // Question 8
      CashTallyQuestion(
        items: [
          GroceryItem(name: 'Tomatoes', quantity: 3, pricePerUnit: 40), // 120
          GroceryItem(name: 'Onions', quantity: 2, pricePerUnit: 90),   // 180
        ],
        // Total = 300
        choices: [
          CashTallyChoice(notes: [availableNotes[3], availableNotes[4]]), // 100+500
          CashTallyChoice(notes: [ // Correct: 100x3
            availableNotes[3], 
            availableNotes[3], 
            availableNotes[3]
          ]),
          CashTallyChoice(notes: [ // 10+50+50+500
            availableNotes[0], 
            availableNotes[2], 
            availableNotes[2],
            availableNotes[4],
          ]),
        ],
        correctChoiceIndex: 1,
      ),

      // Question 9
      CashTallyQuestion(
        items: [
          GroceryItem(name: 'Chocolate', quantity: 2, pricePerUnit: 75), // 150
          GroceryItem(name: 'Cookies', quantity: 1, pricePerUnit: 120),  // 120
        ],
        // Total = 270
        choices: [
          CashTallyChoice(notes: [ //50+20+10
            availableNotes[2], 
            availableNotes[1], 
            availableNotes[0]
          ]), //
          CashTallyChoice(notes: [ // 1000+50+10
            availableNotes[5], 
            availableNotes[2],
            availableNotes[0],
          ]),
          CashTallyChoice(notes: [ // Correct: 100x2 + 50 + 20
            availableNotes[3], 
            availableNotes[3], 
            availableNotes[2], 
            availableNotes[1]
          ]),
        ],
        correctChoiceIndex: 2,
      ),

      // Question 10
      CashTallyQuestion(
        items: [
          GroceryItem(name: 'Juice', quantity: 1, pricePerUnit: 170),   // 170
          GroceryItem(name: 'Chips', quantity: 2, pricePerUnit: 40),   // 80
        ],
        // Total = 250
        choices: [
          CashTallyChoice(notes: [ //correct: 100x2 + 50
            availableNotes[3], 
            availableNotes[3], 
            availableNotes[2]
          ]),
          CashTallyChoice(notes: [ // 500*2 + 100 + 50
            availableNotes[4], 
            availableNotes[4], 
            availableNotes[3], 
            availableNotes[2]
          ]),
          CashTallyChoice(notes: [ // 100+50+50+20
            availableNotes[3], 
            availableNotes[2], 
            availableNotes[2], 
            availableNotes[1]
          ]),
        ],
        correctChoiceIndex: 0,
      ),
   
    ];
  }
}