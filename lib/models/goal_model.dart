class GoalModel {
  const GoalModel({
    required this.id,
    required this.name,
    required this.targetCents,
    this.targetDate,
    required this.sortOrder,
    required this.createdAt,
  });

  final String id;
  final String name;
  final int targetCents;
  final DateTime? targetDate;
  final int sortOrder;
  final DateTime createdAt;

  factory GoalModel.fromMap(Map<String, Object?> map) {
    final targetDateMs = map['target_date'] as int?;
    return GoalModel(
      id: map['id']! as String,
      name: map['name']! as String,
      targetCents: map['target_cents']! as int,
      targetDate: targetDateMs == null ? null : DateTime.fromMillisecondsSinceEpoch(targetDateMs),
      sortOrder: map['sort_order']! as int,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']! as int),
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'target_cents': targetCents,
        'target_date': targetDate?.millisecondsSinceEpoch,
        'sort_order': sortOrder,
        'created_at': createdAt.millisecondsSinceEpoch,
      };
}
