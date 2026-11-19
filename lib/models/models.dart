import 'package:flutter/material.dart';

enum TransactionType { expense, income }

class CategoryModel {
  final int? id;
  final String name;
  final int iconCodePoint;
  final int colorValue;
  final TransactionType type;
  final double monthlyBudget;
  final int sortOrder;

  const CategoryModel({
    this.id,
    required this.name,
    required this.iconCodePoint,
    required this.colorValue,
    required this.type,
    this.monthlyBudget = 0,
    this.sortOrder = 0,
  });

  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');
  Color get color => Color(colorValue);

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'icon_code': iconCodePoint,
      'color_value': colorValue,
      'type': type == TransactionType.expense ? 'expense' : 'income',
      'monthly_budget': monthlyBudget,
      'sort_order': sortOrder,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      iconCodePoint: map['icon_code'] as int,
      colorValue: map['color_value'] as int,
      type: (map['type'] as String) == 'expense'
          ? TransactionType.expense
          : TransactionType.income,
      monthlyBudget: (map['monthly_budget'] as num?)?.toDouble() ?? 0.0,
      sortOrder: (map['sort_order'] as int?) ?? 0,
    );
  }

  CategoryModel copyWith({
    int? id,
    String? name,
    int? iconCodePoint,
    int? colorValue,
    TransactionType? type,
    double? monthlyBudget,
    int? sortOrder,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      colorValue: colorValue ?? this.colorValue,
      type: type ?? this.type,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

class TransactionModel {
  final int? id;
  final double amount;
  final String note;
  final DateTime date;
  final int categoryId;
  final TransactionType type;

  // Joined fields for convenience
  final String? categoryName;
  final int? categoryIconCode;
  final int? categoryColorValue;

  const TransactionModel({
    this.id,
    required this.amount,
    required this.note,
    required this.date,
    required this.categoryId,
    required this.type,
    this.categoryName,
    this.categoryIconCode,
    this.categoryColorValue,
  });

  IconData get categoryIcon => IconData(
        categoryIconCode ?? Icons.category.codePoint,
        fontFamily: 'MaterialIcons',
      );

  Color get categoryColor => Color(categoryColorValue ?? 0xFFFB8C00);

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'amount': amount,
      'note': note,
      'date': date.toIso8601String(),
      'category_id': categoryId,
      'type': type == TransactionType.expense ? 'expense' : 'income',
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as int?,
      amount: (map['amount'] as num).toDouble(),
      note: (map['note'] as String?) ?? '',
      date: DateTime.parse(map['date'] as String),
      categoryId: map['category_id'] as int,
      type: (map['type'] as String) == 'expense'
          ? TransactionType.expense
          : TransactionType.income,
      categoryName: map['category_name'] as String?,
      categoryIconCode: map['category_icon'] as int?,
      categoryColorValue: map['category_color'] as int?,
    );
  }
}
