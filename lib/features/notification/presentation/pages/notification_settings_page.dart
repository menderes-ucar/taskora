import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/notification_preferences_model.dart';
import '../../data/repositories/supabase_notification_preferences_repository.dart';

class NotificationSettingsPage extends ConsumerStatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  ConsumerState<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState
    extends ConsumerState<NotificationSettingsPage> {
  NotificationPreferences? _preferences;
  bool _loading = true;
  bool _saving = false;

  late final SupabaseNotificationPreferencesRepository _repository =
  SupabaseNotificationPreferencesRepository(Supabase.instance.client);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = ref.read(authProvider).user?.id;
    if (userId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      final preferences = await _repository.get(userId);
      if (mounted) {
        setState(() {
          _preferences = preferences;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bildirim ayarları yüklenemedi: $e')),
        );
      }
    }
  }

  Future<void> _save(NotificationPreferences next) async {
    setState(() {
      _preferences = next;
      _saving = true;
    });

    try {
      final saved = await _repository.save(next);
      if (mounted) setState(() => _preferences = saved);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bildirim ayarı kaydedilemedi: $e')),
        );
        await _load();
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final preferences = _preferences;
    final isFreelancer = ref.watch(authProvider).user?.role.name == 'freelancer';

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'Bildirim Ayarları',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : preferences == null
          ? const Center(
        child: Text(
          'Kullanıcı oturumu bulunamadı.',
          style: TextStyle(color: Colors.white),
        ),
      )
          : AbsorbPointer(
        absorbing: _saving,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            _sectionCard(
              title: 'Genel Bildirimler',
              children: [
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Anlık bildirimler',
                    style: TextStyle(
                      color: AppColors.black,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: const Text(
                    'Telefonunuza push bildirimi gönderilmesine izin ver.',
                  ),
                  value: preferences.pushEnabled,
                  onChanged: (value) => _save(
                    preferences.copyWith(pushEnabled: value),
                  ),
                ),
              ],
            ),
            if (isFreelancer) ...[
              const SizedBox(height: 14),
              _sectionCard(
                title: 'İş İlanı Bildirimleri',
                children: [
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Yeni iş fırsatları',
                      style: TextStyle(
                        color: AppColors.black,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitle: const Text(
                      'Sadece seçtiğin kategoriler yayınlandığında bildirim al.',
                    ),
                    value: preferences.jobAlertsEnabled,
                    onChanged: (value) => _save(
                      preferences.copyWith(jobAlertsEnabled: value),
                    ),
                  ),
                  const Divider(),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Text(
                      'İlgilendiğin kategoriler',
                      style: TextStyle(
                        color: AppColors.black,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  ...NotificationPreferences.availableCategories.map(
                        (category) {
                      final selected =
                      preferences.jobCategories.contains(category);
                      return CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(category),
                        value: selected,
                        activeColor: AppColors.primaryDark,
                        onChanged: !preferences.jobAlertsEnabled
                            ? null
                            : (value) {
                          final next = [
                            ...preferences.jobCategories,
                          ];
                          if (value == true) {
                            if (!next.contains(category)) {
                              next.add(category);
                            }
                          } else {
                            next.remove(category);
                          }
                          _save(
                            preferences.copyWith(
                              jobCategories: next,
                            ),
                          );
                        },
                      );
                    },
                  ),
                  if (preferences.jobAlertsEnabled &&
                      preferences.jobCategories.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Kategori seçmezsen yeni iş ilanı bildirimi gönderilmez.',
                        style: TextStyle(
                          color: AppColors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.primaryDark,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}
