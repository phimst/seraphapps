import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Warna diambil persis dari desain Canva "Dark Grid" milik Phyn.
class AppColors {
  static const bg = Color(0xFF0B0D10);
  static const panel = Color(0xFF14171C);
  static const panel2 = Color(0xFF1B1F26);
  static const ink = Color(0xFFF3F3F0);
  static const cyan = Color(0xFF4CF3D6);
  static const magenta = Color(0xFFFF5CAA);
  static const gray = Color(0xFF7A8088);
  static const line = Color(0xFF22262C);
}

/// Font sesuai desain original: Archivo buat judul/heading (bold, techy),
/// JetBrains Mono buat body/data/label (monospace, kesan terminal/dev).
class AppFonts {
  static TextStyle heading({
    double fontSize = 20,
    FontWeight fontWeight = FontWeight.w900,
    Color color = AppColors.ink,
    double? letterSpacing,
  }) =>
      GoogleFonts.archivo(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
      );

  static TextStyle mono({
    double fontSize = 12.5,
    FontWeight fontWeight = FontWeight.w400,
    Color color = AppColors.ink,
    double? letterSpacing,
    FontStyle? fontStyle,
  }) =>
      GoogleFonts.jetBrainsMono(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        fontStyle: fontStyle,
      );

  /// Buat caption/hint/label kecil di bawah input - dikasih sedikit
  /// aksen warna & style "// comment" biar lebih hidup, gak flat abu-abu
  /// polos semua kayak sebelumnya.
  static TextStyle caption({Color color = AppColors.gray, double fontSize = 10}) =>
      GoogleFonts.jetBrainsMono(
        fontSize: fontSize,
        color: color,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
      );
}

class AppTheme {
  static ThemeData get dark {
    final baseMono = GoogleFonts.jetBrainsMonoTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.cyan,
        secondary: AppColors.magenta,
        surface: AppColors.panel,
        onSurface: AppColors.ink,
      ),
      textTheme: baseMono.apply(
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.ink,
        elevation: 0,
        titleTextStyle: AppFonts.mono(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
          color: AppColors.gray,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.panel,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.line),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.cyan),
        ),
        hintStyle: GoogleFonts.jetBrainsMono(color: const Color(0xFF4A4F57), fontSize: 12),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? AppColors.cyan : AppColors.gray),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? AppColors.cyan.withValues(alpha: 0.25)
                : AppColors.line),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.cyan,
          foregroundColor: const Color(0xFF06110E),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: GoogleFonts.archivo(fontWeight: FontWeight.w800, letterSpacing: 0.5),
        ),
      ),
    );
  }
}
