class BudgetModel {
  const BudgetModel({
    required this.id,
    required this.categoryId,
    required this.yearMonth,
    required this.amountCents,
  });

  final String id;
  final String categoryId;
  final String yearMonth;
  final int amountCents;

  factory BudgetModel.fromMap(Map<String, Object?> map) {
    return BudgetModel(
      id: map['id']! as String,
      categoryId: map['category_id']! as String,
      yearMonth: map['year_month']! as String,
      amountCents: map['amount_cents']! as int,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'category_id': categoryId,
        'year_month': yearMonth,
        'amount_cents': amountCents,
      };
}
