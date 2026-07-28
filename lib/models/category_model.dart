import 'package:flutter/material.dart';

import 'transaction_model.dart';

enum CategoryKind { gasto, ingreso, ambas }

CategoryKind categoryKindFromString(String s) => switch (s) {
      'ingreso' => CategoryKind.ingreso,
      'ambas' => CategoryKind.ambas,
      _ => CategoryKind.gasto,
    };

String categoryKindToString(CategoryKind k) => switch (k) {
      CategoryKind.ingreso => 'ingreso',
      CategoryKind.ambas => 'ambas',
      CategoryKind.gasto => 'gasto',
    };

class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    required this.iconCodePoint,
    required this.sortOrder,
    this.kind = CategoryKind.gasto,
  });

  final String id;
  final String name;
  final int iconCodePoint;
  final int sortOrder;
  final CategoryKind kind;

  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');

  bool appliesTo(TransactionType type) {
    if (kind == CategoryKind.ambas) return true;
    return switch (type) {
      TransactionType.gasto => kind == CategoryKind.gasto,
      TransactionType.ingreso => kind == CategoryKind.ingreso,
    };
  }

  factory CategoryModel.fromMap(Map<String, Object?> map) {
    return CategoryModel(
      id: map['id']! as String,
      name: map['name']! as String,
      iconCodePoint: map['icon_code']! as int,
      sortOrder: map['sort_order']! as int,
      kind: categoryKindFromString(map['kind'] as String? ?? 'gasto'),
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'icon_code': iconCodePoint,
        'sort_order': sortOrder,
        'kind': categoryKindToString(kind),
      };
}
