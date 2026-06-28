import 'package:uuid/uuid.dart';

enum TransactionType { income, expense }

class Transaction {
  final String id;
  final String title;
  final double amount;
  final String category; // Food, Travel, Bills, Shopping, Salary, Investment
  final TransactionType type;
  final DateTime date;
  final String note;
  final List<String> tags;

  Transaction({
    String? id,
    required this.title,
    required this.amount,
    required this.category,
    required this.type,
    required this.date,
    this.note = '',
    this.tags = const [],
  }) : id = id ?? const Uuid().v4();

  // Create a copy of this object with optional new values
  Transaction copyWith({
    String? id,
    String? title,
    double? amount,
    String? category,
    TransactionType? type,
    DateTime? date,
    String? note,
    List<String>? tags,
  }) {
    return Transaction(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      type: type ?? this.type,
      date: date ?? this.date,
      note: note ?? this.note,
      tags: tags ?? this.tags,
    );
  }

  // Convert a JSON Map into a Transaction object (Deserialization)
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      category: json['category'] as String,
      type: TransactionType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => TransactionType.expense,
      ),
      date: DateTime.parse(json['date'] as String),
      note: json['note'] as String? ?? '',
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  // Convert a Transaction object into a JSON Map (Serialization)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category,
      'type': type.toString().split('.').last,
      'date': date.toIso8601String(),
      'note': note,
      'tags': tags,
    };
  }
}
