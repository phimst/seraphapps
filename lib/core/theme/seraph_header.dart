import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Header standar buat tiap halaman tools/fitur - desain "Flag Marker":
/// garis gradient cyan tipis di kiri sebagai penanda, judul pake font
/// EvolveSans dengan 1 kata di-highlight cyan, subtitle polos di bawah
/// (tanpa gaya "// comment" yang udah di-drop).
///
/// [title] - kata pertama/utama, warna ink normal.
/// [accent] - kata terakhir yang di-highlight cyan (opsional).
/// [subtitle] - deskripsi singkat, kalimat biasa tanpa "//".
class SeraphHeader extends StatelessWidget {
  final String title;
  final String? accent;
  final String? subtitle;
  final EdgeInsetsGeometry padding;
  final double fontSize;

  const SeraphHeader({
    super.key,
    required this.title,
    this.accent,
    this.subtitle,
    this.padding = const EdgeInsets.only(bottom: 22),
    this.fontSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 3,
            height: subtitle != null ? fontSize + 16 : fontSize + 4,
            margin: const EdgeInsets.only(top: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.cyan, AppColors.cyan.withValues(alpha: 0.08)],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: title,
                        style: AppFonts.heading(fontSize: fontSize, fontWeight: FontWeight.w500),
                      ),
                      if (accent != null)
                        TextSpan(
                          text: accent,
                          style: AppFonts.heading(
                              fontSize: fontSize, fontWeight: FontWeight.w500, color: AppColors.cyan),
                        ),
                    ],
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 5),
                  Text(subtitle!,
                      style: const TextStyle(color: AppColors.gray, fontSize: 12, height: 1.3)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
