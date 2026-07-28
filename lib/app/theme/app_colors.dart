import 'package:flutter/material.dart';

/// OneToolkit brand palette — teal accent, Files/Notion neutrals.
abstract final class AppColors {
  static const Color seed = Color(0xFF0F766E);
  static const Color seedDark = Color(0xFF2DD4BF);

  // Soft warm-neutral surfaces (not cream-terracotta AI default)
  static const Color surfaceLight = Color(0xFFF7F8F7);
  static const Color surfaceDark = Color(0xFF0C0F0E);

  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF161B1A);

  static const Color inkLight = Color(0xFF111827);
  static const Color inkDark = Color(0xFFF3F4F6);

  static const Color mutedLight = Color(0xFF6B7280);
  static const Color mutedDark = Color(0xFF9CA3AF);

  static const Color hairlineLight = Color(0xFFE5E7EB);
  static const Color hairlineDark = Color(0xFF2A3130);

  // Category accents — restrained, Files-like
  static const Color pdf = Color(0xFFDC2626);
  static const Color images = Color(0xFF2563EB);
  static const Color documents = Color(0xFF7C3AED);
  static const Color qr = Color(0xFF059669);
  static const Color text = Color(0xFFD97706);
  static const Color developer = Color(0xFF0891B2);
  static const Color files = Color(0xFF64748B);
  static const Color ai = Color(0xFFDB2777);
}

/// 8-point spacing + shared radii.
abstract final class AppSpace {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  static const double radius = 18;
  static const double radiusSm = 12;
  static const double radiusLg = 22;

  static const Duration motion = Duration(milliseconds: 240);
}
