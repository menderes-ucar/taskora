import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../shared/enums/user_role.dart';
import '../../../notification/data/services/notification_helper.dart'; // 🚀 EKLENDİ
import '../providers/auth_state.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();

  final companyNameController = TextEditingController();
  final industryController = TextEditingController();
  final titleController = TextEditingController();
  final hourlyRateController = TextEditingController();

  UserRole selectedRole = UserRole.freelancer;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    companyNameController.dispose();
    industryController.dispose();
    titleController.dispose();
    hourlyRateController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (firstNameController.text.trim().isEmpty ||
        lastNameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            backgroundColor: AppColors.danger,
            content: Text('Lütfen temel alanları doldurun.',
                style: TextStyle(fontWeight: FontWeight.bold))),
      );
      return;
    }

    if (selectedRole == UserRole.employer &&
        companyNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            backgroundColor: AppColors.danger,
            content: Text('İşveren için Şirket Adı zorunludur.',
                style: TextStyle(fontWeight: FontWeight.bold))),
      );
      return;
    }

    if (selectedRole == UserRole.freelancer &&
        titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            backgroundColor: AppColors.danger,
            content: Text('Freelancer için Uzmanlık Ünvanı zorunludur.',
                style: TextStyle(fontWeight: FontWeight.bold))),
      );
      return;
    }

    final success = await ref.read(authProvider.notifier).signUp(
      firstName: firstNameController.text.trim(),
      lastName: lastNameController.text.trim(),
      email: emailController.text.trim(),
      password: passwordController.text,
      role: selectedRole,
      companyName: selectedRole == UserRole.employer ? companyNameController.text.trim() : null,
      industry: selectedRole == UserRole.employer ? industryController.text.trim() : null,
      title: selectedRole == UserRole.freelancer ? titleController.text.trim() : null,
      hourlyRate: selectedRole == UserRole.freelancer ? double.tryParse(hourlyRateController.text.trim()) : null,
    );

    if (!mounted) return;

    final authState = ref.read(authProvider);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          content: Text(
              authState.errorMessage ?? 'Kayıt esnasında bir hata oluştu.',
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      );
      return;
    }

    // 🚀 KAYIT VE OTURUM BAŞARILI OLDUĞUNDA FCM TOKEN'I SÜRDÜR/KAYDET
    await NotificationHelper.saveFcmToken();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          backgroundColor: AppColors.success,
          content: Text('Kayıt başarılı! Giriş yapabilirsiniz.',
              style: TextStyle(fontWeight: FontWeight.bold))),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hesap Oluştur',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Taskora platformuna katılarak hemen işlemlere başla.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 28),

              const Text(
                'Kullanıcı Rolü Seçin',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () =>
                          setState(() => selectedRole = UserRole.freelancer),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: selectedRole == UserRole.freelancer
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: selectedRole == UserRole.freelancer
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.20),
                            width: selectedRole == UserRole.freelancer ? 2 : 1,
                          ),
                          boxShadow: selectedRole == UserRole.freelancer
                              ? [
                            BoxShadow(
                              color: AppColors.black
                                  .withValues(alpha: 0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ]
                              : [],
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.person_outline_rounded,
                              color: selectedRole == UserRole.freelancer
                                  ? AppColors.primaryDark
                                  : Colors.white,
                              size: 26,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Freelancer',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: selectedRole == UserRole.freelancer
                                    ? AppColors.black
                                    : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () =>
                          setState(() => selectedRole = UserRole.employer),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: selectedRole == UserRole.employer
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: selectedRole == UserRole.employer
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.20),
                            width: selectedRole == UserRole.employer ? 2 : 1,
                          ),
                          boxShadow: selectedRole == UserRole.employer
                              ? [
                            BoxShadow(
                              color: AppColors.black
                                  .withValues(alpha: 0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ]
                              : [],
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.business_center_rounded,
                              color: selectedRole == UserRole.employer
                                  ? AppColors.primaryDark
                                  : Colors.white,
                              size: 26,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'İşveren',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: selectedRole == UserRole.employer
                                    ? AppColors.black
                                    : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: firstNameController,
                      style: const TextStyle(
                        color: AppColors.black,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: _inputDecoration(
                          'Ad', Icons.person_outline_rounded),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: TextField(
                      controller: lastNameController,
                      style: const TextStyle(
                        color: AppColors.black,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: _inputDecoration(
                          'Soyad', Icons.person_outline_rounded),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(
                  color: AppColors.black,
                  fontWeight: FontWeight.w500,
                ),
                decoration: _inputDecoration(
                    'E-posta Adresi', Icons.mail_outline_rounded),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                style: const TextStyle(
                  color: AppColors.black,
                  fontWeight: FontWeight.w500,
                ),
                decoration: _inputDecoration(
                    'Şifre (En az 6 karakter)', Icons.lock_open_rounded),
              ),
              const SizedBox(height: 16),

              if (selectedRole == UserRole.employer) ...[
                TextField(
                  controller: companyNameController,
                  style: const TextStyle(
                    color: AppColors.black,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: _inputDecoration(
                      'Şirket Adı / Ticari Ünvan *', Icons.business_rounded),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: industryController,
                  style: const TextStyle(
                    color: AppColors.black,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: _inputDecoration('Sektör (Opsiyonel)',
                      Icons.domain_verification_rounded),
                ),
              ],

              if (selectedRole == UserRole.freelancer) ...[
                TextField(
                  controller: titleController,
                  style: const TextStyle(
                    color: AppColors.black,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: _inputDecoration(
                      'Uzmanlık Ünvanı * (Örn: Flutter Developer)',
                      Icons.psychology_outlined),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: hourlyRateController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    color: AppColors.black,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: _inputDecoration(
                      'Hedef Saatlik Ücret ₺ (Opsiyonel)',
                      Icons.monetization_on_outlined),
                ),
              ],

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: authState.isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: authState.isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                      : const Text(
                    'Kayıt Ol',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.grey),
      prefixIcon: Icon(icon, color: AppColors.primaryDark, size: 20),
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
    );
  }
}