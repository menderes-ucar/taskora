class ContractDeliveryFileModel {
  final String id;
  final String deliveryId;
  final String fileName;
  final String fileUrl;
  final String? mimeType;
  final int? fileSize;
  final DateTime createdAt;

  const ContractDeliveryFileModel({
    required this.id,
    required this.deliveryId,
    required this.fileName,
    required this.fileUrl,
    this.mimeType,
    this.fileSize,
    required this.createdAt,
  });

  factory ContractDeliveryFileModel.fromMap(Map<String, dynamic> map) {
    return ContractDeliveryFileModel(
      id: (map['id'] ?? '').toString(),
      deliveryId: (map['delivery_id'] ?? '').toString(),
      fileName: (map['file_name'] ?? '').toString(),
      fileUrl: (map['file_url'] ?? '').toString(),
      mimeType: map['mime_type']?.toString(),
      fileSize: _parseInt(map['file_size']),
      createdAt: _parseDateTime(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'delivery_id': deliveryId,
      'file_name': fileName,
      'file_url': fileUrl,
      'mime_type': mimeType,
      'file_size': fileSize,
      'created_at': createdAt.toIso8601String(),
    };
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }
}

class ContractDeliveryModel {
  final String id;
  final String contractId;
  final int version;
  final String message;

  /// Legacy single-file field. Kept for backward compatibility.
  final String? fileUrl;

  /// New multi-file delivery representation.
  ///
  /// The list is optional so existing delivery records that only contain
  /// `file_url` continue to deserialize without breaking older data.
  final List<ContractDeliveryFileModel> files;

  final DateTime createdAt;

  const ContractDeliveryModel({
    required this.id,
    required this.contractId,
    required this.version,
    required this.message,
    this.fileUrl,
    this.files = const <ContractDeliveryFileModel>[],
    required this.createdAt,
  });

  factory ContractDeliveryModel.fromMap(Map<String, dynamic> map) {
    final rawFiles = map['files'] ?? map['contract_delivery_files'];

    final files = rawFiles is List
        ? rawFiles
        .whereType<Map>()
        .map(
          (item) => ContractDeliveryFileModel.fromMap(
        Map<String, dynamic>.from(item),
      ),
    )
        .toList(growable: false)
        : const <ContractDeliveryFileModel>[];

    return ContractDeliveryModel(
      id: (map['id'] ?? '').toString(),
      contractId: (map['contract_id'] ?? '').toString(),
      version: _parseInt(map['version']) ?? 1,
      message: (map['message'] ?? '').toString(),
      fileUrl: map['file_url']?.toString(),
      files: files,
      createdAt: _parseDateTime(map['created_at']),
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

  bool get hasFiles => files.isNotEmpty || (fileUrl?.trim().isNotEmpty ?? false);

  int get fileCount => files.isNotEmpty ? files.length : (hasFiles ? 1 : 0);

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }
}
