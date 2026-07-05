import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/widgets/primary_button.dart';
import '../../../../../shared/enums/job_status.dart';
import '../../../../../shared/models/job_model.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../logic/jobs_provider.dart';

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
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    budgetController.dispose();
    deliveryDaysController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = ref.read(authProvider).user;
    if (currentUser == null) return;

    if (selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen bir kategori seçin'),
        ),
      );
      return;
    }

    final newJob = JobModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      employerId: currentUser.id,
      title: titleController.text.trim(),
      description: descriptionController.text.trim(),
      budget: double.tryParse(budgetController.text.trim()) ?? 0,
      category: selectedCategory!,
      deliveryDays: int.tryParse(deliveryDaysController.text.trim()) ?? 1,
      status: JobStatus.open,
      createdAt: DateTime.now(),
    );

    ref.read(jobsProvider.notifier).addJob(newJob);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('İlan başarıyla oluşturuldu'),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        title: const Text('İlan Oluştur'),
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
                          'Yeni İlan Yayınla',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Doğru kategoriyi seç, detayları gir ve freelancerlardan teklif almaya başla.',
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
                    Icons.campaign_rounded,
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
              text: 'İlanı Yayınla',
              icon: Icons.publish_rounded,
              onPressed: _submit,
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