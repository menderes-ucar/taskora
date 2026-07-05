import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/widgets/primary_button.dart';
import '../../../../../shared/models/portfolio_item_model.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
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

    // 👇 minimum 1 görsel kontrolü
    if (imageUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
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
      // ❌ createdAt verme artık
    );

    ref.read(portfolioProvider.notifier).addPortfolioItem(portfolioItem);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Portföy projesi eklendi'),
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
      decoration: InputDecoration(
        hintText: hint,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        scrolledUnderElevation: 0,
        title: const Text('Portföy Ekle'),
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
                          'Yeni Portföy Projesi',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Yaptığın işleri görsellerle birlikte ekleyerek profilini güçlendir.',
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
                    Icons.workspaces_outline,
                    color: Colors.white,
                    size: 34,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const _SectionTitle('Proje Bilgileri'),
            const SizedBox(height: 10),
            TextFormField(
              controller: titleController,
              validator: (value) =>
              value == null || value.trim().isEmpty ? 'Başlık girin' : null,
              decoration: _inputDecoration('Proje başlığı'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: categoryController,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Kategori girin'
                  : null,
              decoration: _inputDecoration('Kategori'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: descriptionController,
              maxLines: 5,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Açıklama girin'
                  : null,
              decoration: _inputDecoration('Proje açıklaması'),
            ),
            const SizedBox(height: 20),
            const _SectionTitle('Proje Görselleri'),
            const SizedBox(height: 10),
            _buildImageField(
              controller: image1Controller,
              hint: 'Görsel URL 1',
            ),
            const SizedBox(height: 12),
            _buildImageField(
              controller: image2Controller,
              hint: 'Görsel URL 2',
            ),
            const SizedBox(height: 12),
            _buildImageField(
              controller: image3Controller,
              hint: 'Görsel URL 3',
            ),
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

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
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