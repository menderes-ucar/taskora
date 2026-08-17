class ContractTimelineModel {
  final String id;
  final String contractId;
  final String title;
  final String? description;
  final String actorId;
  final String? actorRole;
  final DateTime createdAt;

  const ContractTimelineModel({
    required this.id,
    required this.contractId,
    required this.title,
    this.description,
    required this.actorId,
    this.actorRole,
    required this.createdAt,
  });

  factory ContractTimelineModel.fromMap(Map<String, dynamic> map) {
    return ContractTimelineModel(
      id: (map['id'] ?? '').toString(),
      contractId: (map['contract_id'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      description: map['description']?.toString(),
      actorId: (map['actor_id'] ?? '').toString(),
      actorRole: map['actor_role']?.toString(),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ??
          DateTime.now().toUtc()
          : DateTime.now().toUtc(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'contract_id': contractId,
      'title': title,
      'description': description,
      'actor_id': actorId,
      'actor_role': actorRole,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }
}
