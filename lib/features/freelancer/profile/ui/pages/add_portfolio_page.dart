import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Provider;
import 'package:uuid/uuid.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/widgets/primary_button.dart';
import '../../../../../shared/models/portfolio_item_model.dart';
import '../../../../auth/presentation/providers/auth_state.dart';
import '../../logic/portfolio_provider.dart';

class AddPortfolioPage extends ConsumerStatefulWidget {
  const AddPortfolioPage({super.key});

  @override
  ConsumerState<AddPortfolioPage> createState() => _AddPortfolioPageState();
}

class _AddPortfolioPageState extends ConsumerState<AddPortfolioPage> {
  final _formKey = GlobalKey<FormState>();

  final titleController = TextEditingController();
  final categoryController = TextEditingController();
  final descriptionController = TextEditingController();
  final image1Controller = TextEditingController();
  final image2Controller = TextEditingController();
  final image3Controller = TextEditingController();

  @override
  void dispose() {
    titleController.dispose();
    categoryController.dispose();
    descriptionController.dispose();
    image1Controller.dispose();
    image2Controller.dispose();
    image3Controller.dispose();
    super.dispose();
  }

  Future<void> _savePortfolio() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(authProvider).user;
    if (user == null) return;

    final imageUrls = [
      image1Controller.text.trim(),
      image2Controller.text.trim(),
      image3Controller.text.trim(),
    ].where((e) => e.isNotEmpty).toList();

    if (imageUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.danger,
          content: Text('En az 1 görsel eklemelisin'),
        ),
      );
      return;
    }

    final portfolioItem = PortfolioItemModel(
      id: const Uuid().v4(),
      freelancerId: user.id,
      title: titleController.text.trim(),
      category: categoryController.text.trim(),
      description: descriptionController.text.trim(),
      imageUrls: imageUrls,
    );

    ref.read(portfolioProvider.notifier).addPortfolioItem(portfolioItem);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.success,
          content: Text('Portföy projesi eklendi, onay bekliyor.'),
        ),
      );
      Navigator.pop(context);
    }
  }

  Widget _buildImageField({
    required TextEditingController controller,
    required String hint,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(
        color: AppColors.black,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.grey),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: AppColors.primaryDark.withValues(alpha: 0.20),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: AppColors.primaryDark.withValues(alpha: 0.20),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: AppColors.primaryDark,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Portföy Ekle',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF0E2238),
                    Color(0xFF103847),
                    Color(0xFF0BA99C),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.16),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Yeni Portföy Projesi',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Yaptığın işleri görsellerle birlikte ekleyerek profilini güçlendir.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.workspaces_outline,
                    color: Colors.white,
                    size: 34,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.40),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.gavel_rounded, color: AppColors.warning, size: 22),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '🚨 SaaS Politikası: Eklediğiniz portföy projeleri admin onayından geçtikten sonra işverenlere gösterilecektir kanka.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Proje Bilgileri',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: titleController,
              style: const TextStyle(
                color: AppColors.black,
                fontWeight: FontWeight.w500,
              ),
              validator: (value) => value == null || value.trim().isEmpty ? 'Başlık girin' : null,
              decoration: InputDecoration(
                hintText: 'Proje başlığı',
                hintStyle: const TextStyle(color: AppColors.grey),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(
                    color: AppColors.primaryDark.withValues(alpha: 0.20),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(
                    color: AppColors.primaryDark.withValues(alpha: 0.20),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(
                    color: AppColors.primaryDark,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: categoryController,
              style: const TextStyle(
                color: AppColors.black,
                fontWeight: FontWeight.w500,
              ),
              validator: (value) => value == null || value.trim().isEmpty ? 'Kategori girin' : null,
              decoration: InputDecoration(
                hintText: 'Kategori',
                hintStyle: const TextStyle(color: AppColors.grey),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(
                    color: AppColors.primaryDark.withValues(alpha: 0.20),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(
                    color: AppColors.primaryDark.withValues(alpha: 0.20),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(
                    color: AppColors.primaryDark,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: descriptionController,
              maxLines: 5,
              style: const TextStyle(
                color: AppColors.black,
                fontWeight: FontWeight.w500,
              ),
              validator: (value) => value == null || value.trim().isEmpty ? 'Açıklama girin' : null,
              decoration: InputDecoration(
                hintText: 'Proje açıklaması',
                hintStyle: const TextStyle(color: AppColors.grey),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(
                    color: AppColors.primaryDark.withValues(alpha: 0.20),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(
                    color: AppColors.primaryDark.withValues(alpha: 0.20),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(
                    color: AppColors.primaryDark,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Proje Görselleri (URL)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            _buildImageField(controller: image1Controller, hint: 'Görsel URL 1'),
            const SizedBox(height: 12),
            _buildImageField(controller: image2Controller, hint: 'Görsel URL 2'),
            const SizedBox(height: 12),
            _buildImageField(controller: image3Controller, hint: 'Görsel URL 3'),
            const SizedBox(height: 28),
            PrimaryButton(
              text: 'Portföyü Kaydet',
              icon: Icons.save_outlined,
              onPressed: _savePortfolio,
            ),
          ],
        ),
      ),
    );
  }
}
