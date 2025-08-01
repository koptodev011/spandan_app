import 'package:flutter/foundation.dart';

enum TransactionType { income, expense }

class Transaction {
  final String id;
  final DateTime date;
  final String description;
  final double amount;
  final TransactionType type;
  final String category;
  final String? patientId;
  final String? patientName;

  Transaction({
    required this.id,
    required this.date,
    required this.description,
    required this.amount,
    required this.type,
    required this.category,
    this.patientId,
    this.patientName,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'description': description,
      'amount': amount,
      'type': type.toString(),
      'category': category,
      'patientId': patientId,
      'patientName': patientName,
    };
  }

  // Create from JSON
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      date: DateTime.parse(json['date']),
      description: json['description'],
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] == 'TransactionType.income' 
          ? TransactionType.income 
          : TransactionType.expense,
      category: json['category'],
      patientId: json['patientId'],
      patientName: json['patientName'],
    );
  }

  // Copy with method for immutability
  Transaction copyWith({
    String? id,
    DateTime? date,
    String? description,
    double? amount,
    TransactionType? type,
    String? category,
    String? patientId,
    String? patientName,
  }) {
    return Transaction(
      id: id ?? this.id,
      date: date ?? this.date,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
    );
  }
}

// Categories for transactions
class TransactionCategories {
  static const List<String> income = [
    'Therapy Sessions',
    'Consultation',
    'Group Therapy',
    'Other Income',
  ];

  static const List<String> expense = [
    'Office Rent',
    'Utilities',
    'Medical Supplies',
    'Equipment',
    'Marketing',
    'Insurance',
    'Other Expenses',
  ];

  static List<String> getCategories(TransactionType type) {
    return type == TransactionType.income ? income : expense;
  }
}
