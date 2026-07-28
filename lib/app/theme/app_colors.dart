// lib/app/theme/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // SaaS v2 Derin Koyu Renk Paleti
  static const Color primary = Color(0xFF12D6C5);       // Neon Turkuaz
  static const Color primaryDark = Color(0xFF0BA99C);   // Koyu Vurgu Turkuaz

  static const Color black = Color(0xFF0B0F14);         // Tam Karanlık
  static const Color dark = Color(0xFF121821);          // Ana Scaffold Zemin Rengi
  static const Color surfaceCard = Color(0xFF1A2232);   // Kart Arka Planları

  static const Color white = Color(0xFFFFFFFF);         // Bembeyaz Başlıklar
  static const Color offWhite = Color(0xFFE2E8F0);      // Okuma Metinleri
  static const Color grey = Color(0xFF98A2B3);          // İkincil Bilgiler
  static const Color border = Color(0xFF26334D);        // İnce Çizgiler

  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);

  // 🚀 HATA ÇÖZÜMÜ: Hem 'danger' hem 'error' isimlerini aynı renge bağlıyoruz!
  // Böylece eski/yeni hangi dosyada çağrılırsa çağrılsın kırmızı hata vermez.
  static const Color danger = Color(0xFFEF4444);
  static const Color error = Color(0xFFEF4444);
}