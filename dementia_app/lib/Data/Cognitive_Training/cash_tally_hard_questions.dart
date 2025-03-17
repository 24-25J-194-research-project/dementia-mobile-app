import '../../Components/Models/Cognitive_Training/cash_tally_models.dart';

class CashTallyDataHard {
  // Define money notes
  static final List<MoneyNote> availableNotes = [
    const MoneyNote(value: 10, imagePath: 'assets/cash_tally/10_note.jpg'),
    const MoneyNote(value: 20, imagePath: 'assets/cash_tally/20_note.jpg'),
    const MoneyNote(value: 50, imagePath: 'assets/cash_tally/50_note.jpg'),
    const MoneyNote(value: 100, imagePath: 'assets/cash_tally/100_note.jpg'),
    const MoneyNote(value: 500, imagePath: 'assets/cash_tally/500_note.jpg'),
    const MoneyNote(value: 1000, imagePath: 'assets/cash_tally/1000_note.jpg'),
    const MoneyNote(value: 5000, imagePath: 'assets/cash_tally/5000_note.jpg'),
  ];
  
  // Get the list of questions
  static List<CashTallyQuestion> getHardQuestions() {
    return [
      // Question 1
      CashTallyQuestion(
        items: [
          GroceryItem(name: 'Potatoes', quantity: 2, pricePerUnit: 120),  // 240
          GroceryItem(name: 'Onions', quantity: 1, pricePerUnit: 80),     // 80
          GroceryItem(name: 'Tomatoes', quantity: 3, pricePerUnit: 60),   // 180
          GroceryItem(name: 'Carrots', quantity: 1, pricePerUnit: 100),   // 100
        ],
        // Total = 600
        choices: [
          CashTallyChoice(notes: [
            availableNotes[4], // Rs.500
            availableNotes[0], // Rs.10
          ]),
          CashTallyChoice(notes: [
            availableNotes[4], // Rs.500
          ]),
          CashTallyChoice(notes: [
            availableNotes[3], // Rs.100
            availableNotes[3], // Rs.100
            availableNotes[3], // Rs.100
            availableNotes[3], // Rs.100
            availableNotes[1], // Rs.20
          ]),
          CashTallyChoice(notes: [
            availableNotes[5], // Rs.1000
          ]),
          // Correct: 500 + 100 = 600
          CashTallyChoice(notes: [
            availableNotes[4], // Rs.500
            availableNotes[3], // Rs.100
          ]),
        ],
        correctChoiceIndex: 4,
      ),

      // Question 2
      CashTallyQuestion(
        items: [
          GroceryItem(name: 'Rice', quantity: 3, pricePerUnit: 40),     // 120
          GroceryItem(name: 'Beans', quantity: 2, pricePerUnit: 60),    // 120
          GroceryItem(name: 'Milk', quantity: 1, pricePerUnit: 50),     // 50
          GroceryItem(name: 'Bread', quantity: 4, pricePerUnit: 30),    // 120
        ],
        // Total = 410
        choices: [
          CashTallyChoice(notes: [
            availableNotes[4],
            availableNotes[0],
          ]), // 500 + 10 = 510
          CashTallyChoice(notes: [
            availableNotes[3],
            availableNotes[3],
            availableNotes[1],
            availableNotes[0],
          ]), // 100 + 100 + 20 + 10 = 230
          // Correct: 100 + 100 + 100 + 100 + 10 = 410
          CashTallyChoice(notes: [
            availableNotes[3],
            availableNotes[3],
            availableNotes[3],
            availableNotes[3],
            availableNotes[0],
          ]),
          CashTallyChoice(notes: [
            availableNotes[3],
            availableNotes[3],
            availableNotes[2],
          ]), // 100 + 100 + 50 = 250
          CashTallyChoice(notes: [
            availableNotes[4],
            availableNotes[3],
          ]), // 500 + 100 = 600
        ],
        correctChoiceIndex: 2,
      ),

      // Question 3
      CashTallyQuestion(
        items: [
          GroceryItem(name: 'Chicken', quantity: 2, pricePerUnit: 250), // 500
          GroceryItem(name: 'Eggs', quantity: 5, pricePerUnit: 10),     // 50
          GroceryItem(name: 'Bread', quantity: 3, pricePerUnit: 40),      // 120
          GroceryItem(name: 'Butter', quantity: 1, pricePerUnit: 150),    // 150
        ],
        // Total = 820
        choices: [
          CashTallyChoice(notes: [
            availableNotes[5],
          ]), // 1000
          CashTallyChoice(notes: [
            availableNotes[4],
            availableNotes[4],
          ]), // 500 + 500 = 1000
          CashTallyChoice(notes: [
            availableNotes[3],
            availableNotes[3],
            availableNotes[3],
            availableNotes[3],
            availableNotes[0],
          ]), // 100 + 100 + 100 + 100 + 10 = 410
          // Correct: 500 + 100 + 100 + 100 + 20 = 820
          CashTallyChoice(notes: [
            availableNotes[4],
            availableNotes[3],
            availableNotes[3],
            availableNotes[3],
            availableNotes[1],
          ]),
          CashTallyChoice(notes: [
            availableNotes[3],
            availableNotes[3],
            availableNotes[2],
          ]), // 100 + 100 + 50 = 250
        ],
        correctChoiceIndex: 3,
      ),

      // Question 4
      CashTallyQuestion(
        items: [
          GroceryItem(name: 'Apples', quantity: 4, pricePerUnit: 30),   // 120
          GroceryItem(name: 'Bananas', quantity: 3, pricePerUnit: 20),  // 60
          GroceryItem(name: 'Oranges', quantity: 2, pricePerUnit: 50),  // 100
          GroceryItem(name: 'Grapes', quantity: 1, pricePerUnit: 200),  // 200
        ],
        // Total = 480
        choices: [
          CashTallyChoice(notes: [
            availableNotes[4],
            availableNotes[0],
            availableNotes[0],
          ]), // 500 + 10 + 10 = 520
          // Correct: 100+100+100+100+50+20+10 = 480
          CashTallyChoice(notes: [
            availableNotes[3],
            availableNotes[3],
            availableNotes[3],
            availableNotes[3],
            availableNotes[2],
            availableNotes[1],
            availableNotes[0],
          ]),
          CashTallyChoice(notes: [
            availableNotes[3],
            availableNotes[3],
            availableNotes[3],
          ]), // 100+100+100 = 300
          CashTallyChoice(notes: [
            availableNotes[4],
            availableNotes[3],
          ]), // 500+100 = 600
          CashTallyChoice(notes: [
            availableNotes[3],
            availableNotes[3],
            availableNotes[1],
          ]), // 100+100+20 = 220
        ],
        correctChoiceIndex: 1,
      ),

      // Question 5
      CashTallyQuestion(
        items: [
          GroceryItem(name: 'Soda', quantity: 1, pricePerUnit: 60),       // 60
          GroceryItem(name: 'Chips', quantity: 4, pricePerUnit: 35),      // 140
          GroceryItem(name: 'Chocolate', quantity: 2, pricePerUnit: 45),  // 90
          GroceryItem(name: 'Cookies', quantity: 3, pricePerUnit: 50),    // 150
        ],
        // Total = 440
        choices: [
          CashTallyChoice(notes: [
            availableNotes[4],
            availableNotes[0],
          ]), // 500+10 = 510
          CashTallyChoice(notes: [
            availableNotes[3],
            availableNotes[2],
            availableNotes[2],
          ]), // 100+50+50 = 200
          CashTallyChoice(notes: [
            availableNotes[5],
          ]), // 1000
          CashTallyChoice(notes: [
            availableNotes[4],
            availableNotes[3],
          ]), // 500+100 = 600
          // Correct: 100+100+100+100+20+20 = 440
          CashTallyChoice(notes: [
            availableNotes[3],
            availableNotes[3],
            availableNotes[3],
            availableNotes[3],
            availableNotes[1],
            availableNotes[1],
          ]),
        ],
        correctChoiceIndex: 4,
      ),

      // Question 6
      CashTallyQuestion(
        items: [
          GroceryItem(name: 'Fish', quantity: 3, pricePerUnit: 150),    // 450
          GroceryItem(name: 'Shrimp', quantity: 1, pricePerUnit: 200),  // 200
          GroceryItem(name: 'Spices', quantity: 2, pricePerUnit: 30),     // 60
          GroceryItem(name: 'Lemon', quantity: 4, pricePerUnit: 15),      // 60
        ],
        // Total = 770
        choices: [
          // Correct: 500+100+100+50+20 = 770
          CashTallyChoice(notes: [
            availableNotes[4],
            availableNotes[3],
            availableNotes[3],
            availableNotes[2],
            availableNotes[1],
          ]),
          CashTallyChoice(notes: [
            availableNotes[4],
            availableNotes[4],
          ]), // 500+500 = 1000
          CashTallyChoice(notes: [
            availableNotes[3],
            availableNotes[3],
            availableNotes[3],
            availableNotes[3],
          ]), // 100+100+100+100 = 400
          CashTallyChoice(notes: [
            availableNotes[5],
          ]), // 1000
          CashTallyChoice(notes: [
            availableNotes[3],
            availableNotes[3],
            availableNotes[1],
          ]), // 100+100+20 = 220
        ],
        correctChoiceIndex: 0,
      ),

      // Question 7
      CashTallyQuestion(
        items: [
          GroceryItem(name: 'Pasta', quantity: 2, pricePerUnit: 70),   // 140
          GroceryItem(name: 'Sauce', quantity: 3, pricePerUnit: 40),   // 120
          GroceryItem(name: 'Cheese', quantity: 1, pricePerUnit: 150), // 150
          GroceryItem(name: 'Basil', quantity: 5, pricePerUnit: 10),   // 50
        ],
        // Total = 460
        choices: [
          CashTallyChoice(notes: [
            availableNotes[4],
            availableNotes[1],
          ]), // 500+20 = 520
          CashTallyChoice(notes: [
            availableNotes[5],
          ]), // 1000
          CashTallyChoice(notes: [
            availableNotes[3],
            availableNotes[3],
            availableNotes[1],
          ]), // 100+100+20 = 220
          CashTallyChoice(notes: [
            availableNotes[4],
            availableNotes[3],
          ]), // 500+100 = 600
          // Correct: 100+100+100+100+50+10 = 460
          CashTallyChoice(notes: [
            availableNotes[3],
            availableNotes[3],
            availableNotes[3],
            availableNotes[3],
            availableNotes[2],
            availableNotes[0],
          ]),
        ],
        correctChoiceIndex: 4,
      ),

      // Question 8
      CashTallyQuestion(
        items: [
          GroceryItem(name: 'Coffee', quantity: 1, pricePerUnit: 250), // 250
          GroceryItem(name: 'Tea', quantity: 2, pricePerUnit: 80),     // 160
          GroceryItem(name: 'Sugar', quantity: 3, pricePerUnit: 40),   // 120
          GroceryItem(name: 'Milk', quantity: 1, pricePerUnit: 60),    // 60
        ],
        // Total = 590
        choices: [
          CashTallyChoice(notes: [
            availableNotes[3],
            availableNotes[3],
            availableNotes[3],
          ]), // 100+100+100 = 300
          CashTallyChoice(notes: [
            availableNotes[5],
          ]), // 1000
          // Correct: 500+50+20+20 = 590
          CashTallyChoice(notes: [
            availableNotes[4],
            availableNotes[2],
            availableNotes[1],
            availableNotes[1],
          ]),
          CashTallyChoice(notes: [
            availableNotes[4],
            availableNotes[3],
          ]), // 500+100 = 600
          CashTallyChoice(notes: [
            availableNotes[3],
            availableNotes[3],
            availableNotes[1],
          ]), // 100+100+20 = 220
        ],
        correctChoiceIndex: 2,
      ),

      // Question 9
      CashTallyQuestion(
        items: [
          GroceryItem(name: 'Beef', quantity: 2, pricePerUnit: 300),    // 600
          GroceryItem(name: 'Potatoes', quantity: 3, pricePerUnit: 40),   // 120
          GroceryItem(name: 'Peppers', quantity: 1, pricePerUnit: 90),    // 90
          GroceryItem(name: 'Onions', quantity: 4, pricePerUnit: 30),     // 120
        ],
        // Total = 930
        choices: [
          CashTallyChoice(notes: [
            availableNotes[5],
          ]), // 1000
          // Correct: 500+100+100+100+100+20+10 = 930
          CashTallyChoice(notes: [
            availableNotes[4],
            availableNotes[3],
            availableNotes[3],
            availableNotes[3],
            availableNotes[3],
            availableNotes[1],
            availableNotes[0],
          ]),
          CashTallyChoice(notes: [
            availableNotes[4],
            availableNotes[4],
          ]), // 500+500 = 1000
          CashTallyChoice(notes: [
            availableNotes[3],
            availableNotes[3],
            availableNotes[3],
          ]), // 100+100+100 = 300
          CashTallyChoice(notes: [
            availableNotes[4],
            availableNotes[3],
          ]), // 500+100 = 600
        ],
        correctChoiceIndex: 1,
      ),

      // Question 10
      CashTallyQuestion(
        items: [
          GroceryItem(name: 'Eggplant', quantity: 4, pricePerUnit: 75),   // 300
          GroceryItem(name: 'Zucchini', quantity: 2, pricePerUnit: 85),   // 170
          GroceryItem(name: 'Bell Pepper', quantity: 3, pricePerUnit: 40),  // 120
          GroceryItem(name: 'Spinach', quantity: 1, pricePerUnit: 50),      // 50
        ],
        // Total = 640
        choices: [
          CashTallyChoice(notes: [
            availableNotes[3],
            availableNotes[3],
            availableNotes[3],
            availableNotes[3],
            availableNotes[0],
          ]), // 100+100+100+100+10 = 410
          CashTallyChoice(notes: [
            availableNotes[4],
            availableNotes[4],
          ]), // 500+500 = 1000
          CashTallyChoice(notes: [
            availableNotes[5],
          ]), // 1000
          // Correct: 500+100+20+20 = 640
          CashTallyChoice(notes: [
            availableNotes[4],
            availableNotes[3],
            availableNotes[1],
            availableNotes[1],
          ]),
          CashTallyChoice(notes: [
            availableNotes[3],
            availableNotes[2],
            availableNotes[2],
          ]), // 100+50+50 = 200
        ],
        correctChoiceIndex: 3,
      ),
    ];
  }
}