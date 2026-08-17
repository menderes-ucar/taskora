import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart'; // 🚀 UUID paketi eklendi

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../shared/enums/job_status.dart';
import '../../../../shared/models/job_model.dart';
import '../../../../shared/constants/job_categories.dart';
import '../../../auth/presentation/providers/auth_state.dart';
import '../../domain/providers/job_provider.dart';

class CreateJobPage extends ConsumerStatefulWidget {
  const CreateJobPage({super.key});

  @override
  ConsumerState<CreateJobPage> createState() => _CreateJobPageState();
}

class _CreateJobPageState extends ConsumerState<CreateJobPage> {
  final _formKey = GlobalKey<FormState>();

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final budgetController = TextEditingController();
  final deliveryDaysController = TextEditingController();

  String? selectedCategory;
  bool _isSubmitting = false;

  final List<_JobCategoryItem> categories = [
    for (final category in TaskoraJobCategories.all)
      _JobCategoryItem(label: category.label, icon: category.icon),
  ];

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    budgetController.dispose();
    deliveryDaysController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = ref.read(authProvider).user;
    if (currentUser == null) return;

    if (selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.danger,
          content: Text('Lütfen bir kategori seçin'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final parsedBudget = double.tryParse(budgetController.text.trim()) ?? 0;
      final parsedDays = deliveryDaysController.text.trim();

      // 🚀 ÇÖZÜM: DateTime yerine Supabase standartlarına uygun geçerli UUID üretiliyor.
      // 🚀 Admin Onay Süreci: İlan durumu 'pending' (beklemede) olarak oluşturuluyor.
      final newJob = JobModel(
        id: const Uuid().v4(), // Fix: Invalid UUID hatası çözüldü
        employerId: currentUser.id,
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
        category: selectedCategory!,
        budgetMin: parsedBudget,
        budgetMax: parsedBudget,
        skillsRequired: const [],
        duration: '$parsedDays Gün',
        level: 'Intermediate',
        status: JobStatus.pending, // Admin onayına göndermek için 'pending'
        createdAt: DateTime.now(),
      );

      await ref.read(jobsProvider.notifier).addJob(newJob);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.success,
            content: Text('İlanınız onay için admine gönderildi! 🚀'),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.danger,
            content: Text('İlan oluşturulamadı: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        title: const Text(
          'İlan Oluştur',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
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
                    blurRadius: 20,
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
                        Text(
                          'Yeni İlan Yayınla',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.white),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'İlanınız yayınlandıktan sonra admin onayının ardından freelancerlara görünecektir.',
                          style: TextStyle(
                              color: Colors.white70,
                              height: 1.4,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12),
                  Icon(Icons.campaign_rounded, color: Colors.white, size: 34),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const _SectionTitle('Temel Bilgiler'),
            const SizedBox(height: 10),
            _StyledTextField(
              controller: titleController,
              hintText: 'İş başlığı',
              validator: (value) =>
              value == null || value.trim().isEmpty ? 'Başlık girin' : null,
            ),
            const SizedBox(height: 12),
            _StyledTextField(
              controller: descriptionController,
              hintText: 'İş açıklaması',
              maxLines: 6,
              validator: (value) =>
              value == null || value.trim().isEmpty ? 'Açıklama girin' : null,
            ),
            const SizedBox(height: 20),
            const _SectionTitle('Kategori Seç'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: categories.map((category) {
                final isSelected = selectedCategory == category.label;
                return InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => setState(() => selectedCategory = category.label),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryDark : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryDark
                            : AppColors.primaryDark.withValues(alpha: 0.22),
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
                        Icon(category.icon,
                            size: 18,
                            color: isSelected
                                ? Colors.white
                                : AppColors.primaryDark),
                        const SizedBox(width: 8),
                        Text(
                          category.label,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppColors.primaryDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            const _SectionTitle('Teslim ve Bütçe'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _StyledTextField(
                    controller: budgetController,
                    hintText: 'Bütçe (₺)',
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Bütçe girin' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StyledTextField(
                    controller: deliveryDaysController,
                    hintText: 'Teslim günü',
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Süre girin' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            PrimaryButton(
              text: _isSubmitting ? 'Gönderiliyor...' : 'İlanı Onaya Gönder',
              icon: Icons.publish_rounded,
              onPressed: _isSubmitting ? null : _submit,
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
      style: const TextStyle(
          color: AppColors.black, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: AppColors.grey),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide:
          BorderSide(color: AppColors.primaryDark.withValues(alpha: 0.22)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide:
          BorderSide(color: AppColors.primaryDark.withValues(alpha: 0.22)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide:
          const BorderSide(color: AppColors.primaryDark, width: 1.5),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
          fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white),
    );
  }
}

class _JobCategoryItem {
  final String label;
  final IconData icon;

  const _JobCategoryItem({required this.label, required this.icon});
}