import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class DeliveryUploadFile {
  final String name;
  final Uint8List bytes;
  final String? mimeType;

  const DeliveryUploadFile({
    required this.name,
    required this.bytes,
    this.mimeType,
  });

  int get size => bytes.lengthInBytes;
}

class ContractDeliveryStorageService {
  static const String bucket = 'taskora-deliveries';
  static const int maxFileSizeBytes = 50 * 1024 * 1024;
  static const int maxFilesPerDelivery = 10;

  final SupabaseClient _supabase;

  ContractDeliveryStorageService(this._supabase);

  String _safeFileName(String value) {
    final normalized = value.trim().replaceAll(RegExp(r'[^a-zA-Z0-9._-]+'), '_');
    return normalized.isEmpty ? 'file' : normalized;
  }

  Future<String> uploadFile({
    required String contractId,
    required int version,
    required DeliveryUploadFile file,
  }) async {
    if (file.size > maxFileSizeBytes) {
      throw Exception('Dosya boyutu 50 MB sınırını aşamaz: ${file.name}');
    }

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Oturum bulunamadı.');
    }

    final safeName = _safeFileName(file.name);
    final uniqueName = '${DateTime.now().microsecondsSinceEpoch}_$safeName';
    final path = '$contractId/v$version/$userId/$uniqueName';

    await _supabase.storage.from(bucket).uploadBinary(
      path,
      file.bytes,
      fileOptions: FileOptions(
        contentType: file.mimeType,
        upsert: false,
      ),
    );

    return path;
  }

  Future<void> attachFileMetadata({
    required String deliveryId,
    required String actorId,
    required String fileName,
    required String storagePath,
    required String? mimeType,
    required int fileSize,
  }) async {
    await _supabase.rpc(
      'attach_contract_delivery_file_rpc',
      params: {
        'p_delivery_id': deliveryId,
        'p_actor_id': actorId,
        'p_file_name': fileName,
        // Stored as a private storage reference, never as a permanent public URL.
        'p_file_url': 'storage://$storagePath',
        'p_mime_type': mimeType,
        'p_file_size': fileSize,
      },
    );
  }

  Future<String> createSignedUrl(String storagePath) async {
    return _supabase.storage.from(bucket).createSignedUrl(
      storagePath,
      60 * 60,
    );
  }
}
