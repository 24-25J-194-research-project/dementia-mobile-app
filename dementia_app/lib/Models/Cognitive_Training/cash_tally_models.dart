//models for Cash Tally activity
class GroceryItem {
  final String name;
  final int quantity;
  final double pricePerUnit;

  GroceryItem({
    required this.name,
    required this.quantity,
    required this.pricePerUnit,
  });

  double get totalPrice => quantity * pricePerUnit;
}

class MoneyNote {
  final double value;
  final String imagePath;

  const MoneyNote({
    required this.value,
    required this.imagePath,
  });
}

class CashTallyChoice {
  final List<MoneyNote> notes;

  CashTallyChoice({
    required this.notes,
  });

  double get total => notes.fold(0, (total, note) => total + note.value);
}

class CashTallyQuestion {
  final List<GroceryItem> items;
  final List<CashTallyChoice> choices;
  final int correctChoiceIndex;

  CashTallyQuestion({
    required this.items,
    required this.choices,
    required this.correctChoiceIndex,
  });

  double get correctTotal {
    return items.fold(0, (total, item) => total + item.totalPrice);
  }
}