import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../shared/enums/contract_status.dart';
import '../../../../shared/models/contract_model.dart';
import '../../data/services/contract_delivery_storage_service.dart';
import '../../logic/contracts_provider.dart';

class DeliverySubmissionPage extends ConsumerStatefulWidget {
  final ContractModel contract;

  const DeliverySubmissionPage({
    super.key,
    required this.contract,
  });

  @override
  ConsumerState<DeliverySubmissionPage> createState() =>
      _DeliverySubmissionPageState();
}

class _DeliverySubmissionPageState
    extends ConsumerState<DeliverySubmissionPage> {
  static const int _maxTotalBytes = 150 * 1024 * 1024;

  final _messageController = TextEditingController();
  final _linkController = TextEditingController();
  final List<DeliveryUploadFile> _files = [];

  bool _isSubmitting = false;

  bool get _isRevision =>
      widget.contract.status == ContractStatus.revisionRequested;

  int get _totalBytes =>
      _files.fold<int>(0, (total, file) => total + file.size);

  @override
  void dispose() {
    _messageController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.pickFiles(
        allowMultiple: true,
        withData: true,
        type: FileType.any,
      );

      if (result == null || result.files.isEmpty) return;

      final remainingSlots =
          ContractDeliveryStorageService.maxFilesPerDelivery - _files.length;
      if (remainingSlots <= 0) {
        _showError('Bir teslimatta en fazla 10 dosya ekleyebilirsiniz.');
        return;
      }

      final picked = result.files.take(remainingSlots).toList();
      final nextFiles = <DeliveryUploadFile>[];
      var nextTotal = _totalBytes;

      for (final platformFile in picked) {
        final bytes = platformFile.bytes;
        if (bytes == null) {
          _showError('${platformFile.name} okunamadı. Lütfen tekrar deneyin.');
          continue;
        }

        if (bytes.lengthInBytes >
            ContractDeliveryStorageService.maxFileSizeBytes) {
          _showError('${platformFile.name} 50 MB sınırını aşıyor.');
          continue;
        }

        if (nextTotal + bytes.lengthInBytes > _maxTotalBytes) {
          _showError('Bir teslimatın toplam dosya boyutu 150 MB ile sınırlı.');
          break;
        }

        final duplicate = _files.any(
              (file) =>
          file.name == platformFile.name && file.size == bytes.lengthInBytes,
        );
        if (duplicate) continue;

        final file = DeliveryUploadFile(
          name: platformFile.name,
          bytes: bytes,
          mimeType: _mimeTypeFor(platformFile.extension),
        );

        nextFiles.add(file);
        nextTotal += file.size;
      }

      if (!mounted) return;
      setState(() => _files.addAll(nextFiles));
    } catch (e) {
      if (!mounted) return;
      _showError('Dosya seçilemedi: $e');
    }
  }

  String? _mimeTypeFor(String? extension) {
    switch (extension?.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'zip':
        return 'application/zip';
      case 'rar':
        return 'application/vnd.rar';
      case '7z':
        return 'application/x-7z-compressed';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'webp':
        return 'image/webp';
      case 'txt':
        return 'text/plain';
      default:
        return null;
    }
  }

  Future<void> _submit() async {
    final message = _messageController.text.trim();
    final link = _linkController.text.trim();

    if (message.length < 10) {
      _showError('Teslimat açıklaması en az 10 karakter olmalı.');
      return;
    }

    if (link.isNotEmpty) {
      final uri = Uri.tryParse(link);
      if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
        _showError('Geçerli bir proje bağlantısı girin.');
        return;
      }
    }

    if (_files.isEmpty && link.isEmpty) {
      _showError('En az bir dosya veya harici proje bağlantısı ekleyin.');
      return;
    }

    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      await ref.read(contractsProvider.notifier).submitDeliveryWithFiles(
        contractId: widget.contract.id,
        message: message,
        fileUrl: link.isEmpty ? null : link,
        files: List<DeliveryUploadFile>.unmodifiable(_files),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.success,
          content: Text('Teslimat başarıyla gönderildi.'),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showError('Teslimat gönderilemedi: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.danger,
        content: Text(message),
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  IconData _fileIcon(String name) {
    final extension = name.split('.').last.toLowerCase();
    if (['png', 'jpg', 'jpeg', 'webp'].contains(extension)) {
      return Icons.image_outlined;
    }
    if (extension == 'pdf') return Icons.picture_as_pdf_outlined;
    if (['zip', 'rar', '7z'].contains(extension)) {
      return Icons.folder_zip_outlined;
    }
    if (['doc', 'docx'].contains(extension)) return Icons.description_outlined;
    if (['xls', 'xlsx'].contains(extension)) return Icons.table_chart_outlined;
    if (['ppt', 'pptx'].contains(extension)) return Icons.slideshow_outlined;
    return Icons.insert_drive_file_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final totalProgress = _maxTotalBytes == 0
        ? 0.0
        : (_totalBytes / _maxTotalBytes).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppColors.dark,
      appBar: AppBar(
        backgroundColor: AppColors.dark,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          _isRevision ? 'Revize Sürümü Teslim Et' : 'Yeni Versiyon Teslim Et',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  _buildHeader(),
                  const SizedBox(height: 18),
                  _buildMessageCard(),
                  const SizedBox(height: 14),
                  _buildFilesCard(totalProgress),
                  const SizedBox(height: 14),
                  _buildLinkCard(),
                  const SizedBox(height: 14),
                  _buildChecklist(),
                ],
              ),
            ),
            _buildSubmitBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.22),
            AppColors.surfaceCard,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primary.withOpacity(0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.rocket_launch_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.contract.jobTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _isRevision
                      ? 'İşverenin revizyon notlarını karşılayan yeni sürümü gönderin.'
                      : 'Çalışmanın bu sürümünü açıklama, dosyalar ve varsa demo bağlantısıyla teslim edin.',
                  style: const TextStyle(
                    color: AppColors.offWhite,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageCard() {
    return _sectionCard(
      title: 'Teslimat açıklaması',
      subtitle: 'Bu sürümde nelerin tamamlandığını net şekilde anlatın.',
      icon: Icons.notes_rounded,
      child: TextField(
        controller: _messageController,
        minLines: 5,
        maxLines: 8,
        textCapitalization: TextCapitalization.sentences,
        style: const TextStyle(color: AppColors.black, fontSize: 14),
        decoration: _inputDecoration(
          'Örn. Ana sayfa tamamlandı, responsive yapı düzenlendi ve login akışı test edildi...',
        ),
      ),
    );
  }

  Widget _buildFilesCard(double totalProgress) {
    return _sectionCard(
      title: 'Teslim dosyaları',
      subtitle: 'Dosyalar özel Supabase Storage alanında saklanır.',
      icon: Icons.attach_file_rounded,
      trailing: Text(
        '${_files.length}/10',
        style: const TextStyle(
          color: AppColors.primaryDark,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: _isSubmitting ? null : _pickFiles,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.28),
                ),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.cloud_upload_outlined,
                    color: AppColors.primaryDark,
                    size: 30,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Dosya ekle',
                    style: TextStyle(
                      color: AppColors.black,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Tek veya birden fazla dosya seçebilirsiniz · Maks. 50 MB/dosya',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.grey, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
          if (_files.isNotEmpty) ...[
            const SizedBox(height: 12),
            ..._files.asMap().entries.map((entry) {
              final index = entry.key;
              final file = entry.value;
              return _fileTile(file, index);
            }),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      minHeight: 6,
                      value: totalProgress,
                      backgroundColor: AppColors.border,
                      valueColor: const AlwaysStoppedAnimation(AppColors.primaryDark),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${_formatBytes(_totalBytes)} / 150 MB',
                  style: const TextStyle(
                    color: AppColors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _fileTile(DeliveryUploadFile file, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _fileIcon(file.name),
              color: AppColors.primaryDark,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _formatBytes(file.size),
                  style: const TextStyle(color: AppColors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Kaldır',
            onPressed: _isSubmitting
                ? null
                : () => setState(() => _files.removeAt(index)),
            icon: const Icon(Icons.close_rounded, size: 19),
            color: AppColors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildLinkCard() {
    return _sectionCard(
      title: 'Harici proje bağlantısı',
      subtitle: 'GitHub, Figma, canlı demo veya Drive bağlantısı ekleyebilirsiniz.',
      icon: Icons.link_rounded,
      child: TextField(
        controller: _linkController,
        keyboardType: TextInputType.url,
        style: const TextStyle(color: AppColors.black, fontSize: 14),
        decoration: _inputDecoration('https://...').copyWith(
          prefixIcon: const Icon(Icons.link_rounded, color: AppColors.primaryDark),
        ),
      ),
    );
  }

  Widget _buildChecklist() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Göndermeden önce',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 10),
          _CheckItem(text: 'Teslimat açıklaması tamamlandı'),
          _CheckItem(text: 'Dosyalar açılabilir ve son sürüm'),
          _CheckItem(text: 'Varsa demo / GitHub bağlantısı güncel'),
        ],
      ),
    );
  }

  Widget _buildSubmitBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: AppColors.dark,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: _isSubmitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDark,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.border,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            icon: _isSubmitting
                ? const SizedBox(
              width: 19,
              height: 19,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: Colors.white,
              ),
            )
                : const Icon(Icons.send_rounded, size: 20),
            label: Text(
              _isSubmitting ? 'Teslimat gönderiliyor...' : 'Teslimatı Gönder',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primaryDark, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.grey,
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF98A2B3), fontSize: 13),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: AppColors.primaryDark, width: 1.4),
      ),
    );
  }
}

class _CheckItem extends StatelessWidget {
  final String text;

  const _CheckItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 17),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppColors.offWhite, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
