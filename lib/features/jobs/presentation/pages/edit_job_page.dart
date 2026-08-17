import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../shared/models/job_model.dart';
import '../../../../shared/constants/job_categories.dart';
import '../../domain/providers/job_provider.dart';

class EditJobPage extends ConsumerStatefulWidget {
  final JobModel job;

  const EditJobPage({super.key, required this.job});

  @override
  ConsumerState<EditJobPage> createState() => _EditJobPageState();
}

class _EditJobPageState extends ConsumerState<EditJobPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController titleController;
  late final TextEditingController descriptionController;
  late final TextEditingController budgetController;
  late final TextEditingController deliveryDaysController;

  String? selectedCategory;

  final List<_JobCategoryItem> categories = [
    for (final category in TaskoraJobCategories.all)
      _JobCategoryItem(label: category.label, icon: category.icon),
  ];

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.job.title);
    descriptionController = TextEditingController(text: widget.job.description);
    budgetController = TextEditingController(text: widget.job.budgetMax.toStringAsFixed(0));
    deliveryDaysController = TextEditingController(text: widget.job.duration);
    selectedCategory = widget.job.category;
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    budgetController.dispose();
    deliveryDaysController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir kategori seçin')),
      );
      return;
    }

    final updatedJob = widget.job.copyWith(
      title: titleController.text.trim(),
      description: descriptionController.text.trim(),
      category: selectedCategory!,
      budgetMin: widget.job.budgetMin,
      budgetMax: double.tryParse(budgetController.text.trim()) ?? widget.job.budgetMax,
      duration: deliveryDaysController.text.trim(),
    );

    try {
      await ref.read(jobsProvider.notifier).updateJob(widget.job.id, updatedJob);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.success,
            content: Text('İlan başarıyla güncellendi', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppColors.error, content: Text('Hata: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text('İlanı Düzenle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  colors: [Color(0xFF0E2238), Color(0xFF103847), Color(0xFF0BA99C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.15),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('İlanı Güncelle', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                        SizedBox(height: 8),
                        Text(
                          'İlan detaylarını güncelle, kategori ve teslim süresini düzenle.',
                          style: TextStyle(color: Colors.white70, height: 1.4, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12),
                  Icon(Icons.edit_note_rounded, color: Colors.white, size: 34),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Temel Bilgiler', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(height: 12),
            _StyledTextField(
              controller: titleController,
              hintText: 'İş başlığı',
              validator: (value) => value == null || value.trim().isEmpty ? 'Başlık girin' : null,
            ),
            const SizedBox(height: 12),
            _StyledTextField(
              controller: descriptionController,
              hintText: 'İş açıklaması',
              maxLines: 6,
              validator: (value) => value == null || value.trim().isEmpty ? 'Açıklama girin' : null,
            ),
            const SizedBox(height: 24),
            const Text('Kategori Seç', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: categories.map((category) {
                final isSelected = selectedCategory == category.label;
                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => setState(() => selectedCategory = category.label),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryDark : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? AppColors.primaryDark : AppColors.primaryDark.withValues(alpha: 0.26),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.black.withValues(alpha: 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(category.icon, size: 18, color: isSelected ? Colors.white : AppColors.primaryDark),
                        const SizedBox(width: 8),
                        Text(
                          category.label,
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppColors.primaryDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Text('Teslim ve Bütçe', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StyledTextField(
                    controller: budgetController,
                    hintText: 'Bütçe (₺)',
                    keyboardType: TextInputType.number,
                    validator: (value) => value == null || value.trim().isEmpty ? 'Bütçe girin' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StyledTextField(
                    controller: deliveryDaysController,
                    hintText: 'Teslim günü',
                    keyboardType: TextInputType.number,
                    validator: (value) => value == null || value.trim().isEmpty ? 'Süre girin' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              text: 'Değişiklikleri Kaydet',
              icon: Icons.save_outlined,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}

class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _StyledTextField({
    required this.controller,
    required this.hintText,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: AppColors.black, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: AppColors.grey),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.primaryDark.withValues(alpha: 0.30)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.primaryDark.withValues(alpha: 0.22)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primaryDark, width: 1.5),
        ),
      ),
    );
  }
}

class _JobCategoryItem {
  final String label;
  final IconData icon;

  const _JobCategoryItem({required this.label, required this.icon});
}