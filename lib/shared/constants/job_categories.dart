import 'package:flutter/material.dart';

/// Canonical Taskora job taxonomy.
///
/// These values are persisted in `jobs.category`, `job_postings.category`
/// and `notification_preferences.job_categories`. Keep them stable because
/// they are part of the public data contract between mobile and Supabase.
class TaskoraJobCategory {
  final String value;
  final String description;
  final String iconKey;

  const TaskoraJobCategory({
    required this.value,
    required this.description,
    required this.iconKey,
  });

  /// Backward-compatible display alias used by existing category widgets.
  String get label => value;

  /// Backward-compatible icon accessor used by existing category widgets.
  IconData get icon => switch (iconKey) {
    'web' => Icons.web_rounded,
    'mobile' => Icons.phone_android_rounded,
    'bug' => Icons.bug_report_rounded,
    'design' => Icons.design_services_rounded,
    'ai' => Icons.psychology_rounded,
    'cloud' => Icons.cloud_rounded,
    'security' => Icons.security_rounded,
    'qa' => Icons.fact_check_rounded,
    'game' => Icons.sports_esports_rounded,
    'embedded' => Icons.memory_rounded,
    'graphics' => Icons.brush_rounded,
    'video' => Icons.videocam_rounded,
    'writing' => Icons.edit_note_rounded,
    'marketing' => Icons.campaign_rounded,
    'audio' => Icons.headphones_rounded,
    _ => Icons.work_outline_rounded,
  };
}

abstract final class TaskoraJobCategories {
  static const List<TaskoraJobCategory> all = [
    TaskoraJobCategory(
      value: 'Web & Full Stack',
      description: 'Frontend, backend, API ve full-stack geliştirme',
      iconKey: 'web',
    ),
    TaskoraJobCategory(
      value: 'Mobil Uygulama',
      description: 'Flutter, Android, iOS ve React Native geliştirme',
      iconKey: 'mobile',
    ),
    TaskoraJobCategory(
      value: 'Bug Fixing & Debugging',
      description: 'Bug çözümü, debug, hata ayıklama ve mevcut sistem bakımı',
      iconKey: 'bug',
    ),
    TaskoraJobCategory(
      value: 'UI/UX & Ürün Tasarımı',
      description: 'UI, UX, prototip, tasarım sistemi ve ürün tasarımı',
      iconKey: 'design',
    ),
    TaskoraJobCategory(
      value: 'AI & Veri',
      description: 'Yapay zeka, makine öğrenmesi, veri ve analitik',
      iconKey: 'ai',
    ),
    TaskoraJobCategory(
      value: 'DevOps & Cloud',
      description: 'CI/CD, Docker, AWS, Azure, GCP ve altyapı',
      iconKey: 'cloud',
    ),
    TaskoraJobCategory(
      value: 'Cybersecurity',
      description: 'Siber güvenlik, güvenlik analizi, pentest ve hardening',
      iconKey: 'security',
    ),
    TaskoraJobCategory(
      value: 'QA & Test',
      description: 'Manuel test, otomasyon testleri ve kalite güvence',
      iconKey: 'qa',
    ),
    TaskoraJobCategory(
      value: 'Oyun Geliştirme',
      description: 'Unity, Unreal ve oyun sistemleri geliştirme',
      iconKey: 'game',
    ),
    TaskoraJobCategory(
      value: 'Embedded & IoT',
      description: 'Gömülü sistemler, cihazlar ve IoT çözümleri',
      iconKey: 'embedded',
    ),
    TaskoraJobCategory(
      value: 'Grafik & Marka Tasarımı',
      description: 'Logo, kurumsal kimlik, sosyal medya ve grafik tasarım',
      iconKey: 'graphics',
    ),
    TaskoraJobCategory(
      value: 'Video & Animasyon',
      description: 'Video edit, motion graphics ve animasyon',
      iconKey: 'video',
    ),
    TaskoraJobCategory(
      value: 'Yazı & Çeviri',
      description: 'İçerik, copywriting, teknik yazım ve çeviri',
      iconKey: 'writing',
    ),
    TaskoraJobCategory(
      value: 'Sosyal Medya & Pazarlama',
      description: 'Sosyal medya, reklam ve dijital pazarlama',
      iconKey: 'marketing',
    ),
    TaskoraJobCategory(
      value: 'Ses & Müzik',
      description: 'Ses düzenleme, podcast, müzik ve voice-over',
      iconKey: 'audio',
    ),
  ];

  static const List<String> values = [
    'Web & Full Stack',
    'Mobil Uygulama',
    'Bug Fixing & Debugging',
    'UI/UX & Ürün Tasarımı',
    'AI & Veri',
    'DevOps & Cloud',
    'Cybersecurity',
    'QA & Test',
    'Oyun Geliştirme',
    'Embedded & IoT',
    'Grafik & Marka Tasarımı',
    'Video & Animasyon',
    'Yazı & Çeviri',
    'Sosyal Medya & Pazarlama',
    'Ses & Müzik',
  ];

  static TaskoraJobCategory? find(String value) {
    for (final category in all) {
      if (category.value == value) return category;
    }
    return null;
  }
}
