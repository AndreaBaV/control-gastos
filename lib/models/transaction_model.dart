enum TransactionType { gasto, ingreso }

TransactionType transactionTypeFromString(String s) =>
    s == 'ingreso' ? TransactionType.ingreso : TransactionType.gasto;

String transactionTypeToString(TransactionType t) =>
    t == TransactionType.ingreso ? 'ingreso' : 'gasto';

class TransactionModel {
  const TransactionModel({
    required this.id,
    required this.type,
    required this.amountCents,
    required this.note,
    this.categoryId,
    required this.accountId,
    required this.createdAt,
  });

  final String id;
  final TransactionType type;
  final int amountCents;
  final String note;
  final String? categoryId;
  final String accountId;
  final DateTime createdAt;

  factory TransactionModel.fromMap(Map<String, Object?> map) {
    return TransactionModel(
      id: map['id']! as String,
      type: transactionTypeFromString(map['type']! as String),
      amountCents: map['amount_cents']! as int,
      note: map['note']! as String,
      categoryId: map['category_id'] as String?,
      accountId: map['account_id']! as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']! as int),
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'type': transactionTypeToString(type),
        'amount_cents': amountCents,
        'note': note,
        'category_id': categoryId,
        'account_id': accountId,
        'created_at': createdAt.millisecondsSinceEpoch,
      };
}
