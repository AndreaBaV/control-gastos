enum AccountKind { efectivo, debito, credito }

AccountKind accountKindFromString(String s) => switch (s) {
      'credito' => AccountKind.credito,
      'debito' => AccountKind.debito,
      _ => AccountKind.efectivo,
    };

String accountKindToString(AccountKind k) => switch (k) {
      AccountKind.credito => 'credito',
      AccountKind.debito => 'debito',
      AccountKind.efectivo => 'efectivo',
    };

class AccountModel {
  const AccountModel({
    required this.id,
    required this.name,
    required this.kind,
    required this.balanceCents,
    required this.debtCents,
    this.creditLimitCents,
    required this.sortOrder,
    required this.createdAt,
  });

  final String id;
  final String name;
  final AccountKind kind;
  final int balanceCents;
  final int debtCents;
  final int? creditLimitCents;
  final int sortOrder;
  final DateTime createdAt;

  int? get availableCreditCents =>
      creditLimitCents == null ? null : creditLimitCents! - debtCents;

  factory AccountModel.fromMap(Map<String, Object?> map) {
    return AccountModel(
      id: map['id']! as String,
      name: map['name']! as String,
      kind: accountKindFromString(map['kind']! as String),
      balanceCents: map['balance_cents']! as int,
      debtCents: map['debt_cents']! as int,
      creditLimitCents: map['credit_limit_cents'] as int?,
      sortOrder: map['sort_order']! as int,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']! as int),
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'kind': accountKindToString(kind),
        'balance_cents': balanceCents,
        'debt_cents': debtCents,
        'credit_limit_cents': creditLimitCents,
        'sort_order': sortOrder,
        'created_at': createdAt.millisecondsSinceEpoch,
      };
}
