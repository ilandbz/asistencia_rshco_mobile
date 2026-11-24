import 'package:flutter/material.dart';

/// Paleta Institucional y Tokens de Diseño - Red de Salud Huánuco (RSHCO)
class AppColors {
  // Primarios Institucionales
  static const Color primary = Color(0xFF003876); // Azul Institucional RSHCO
  static const Color primaryDark = Color(0xFF00224A);
  static const Color primaryLight = Color(0xFF1E5BB0);
  static const Color accent = Color(0xFF00A3E0); // Celeste Sanitario

  // Colores de Estado Semánticos
  static const Color success = Color(0xFF16A34A); // Verde asistido / Aprobado
  static const Color successBg = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFD97706); // Ámbar tardanza / Pendiente
  static const Color warningBg = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFDC2626); // Rojo falta / Rechazado
  static const Color errorBg = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF2563EB); // Informativo / Solicitado
  static const Color infoBg = Color(0xFFDBEAFE);

  // Colores de Turnos (Siglas Médicas)
  static const Color turnoManana = Color(0xFF0284C7); // Mañana (M)
  static const Color turnoTarde = Color(0xFFEA580C); // Tarde (T)
  static const Color turnoNoche = Color(0xFF4F46E5); // Noche (N)
  static const Color turnoGuardia = Color(0xFF7C3AED); // Guardias (GD, GN)
  static const Color turnoDescanso = Color(0xFF64748B); // Descanso (D)

  // Neutros y Fondos
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFCBD5E1);

  // Tipografía
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        error: AppColors.error,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 1.5,
        shadowColor: Colors.black.withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant.withOpacity(0.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 2,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
