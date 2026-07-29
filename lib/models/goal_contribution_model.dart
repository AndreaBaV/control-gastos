class GoalContributionModel {
  const GoalContributionModel({
    required this.id,
    required this.goalId,
    required this.amountCents,
    required this.note,
    required this.createdAt,
  });

  final String id;
  final String goalId;
  // Positivo = aportación, negativo = retiro.
  final int amountCents;
  final String note;
  final DateTime createdAt;

  factory GoalContributionModel.fromMap(Map<String, Object?> map) {
    return GoalContributionModel(
      id: map['id']! as String,
      goalId: map['goal_id']! as String,
      amountCents: map['amount_cents']! as int,
      note: map['note']! as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']! as int),
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'goal_id': goalId,
        'amount_cents': amountCents,
        'note': note,
        'created_at': createdAt.millisecondsSinceEpoch,
      };
}
