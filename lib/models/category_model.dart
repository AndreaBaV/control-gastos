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
    required this.iconKey,
    required this.sortOrder,
    this.kind = CategoryKind.gasto,
  });

  final String id;
  final String name;
  final String iconKey;
  final int sortOrder;
  final CategoryKind kind;

  // Cada rama devuelve una constante Icons.xxx literal (no reconstruida
  // desde un valor guardado), para que el tree-shaking de iconos funcione.
  IconData get icon => switch (iconKey) {
        'restaurant' => Icons.restaurant,
        'directions_car' => Icons.directions_car,
        'home' => Icons.home,
        'movie' => Icons.movie,
        'favorite' => Icons.favorite,
        'shopping_bag' => Icons.shopping_bag,
        'work_outline' => Icons.work_outline,
        'laptop_mac' => Icons.laptop_mac,
        'savings_outlined' => Icons.savings_outlined,
        _ => Icons.category,
      };

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
      iconKey: map['icon_code']! as String,
      sortOrder: map['sort_order']! as int,
      kind: categoryKindFromString(map['kind'] as String? ?? 'gasto'),
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'icon_code': iconKey,
        'sort_order': sortOrder,
        'kind': categoryKindToString(kind),
      };
}
