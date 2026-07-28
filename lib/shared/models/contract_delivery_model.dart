class ContractDeliveryModel {
  final String id;
  final String contractId;
  final int version;
  final String message;
  final String? fileUrl;
  final DateTime createdAt;

  const ContractDeliveryModel({
    required this.id,
    required this.contractId,
    required this.version,
    required this.message,
    this.fileUrl,
    required this.createdAt,
  });

  factory ContractDeliveryModel.fromMap(Map<String, dynamic> map) {
    return ContractDeliveryModel(
      id: (map['id'] ?? '').toString(),
      contractId: (map['contract_id'] ?? '').toString(),
      version: (map['version'] as int?) ?? 1,
      message: (map['message'] ?? '').toString(),
      fileUrl: map['file_url']?.toString(),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'contract_id': contractId,
      'version': version,
      'message': message,
      'file_url': fileUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }
}