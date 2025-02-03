class Receipt {
  final String id;
  final double amount;
  final String merchantName;
  final DateTime date;
  final double taxAmount;
  final String? note;
  final String? imagePath;

  Receipt({
    String? id,
    required this.amount,
    required this.merchantName,
    required this.date,
    required this.taxAmount,
    this.note,
    this.imagePath,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  // Convert Receipt to a Map for saving to storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'merchantName': merchantName,
      'date': date.toIso8601String(),
      'taxAmount': taxAmount,
      'note': note,
      'imagePath': imagePath,
    };
  }

  // Create a Receipt from a Map (e.g., when loading from storage)
  factory Receipt.fromMap(Map<String, dynamic> map) {
    return Receipt(
      id: map['id'],
      amount: map['amount'],
      merchantName: map['merchantName'],
      date: DateTime.parse(map['date']),
      taxAmount: map['taxAmount'],
      note: map['note'],
      imagePath: map['imagePath'],
    );
  }

  // Add the copyWith method
  Receipt copyWith({
    String? id,
    double? amount,
    String? merchantName,
    DateTime? date,
    double? taxAmount,
    String? note,
    String? imagePath,
  }) {
    return Receipt(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      merchantName: merchantName ?? this.merchantName,
      date: date ?? this.date,
      taxAmount: taxAmount ?? this.taxAmount,
      note: note ?? this.note,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}
