import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/widgets/primary_button.dart';
import '../../../../../shared/models/job_model.dart';
import '../../../../freelancer/jobs/ui/logic/jobs_provider.dart';

class EditJobPage extends ConsumerStatefulWidget {
  final JobModel job;

  const EditJobPage({
    super.key,
    required this.job,
  });

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

  final List<_JobCategoryItem> categories = const [
    _JobCategoryItem(
      label: 'Grafik Tasarım',
      icon: Icons.brush_rounded,
    ),
    _JobCategoryItem(
      label: 'Yazılım',
      icon: Icons.code_rounded,
    ),
    _JobCategoryItem(
      label: 'Mobil',
      icon: Icons.phone_iphone_rounded,
    ),
    _JobCategoryItem(
      label: 'UI/UX',
      icon: Icons.design_services_rounded,
    ),
    _JobCategoryItem(
      label: 'Video',
      icon: Icons.videocam_rounded,
    ),
    _JobCategoryItem(
      label: 'Sosyal Medya',
      icon: Icons.campaign_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.job.title);
    descriptionController = TextEditingController(text: widget.job.description);
    budgetController =
        TextEditingController(text: widget.job.budget.toStringAsFixed(0));
    deliveryDaysController =
        TextEditingController(text: widget.job.deliveryDays.toString());
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
        const SnackBar(
          content: Text('Lütfen bir kategori seçin'),
        ),
      );
      return;
    }

    final updatedJob = widget.job.copyWith(
      title: titleController.text.trim(),
      description: descriptionController.text.trim(),
      budget:
      double.tryParse(budgetController.text.trim()) ?? widget.job.budget,
      category: selectedCategory!,
      deliveryDays:
      int.tryParse(deliveryDaysController.text.trim()) ??
          widget.job.deliveryDays,
    );

    try {
      await ref.read(jobsProvider.notifier).updateJob(updatedJob);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('İlan güncellendi'),
          ),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        title: const Text('İlanı Düzenle'),
        backgroundColor: AppColors.primary,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryDark,
                    AppColors.primaryDark.withOpacity(0.88),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'İlanı Güncelle',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'İlan detaylarını güncelle, kategori ve teslim süresini düzenle.',
                          style: TextStyle(
                            color: Colors.white70,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12),
                  Icon(
                    Icons.edit_note_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
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
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Açıklama girin'
                  : null,
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
                  onTap: () {
                    setState(() {
                      selectedCategory = category.label;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.14)
                          : AppColors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryDark.withOpacity(0.45)
                            : AppColors.border,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          category.icon,
                          size: 18,
                          color: isSelected
                              ? AppColors.primaryDark
                              : AppColors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          category.label,
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.primaryDark
                                : AppColors.black,
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
                    hintText: 'Bütçe',
                    keyboardType: TextInputType.number,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Bütçe girin'
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StyledTextField(
                    controller: deliveryDaysController,
                    hintText: 'Teslim günü',
                    keyboardType: TextInputType.number,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Süre girin'
                        : null,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),
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
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.primaryDark),
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
        fontSize: 17,
        fontWeight: FontWeight.w900,
        color: AppColors.black,
      ),
    );
  }
}

class _JobCategoryItem {
  final String label;
  final IconData icon;

  const _JobCategoryItem({
    required this.label,
    required this.icon,
  });
}