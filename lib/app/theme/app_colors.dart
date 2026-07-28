import 'package:flutter/material.dart';

/// Apple Files–inspired system palette.
abstract final class AppColors {
  static const Color seed = Color(0xFF007AFF); // iOS system blue accent
  static const Color seedDark = Color(0xFF0A84FF);

  // iOS grouped background
  static const Color surfaceLight = Color(0xFFF2F2F7);
  static const Color surfaceDark = Color(0xFF000000);

  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF1C1C1E);

  static const Color inkLight = Color(0xFF000000);
  static const Color inkDark = Color(0xFFFFFFFF);

  static const Color mutedLight = Color(0xFF8E8E93);
  static const Color mutedDark = Color(0xFF8E8E93);

  static const Color fillLight = Color(0xFFE5E5EA);
  static const Color fillDark = Color(0xFF2C2C2E);

  static const Color pdf = Color(0xFFFF3B30);
  static const Color images = Color(0xFF007AFF);
  static const Color documents = Color(0xFFAF52DE);
  static const Color qr = Color(0xFF34C759);
  static const Color text = Color(0xFFFF9500);
  static const Color developer = Color(0xFF5AC8FA);
  static const Color files = Color(0xFF8E8E93);
  static const Color ai = Color(0xFFFF2D55);
}

abstract final class AppSpace {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  /// Files uses tighter continuous corners.
  static const double radius = 14;
  static const double radiusSm = 10;
  static const double radiusLg = 16;

  static const Duration motion = Duration(milliseconds: 220);
}
