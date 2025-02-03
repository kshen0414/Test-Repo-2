// lib/models/expense.dart

class Expense {
  final String id;
  final double amount;
  final String category;
  final DateTime date;
  final String? note;
  final bool isVoiceInput;
  final bool isReceipt;

  Expense({
    String? id,  // Make id optional
    required this.amount,
    required this.category,
    required this.date,
    this.note,
    this.isVoiceInput = false,
    this.isReceipt = false,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(); // Use provided ID or generate new one

  // Update toMap method
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
      'note': note,
      'isVoiceInput': isVoiceInput,
      'isReceipt': isReceipt,
    };
  }

  // Update fromMap factory
  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],  // Include ID when creating from map
      amount: map['amount'],
      category: map['category'],
      date: DateTime.parse(map['date']),
      note: map['note'],
      isVoiceInput: map['isVoiceInput'] ?? false,
      isReceipt: map['isReceipt'] ?? false,
    );
  }

  // Update copyWith method
  Expense copyWith({
    String? id,  // Add id to copyWith
    double? amount,
    String? category,
    DateTime? date,
    String? note,
    bool? isVoiceInput,
    bool? isReceipt,
  }) {
    return Expense(
      id: id ?? this.id,  // Preserve ID when copying
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      note: note ?? this.note,
      isVoiceInput: isVoiceInput ?? this.isVoiceInput,
      isReceipt: isReceipt ?? this.isReceipt,
    );
  }
}