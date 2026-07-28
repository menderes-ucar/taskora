import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;

import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/profile_service.dart';

final profileServiceProvider = Provider<IProfileService>((ref) {
  return SupabaseProfileService(ref.read(supabaseClientProvider));
});

final supabaseClientProvider = Provider((ref) => Supabase.instance.client);

class ProfileEditPage extends ConsumerStatefulWidget {
  final String userId;
  const ProfileEditPage({super.key, required this.userId});

  @override
  ConsumerState<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends ConsumerState<ProfileEditPage> {
  late TextEditingController _nameController, _bioController, _phoneController, _hourlyRateController, _companyNameController;
  final bool _isFreelancer = true;
  final List<String> _skills = [];
  String _newSkill = ''; bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(); _bioController = TextEditingController();
    _phoneController = TextEditingController(); _hourlyRateController = TextEditingController();
    _companyNameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose(); _bioController.dispose(); _phoneController.dispose();
    _hourlyRateController.dispose(); _companyNameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    try {
      final service = ref.read(profileServiceProvider);
      if (_isFreelancer) {
        await service.updateFreelancerProfile(userId: widget.userId, skills: _skills, bio: _bioController.text, hourlyRate: _hourlyRateController.text);
      } else {
        await service.updateEmployerProfile(userId: widget.userId, companyName: _companyNameController.text, bio: _bioController.text);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e'), backgroundColor: AppColors.danger));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
          'Profili Düzenle',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection('Temel Bilgiler', [
              _buildTextField(_nameController, 'İsim'),
              const SizedBox(height: 14),
              _buildTextField(_phoneController, 'Telefon No', keyboardType: TextInputType.phone),
              const SizedBox(height: 14),
              _buildTextField(_bioController, 'Hakkımda', maxLines: 4),
            ]),
            const SizedBox(height: 24),
            if (_isFreelancer) ...[
              _buildSection('Freelancer Detayları', [
                _buildTextField(_hourlyRateController, 'Saatlik Ücret (₺)', keyboardType: TextInputType.number),
                const SizedBox(height: 16),
                const Text(
                  'Yetenekler',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (val) => _newSkill = val,
                        style: const TextStyle(
                          color: AppColors.black,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Yetenek ekle',
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
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(80, 56),
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primaryDark,
                        elevation: 0,
                        side: BorderSide(
                          color: AppColors.primaryDark.withValues(alpha: 0.20),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      onPressed: () {
                        if (_newSkill.trim().isNotEmpty) setState(() { _skills.add(_newSkill.trim()); _newSkill = ''; });
                      },
                      child: const Text(
                        'Ekle',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _skills.map((skill) => Chip(
                    label: Text(
                      skill,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: AppColors.black,
                      ),
                    ),
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: AppColors.primaryDark.withValues(alpha: 0.20),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    onDeleted: () => setState(() => _skills.remove(skill)),
                    deleteIconColor: AppColors.danger,
                  )).toList(),
                ),
              ]),
            ] else _buildSection('Şirket Detayları', [
              _buildTextField(_companyNameController, 'Şirket Adı'),
            ]),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: _isLoading ? null : _saveProfile,
                child: _isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Text(
                  'Profili Kaydet',
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
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {int maxLines = 1, TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(
        color: AppColors.black,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.grey),
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
}