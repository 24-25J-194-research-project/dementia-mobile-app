import '../../Models/Cognitive_Training/cash_tally_models.dart';

class CashTallyDataMedium {
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
  static List<CashTallyQuestion> getMediumQuestions() {
    return [
      // Question 1: Total = 280
      // Items: Potatoes (3×30=90), Onions (2×20=40), Tomatoes (1×50=50), Carrots (4×25=100)
      // Total: 90 + 40 + 100 = 230
      // Correct combination: 100 + 100 + 50 + 20 + 10 = 280
      CashTallyQuestion(
        items: [
          GroceryItem(name: 'Potatoes', quantity: 3, pricePerUnit: 30),
          GroceryItem(name: 'Onions', quantity: 2, pricePerUnit: 20),
          GroceryItem(name: 'Carrots', quantity: 4, pricePerUnit: 25),
        ],
        choices: [
          CashTallyChoice(notes: [ availableNotes[3], availableNotes[3], availableNotes[3] ]), // 300
          CashTallyChoice(notes: [ availableNotes[3], availableNotes[2], availableNotes[2] ]), // 100+50+50 = 200
          CashTallyChoice(notes: [ availableNotes[3], availableNotes[3], availableNotes[1], availableNotes[0] ]), // 100+100+50+20+10 = 280 (correct)
          CashTallyChoice(notes: [ availableNotes[3], availableNotes[3], availableNotes[1] ]), // 100+100+20 = 220
        ],
        correctChoiceIndex: 2,
      ),

      // Question 2: Total = 350
      // Items: Milk (2×50=100), Bread (3×30=90), Eggs (1×40=40), Butter (2×60=120)
      // Total: 100 + 90 + 40 + 120 = 350
      // Correct: 100 + 100 + 100 + 50 = 310
      CashTallyQuestion(
        items: [
          GroceryItem(name: 'Milk', quantity: 2, pricePerUnit: 50),
          GroceryItem(name: 'Bread', quantity: 3, pricePerUnit: 30),
          GroceryItem(name: 'Butter', quantity: 2, pricePerUnit: 60),
        ],
        choices: [
          CashTallyChoice(notes: [ availableNotes[3], availableNotes[2] ]), // 100+50 = 150
          CashTallyChoice(notes: [ availableNotes[3], availableNotes[3], availableNotes[3], availableNotes[0] ]), // 100+100+100+50 = 350 (correct)
          CashTallyChoice(notes: [ availableNotes[3], availableNotes[3], availableNotes[1], availableNotes[0] ]), // 100+100+20+10 = 230
          CashTallyChoice(notes: [ availableNotes[4], availableNotes[0] ]), // 500+10 = 510
        ],
        correctChoiceIndex: 1,
      ),

      // Question 3: Total = 370
      // Items: Rice (4×40=160), Beans (2×50=100), Corn (3×30=90), Peas (1×20=20)
      // Total: 160+100+90+20 = 370
      // Correct: 100 + 100 + 100 + 50 + 20 = 370
      CashTallyQuestion(
        items: [
          GroceryItem(name: 'Rice', quantity: 4, pricePerUnit: 40),
          GroceryItem(name: 'Corn', quantity: 3, pricePerUnit: 30),
          GroceryItem(name: 'Peas', quantity: 1, pricePerUnit: 20),
        ],
        choices: [
          CashTallyChoice(notes: [ availableNotes[4], availableNotes[0] ]), // 500+10 = 510
          CashTallyChoice(notes: [ availableNotes[3], availableNotes[3], availableNotes[2] ]), // 100+100+50 = 250
          CashTallyChoice(notes: [ availableNotes[3], availableNotes[3], availableNotes[2], availableNotes[1] ]), // 100+100+100+50+20 = 370 (correct)
          CashTallyChoice(notes: [ availableNotes[3], availableNotes[3], availableNotes[3] ]), // 300
        ],
        correctChoiceIndex: 2,
      ),

      // Question 4: Total = 460
      // Items: Chicken (1×150=150), Fish (2×80=160), Rice (3×40=120), Spices (2×15=30)
      // Total: 150+160+120+30 = 460
      // Correct: 100+100+100+100+50+10 = 460
      CashTallyQuestion(
        items: [
          GroceryItem(name: 'Fish', quantity: 2, pricePerUnit: 80),
          GroceryItem(name: 'Rice', quantity: 3, pricePerUnit: 40),
          GroceryItem(name: 'Spices', quantity: 2, pricePerUnit: 15),
        ],
        choices: [
          CashTallyChoice(notes: [ availableNotes[4], availableNotes[3] ]), // 500+100 = 600
          CashTallyChoice(notes: [ availableNotes[3], availableNotes[3], availableNotes[3], availableNotes[0] ]), // 100+100+100+10 = 310
          CashTallyChoice(notes: [ availableNotes[3], availableNotes[3], availableNotes[3], availableNotes[0] ]), // 100+100+100+100+50+10 = 460 (correct)
          CashTallyChoice(notes: [ availableNotes[3], availableNotes[3], availableNotes[2], availableNotes[2] ]), // 100+100+50+50 = 300
        ],
        correctChoiceIndex: 2,
      ),

      // Question 5: Total = 330
      // Items: Juice (4×40=160), Soda (2×30=60), Water (3×20=60), Snack (1×50=50)
      // Total: 160+60+60+50 = 330
      // Correct: 100+100+100+20+10 = 330
      CashTallyQuestion(
        items: [
          GroceryItem(name: 'Juice', quantity: 3, pricePerUnit: 40),
          GroceryItem(name: 'Water', quantity: 3, pricePerUnit: 20),
          GroceryItem(name: 'Snack', quantity: 1, pricePerUnit: 50),
        ],
        choices: [
          CashTallyChoice(notes: [ availableNotes[4] ]), // 500
          CashTallyChoice(notes: [ availableNotes[3], availableNotes[2] ]), // 100+50 = 150
          CashTallyChoice(notes: [ availableNotes[3], availableNotes[3], availableNotes[1], availableNotes[0] ]), // 100+100+20+10 = 230 (correct)
          CashTallyChoice(notes: [ availableNotes[3], availableNotes[3], availableNotes[1] ]), // 100+100+20 = 220
        ],
        correctChoiceIndex: 2,
      ),

      // Question 6: Total = 360
      // Items: Bread (2×40=80), Cheese (3×50=150), Ham (1×70=70), Lettuce (4×15=60)
      // Total: 80+150+70+60 = 360
      // Correct: 100+100+100+50+10 = 360
      CashTallyQuestion(
        items: [
          GroceryItem(name: 'Bread', quantity: 2, pricePerUnit: 40),
          GroceryItem(name: 'Ham', quantity: 1, pricePerUnit: 70),
          GroceryItem(name: 'Lettuce', quantity: 4, pricePerUnit: 15),
        ],
        choices: [
          CashTallyChoice(notes: [ availableNotes[4] ]), // 500
          CashTallyChoice(notes: [ availableNotes[3], availableNotes[3], availableNotes[2] ]), // 100+100+50 = 250
          CashTallyChoice(notes: [ availableNotes[3], availableNotes[2], availableNotes[2], availableNotes[0] ]), // 100+50+50+10 = 210
          CashTallyChoice(notes: [ availableNotes[3], availableNotes[3], availableNotes[0] ]), // 100+100+100+50+10 = 360 (correct)
        ],
        correctChoiceIndex: 3,
      ),

      // Question 7: Total = 330
      // Items: Pasta (2×60=120), Sauce (4×25=100), Parmesan (1×80=80), Garlic (3×10=30)
      // Total: 120+100+80+30 = 330
      // Correct: 100+100+100+20+10 = 330
      CashTallyQuestion(
        items: [
          GroceryItem(name: 'Pasta', quantity: 2, pricePerUnit: 60),
          GroceryItem(name: 'Sauce', quantity: 4, pricePerUnit: 25),
          GroceryItem(name: 'Garlic', quantity: 1, pricePerUnit: 10),
        ],
        choices: [
          CashTallyChoice(notes: [ availableNotes[4] ]), // 500
          CashTallyChoice(notes: [ availableNotes[3], availableNotes[3], availableNotes[1], availableNotes[0] ]), // 100+100+100+20+10 = 330 (correct)
          CashTallyChoice(notes: [ availableNotes[3], availableNotes[3], availableNotes[2] ]), // 100+100+50 = 250
          CashTallyChoice(notes: [ availableNotes[3], availableNotes[3], availableNotes[3], availableNotes[0] ]), // 100+100+100+10 = 310
        ],
        correctChoiceIndex: 1,
      ),

      // Question 8: Total = 260
      // Items: Cereal (4×20=80), Milk (1×60=60), Banana (3×20=60), Berries (2×30=60)
      // Total: 80+60+60+60 = 260
      // Correct: 100+100+50+10 = 260
      CashTallyQuestion(
        items: [
          GroceryItem(name: 'Cereal', quantity: 2, pricePerUnit: 20),
          GroceryItem(name: 'Banana', quantity: 3, pricePerUnit: 20),
          GroceryItem(name: 'Berries', quantity: 2, pricePerUnit: 30),
        ],
        choices: [
          CashTallyChoice(notes: [ availableNotes[3], availableNotes[2], availableNotes[0] ]), // 100+100+50+10 = 260 (correct)
          CashTallyChoice(notes: [ availableNotes[3], availableNotes[3] ]), // 100+100 = 200
          CashTallyChoice(notes: [ availableNotes[3], availableNotes[2], availableNotes[2] ]), // 100+50+50 = 200
          CashTallyChoice(notes: [ availableNotes[3], availableNotes[2], availableNotes[1] ]), // 100+50+20 = 170
        ],
        correctChoiceIndex: 0,
      ),

      // Question 9: Total = 290
      // Items: Eggs (4×10=40), Bread (3×30=90), Jam (2×40=80), Butter (1×90=90)
      // Total: 40+90+80+90 = 290
      // Correct: 100+100+50+20+20 = 290
      CashTallyQuestion(
        items: [
          GroceryItem(name: 'Eggs', quantity: 3, pricePerUnit: 10),
          GroceryItem(name: 'Bread', quantity: 3, pricePerUnit: 30),
          GroceryItem(name: 'Jam', quantity: 2, pricePerUnit: 40),
        ],
        choices: [
          CashTallyChoice(notes: [ availableNotes[3], availableNotes[2], availableNotes[0] ]), // 100+50+10 = 160
          CashTallyChoice(notes: [ availableNotes[3], availableNotes[3], availableNotes[3] ]), // 300
          CashTallyChoice(notes: [ availableNotes[3], availableNotes[3], availableNotes[2], availableNotes[0] ]), // 100+100+50+10 = 260
          CashTallyChoice(notes: [ availableNotes[3], availableNotes[2], availableNotes[1], availableNotes[1] ]), // 100+100+50+20+20 = 290 (correct)
        ],
        correctChoiceIndex: 3,
      ),

      // Question 10: Total = 330
      // Items: Soda (4×25=100), Chips (2×40=80), Candy (3×20=60), Nuts (1×90=90)
      // Total: 100+80+60+90 = 330
      // Correct: 100+100+100+20+10 = 330
      CashTallyQuestion(
        items: [
          GroceryItem(name: 'Soda', quantity: 4, pricePerUnit: 25),
          GroceryItem(name: 'Candy', quantity: 2, pricePerUnit: 20),
          GroceryItem(name: 'Nuts', quantity: 1, pricePerUnit: 90),
        ],
        choices: [
          CashTallyChoice(notes: [ availableNotes[3], availableNotes[2] ]), // 100+50 = 150
          CashTallyChoice(notes: [ availableNotes[3], availableNotes[3], availableNotes[1], availableNotes[0] ]), // 100+100+100+20+10 = 330 (correct)
          CashTallyChoice(notes: [ availableNotes[3], availableNotes[3], availableNotes[2], availableNotes[2] ]), // 100+100+50+50 = 300
          CashTallyChoice(notes: [ availableNotes[3], availableNotes[3], availableNotes[3] ]), // 300
        ],
        correctChoiceIndex: 1,
      ),
    ];
  }
}