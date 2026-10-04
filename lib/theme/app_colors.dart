import 'package:flutter/material.dart';

/// Kolory ciemnego motywu aplikacji
class AppColors {
  // Tła
  static const Color background = Color(0xFF0A1220);
  static const Color surface = Color(0xFF111C2E); // karty
  static const Color surfaceHigh = Color(0xFF17253B); // pigułki, pola
  static const Color border = Color(0xFF22324D);
  static const Color borderStrong = Color(0xFF34486A); // obrys pól wyboru
  static const Color headerPhotoLight = Color(0xFF3F8FEA); // światła zdjęcia

  // Teksty
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF9FB0C8);
  static const Color textMuted = Color(0xFF62748F);

  // Akcenty
  static const Color primary = Color(0xFF1E88FF);
  static const Color primaryLight = Color(0xFF4DA3FF);
  static const Color primarySurface = Color(0xFF12305A); // zaznaczone pole
  static const Color success = Color(0xFF22A45D);
  static const Color successDark = Color(0xFF178A48);
  static const Color successBright = Color(0xFF4CD080);
  static const Color warning = Color(0xFFF5A623);
  static const Color danger = Color(0xFFFF5A6E);

  // Tła kart stacji według statusu
  static const Color successSurface = Color(0xFF10291D);
  static const Color warningSurface = Color(0xFF2A2417);
  static const Color dangerSurface = Color(0xFF2A161B);
}
