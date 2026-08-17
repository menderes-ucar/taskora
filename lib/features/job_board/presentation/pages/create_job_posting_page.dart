import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskora/features/job_board/data/providers/job_postings_provider.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../shared/enums/job_board_enums.dart';
import '../../../../shared/constants/job_categories.dart';

class CreateJobPostingPage extends ConsumerStatefulWidget {
  final String employerId;

  const CreateJobPostingPage({
    super.key,
    required this.employerId,
  });

  @override
  ConsumerState<CreateJobPostingPage> createState() => _CreateJobPostingPageState();
}

class _CreateJobPostingPageState extends ConsumerState<CreateJobPostingPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _salaryController = TextEditingController();

  // 🚀 YAZILIM KATEGORİ SEÇENEKLERİ
  final List<String> _softwareCategories = TaskoraJobCategories.values;

  late String _selectedCategory;
  WorkType _selectedWorkType = WorkType.remote;
  ContractType _selectedContractType = ContractType.paid;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedCategory = _softwareCategories.first;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final notifier = ref.read(jobPostingsProvider.notifier);

      await notifier.createPosting(
        employerId: widget.employerId,
        title: _titleController.text.trim(),
        category: _selectedCategory,
        workType: _selectedWorkType,
        contractType: _selectedContractType,
        description: _descriptionController.text.trim(),
        salaryInfo: _salaryController.text.trim().isEmpty ? null : _salaryController.text.trim(),
        location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.success,
            content: Text('İlanınız oluşturuldu! Admin onayından sonra yayına alınacaktır. 🚀'),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppColors.danger, content: Text('Hata: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      appBar: AppBar(
        backgroundColor: AppColors.dark,
        elevation: 0,
        title: const Text(
          'Yeni İlan / Staj Oluştur',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w900),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // İlan Başlığı
            _buildLabel('İlan Başlığı'),
            TextFormField(
              controller: _titleController,
              style: const TextStyle(color: AppColors.white),
              decoration: _inputDecoration('Örn: Kıdemli Flutter Developer veya Yazılım Stajyeri'),
              validator: (v) => v == null || v.isEmpty ? 'Başlık zorunludur' : null,
            ),
            const SizedBox(height: 16),

            // Yazılım Kategorisi (Dropdown)
            _buildLabel('Yazılım Uzmanlık Alanı (Kategori)'),
            _buildDropdownContainer(
              child: DropdownButton<String>(
                value: _selectedCategory,
                isExpanded: true,
                dropdownColor: AppColors.surfaceCard,
                underline: const SizedBox(),
                style: const TextStyle(color: AppColors.white, fontSize: 13, fontWeight: FontWeight.bold),
                onChanged: (val) => setState(() => _selectedCategory = val!),
                items: _softwareCategories.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat));
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Çalışma Şekli (Remote/Hybrid/Onsite)
            _buildLabel('Çalışma Şekli'),
            _buildDropdownContainer(
              child: DropdownButton<WorkType>(
                value: _selectedWorkType,
                isExpanded: true,
                dropdownColor: AppColors.surfaceCard,
                underline: const SizedBox(),
                style: const TextStyle(color: AppColors.white, fontSize: 13, fontWeight: FontWeight.bold),
                onChanged: (val) => setState(() => _selectedWorkType = val!),
                items: WorkType.values.map((w) {
                  return DropdownMenuItem(value: w, child: Text(w.label));
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Çalışma / İstihdam Modeli (Tam Zamanlı, Staj vb.)
            _buildLabel('Çalışma / İstihdam Modeli'),
            _buildDropdownContainer(
              child: DropdownButton<ContractType>(
                value: _selectedContractType,
                isExpanded: true,
                dropdownColor: AppColors.surfaceCard,
                underline: const SizedBox(),
                style: const TextStyle(color: AppColors.white, fontSize: 13, fontWeight: FontWeight.bold),
                onChanged: (val) => setState(() => _selectedContractType = val!),
                items: ContractType.values.map((c) {
                  return DropdownMenuItem(value: c, child: Text(c.label));
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Konum (Şehir / Ülke)
            _buildLabel('Konum / Şehir (Opsiyonel)'),
            TextFormField(
              controller: _locationController,
              style: const TextStyle(color: AppColors.white),
              decoration: _inputDecoration('Örn: Kayseri, İstanbul veya Tüm Türkiye'),
            ),
            const SizedBox(height: 16),

            // Maaş / Ücret Bilgisi
            _buildLabel('Maaş / Bütçe Bilgisi (Opsiyonel)'),
            TextFormField(
              controller: _salaryController,
              style: const TextStyle(color: AppColors.white),
              decoration: _inputDecoration('Örn: 50.000 TL/Ay, Asgari Ücret veya Ücretsiz Staj'),
            ),
            const SizedBox(height: 16),

            // Detaylı Açıklama
            _buildLabel('İlan Detayı ve Aranan Nitelikler'),
            TextFormField(
              controller: _descriptionController,
              maxLines: 5,
              style: const TextStyle(color: AppColors.white),
              decoration: _inputDecoration('Aranan teknolojiler, tecrübe beklentisi vb...'),
              validator: (v) => v == null || v.isEmpty ? 'Açıklama zorunludur' : null,
            ),
            const SizedBox(height: 24),

            // Gönder Butonu
            SizedBox(
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSubmitting ? null : _submitForm,
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: AppColors.black)
                    : const Text(
                  'İlanı Onaya Gönder',
                  style: TextStyle(color: AppColors.black, fontWeight: FontWeight.w900, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }

  Widget _buildDropdownContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.grey, fontSize: 12),
      filled: true,
      fillColor: AppColors.surfaceCard,
      contentPadding: const EdgeInsets.all(12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }
}